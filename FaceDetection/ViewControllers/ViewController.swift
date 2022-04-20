//
//  ViewController.swift
//  FaceDetection
//
//  Created by J on 2022-04-19.
//

import UIKit
import Vision
import AVFoundation
import Combine

final class ViewController: UIViewController {
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var videoDataOutput: AVCaptureVideoDataOutput!
    private var faceLayers: [CAShapeLayer]!
    private var cameraContainerView: UIView!
    private var counterContainerView: UIView!
    private var stackView: UIStackView!
    private var counterLabel = UILabel()
    private var imageView: UIImageView!
    private let imageConfig = UIImage.SymbolConfiguration(scale: .medium)
    private var viewModel = FaceCounterViewModel()
    private var cancellables = Set<AnyCancellable>()
    private let alert = Alerts()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureInitialSetup()
        configureCancellable()
        configureCamera()
        configureCounter()
        setConstraints()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.actionSubject.send(.initialize)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = CGRect(origin: .zero, size: CGSize(width: cameraContainerView.bounds.width, height: cameraContainerView.bounds.height))
    }

    private func configureInitialSetup() {
        captureSession = AVCaptureSession()
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoDataOutput = AVCaptureVideoDataOutput()
        faceLayers = [CAShapeLayer]()
    }
    
    private func configureCancellable() {
        viewModel.stateEffectSubject
            .sink { [weak self] (stateEffect) in
                switch stateEffect {
                case .initialized:
                    DispatchQueue.main.async {
                        self?.counterLabel.text = "0"
                        let image = UIImage(systemName: "person" , withConfiguration: self!.imageConfig)?.withTintColor(.gray, renderingMode: .alwaysOriginal)
                        self?.imageView.image = image
                    }
                case .updateCounter(let num):
                    DispatchQueue.main.async {
                        self?.counterLabel.text = "\(num)"
                        guard let systemName = self?.getImageName(counter: num) else { return }
                        let image = UIImage(systemName: systemName, withConfiguration: self!.imageConfig)?.withTintColor(.gray, renderingMode: .alwaysOriginal)
                        self?.imageView.image = image
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func getImageName(counter: Int) -> String {
        switch counter {
        case 0:
            return "person"
        case 1:
            return "person.fill"
        default:
            return "person.2.fill"
        }
    }
    
    private func configureCamera() {
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front)
        
        guard let device = discoverySession.devices.first,
              let captureDeviceInput = try? AVCaptureDeviceInput(device: device),
              captureSession.canAddInput(captureDeviceInput) else { return }
        captureSession.addInput(captureDeviceInput)
        configurePreview()
    }
    
    private func configurePreview() {
        cameraContainerView = UIView()
        cameraContainerView.accessibilityHint = "Camera view finder"
        cameraContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cameraContainerView)
        
        previewLayer.videoGravity = .resizeAspectFill
        cameraContainerView.layer.addSublayer(previewLayer)
        previewLayer.frame = CGRect(origin: .zero, size: CGSize(width: cameraContainerView.bounds.width, height: cameraContainerView.bounds.height))
        
        videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]
        videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera"))
        captureSession.addOutput(videoDataOutput)
        
        let videoConnection = videoDataOutput.connection(with: .video)
        videoConnection?.videoOrientation = .portrait
        
        captureSession.startRunning()
    }
    
    private func configureCounter() {
        counterContainerView = UIView()
        counterContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(counterContainerView)
        
        counterLabel.text = "0"
        counterLabel.font = UIFont.systemFont(ofSize: 50, weight: .bold)
        counterLabel.adjustsFontForContentSizeCategory = true
        counterLabel.accessibilityHint = "Number of faces detected"
        guard let counterLabelText = counterLabel.text else { return }
        counterLabel.accessibilityValue = "\(counterLabelText) number of face detected"
        counterLabel.textAlignment = .center
        
        let image = UIImage(systemName: "person", withConfiguration: imageConfig)?.withTintColor(.gray, renderingMode: .alwaysOriginal)
        imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.accessibilityHint = "Symbol of a person is currently implying \(counterLabelText) persons"
        
        stackView = UIStackView(arrangedSubviews: [counterLabel, imageView])
        stackView.distribution = .fillEqually
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
        
        var elements = [UIAccessibilityElement]()
        guard let stackView = stackView,
              let counterLabelHint = counterLabel.accessibilityHint,
              let imageViewHint = imageView.accessibilityHint else { return }
        let groupedElement = UIAccessibilityElement(accessibilityContainer: stackView)
        groupedElement.accessibilityLabel = "\(counterLabelHint) is \(counterLabelText). \(imageViewHint)"
        groupedElement.accessibilityFrameInContainerSpace = stackView.frame
        elements.append(groupedElement)
    }

    private func setConstraints() {
        NSLayoutConstraint.activate([
            cameraContainerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            cameraContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cameraContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cameraContainerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.6),
            
            counterContainerView.topAnchor.constraint(equalTo: cameraContainerView.bottomAnchor),
            counterContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            counterContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            counterContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            stackView.heightAnchor.constraint(equalTo: counterContainerView.heightAnchor, multiplier: 0.6),
            stackView.widthAnchor.constraint(equalToConstant: 100),
            stackView.centerXAnchor.constraint(equalTo: counterContainerView.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: counterContainerView.centerYAnchor)
        ])
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {

        guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        let faceLandmarksRequest = VNDetectFaceLandmarksRequest { [weak self] request, error in
            if let error = error {
                self?.viewModel.actionSubject.send(.counterError)
                self?.alert.show(error, for: self)
            }
            
            DispatchQueue.main.async {
                self?.faceLayers.forEach { $0.removeFromSuperlayer() }
                if let faceObervations = request.results as? [VNFaceObservation] {
                    self?.viewModel.actionSubject.send(
                        .updateCounter(numberOfFaces: faceObervations.count)
                    )
                    self?.handleObservations(faceObervations)
                }
            }
        }
        
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: buffer, orientation: .leftMirrored, options: [:])
        
        do {
            try imageRequestHandler.perform([faceLandmarksRequest])
        } catch {
            print(error)
        }
    }
    
    private func handleObservations(_ observations: [VNFaceObservation]) {
        for observation in observations {
            let faceRectConverted = self.previewLayer.layerRectConverted(fromMetadataOutputRect: observation.boundingBox)
            let faceRectanglePath = CGPath(rect: faceRectConverted, transform: nil)
            
            let faceLayer = CAShapeLayer()
            faceLayer.path = faceRectanglePath
            faceLayer.fillColor = UIColor.clear.cgColor
            faceLayer.strokeColor = UIColor.yellow.cgColor
            
            self.faceLayers.append(faceLayer)
            self.view.layer.addSublayer(faceLayer)
        }
    }
}
