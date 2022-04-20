//
//  ViewController.swift
//  FaceDetection
//
//  Created by J on 2022-04-19.
//

/*
 Abstract:
 Face Detection app using the MVVM architecture.  A view model uses Combine to listen to the changes in the number of faces detected and updates its state to be reflected on the UI.
 */

import UIKit
import Vision
import AVFoundation
import Combine

final class ViewController: UIViewController {
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var videoDataOutput: AVCaptureVideoDataOutput!
    private var faceDetectionLayers: [CAShapeLayer]!
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
        /// Initialize the UI to 0 face detected upon load
        viewModel.actionSubject.send(.initialize)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        previewLayer.frame = CGRect(origin: .zero, size: CGSize(width: cameraContainerView.bounds.width, height: cameraContainerView.bounds.height))
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)

        /// Adjust the preview layer's orientation depending on the orientation of the device.
        guard let connection = previewLayer?.connection else { return }

        switch UIDevice.current.orientation {
            case .portraitUpsideDown:
                connection.videoOrientation = .portraitUpsideDown
            case .landscapeLeft:
                connection.videoOrientation = .landscapeRight
            case .landscapeRight:
                connection.videoOrientation = .landscapeLeft
            default:
                connection.videoOrientation = .portrait
        }
    }

    private func configureInitialSetup() {
        captureSession = AVCaptureSession()
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoDataOutput = AVCaptureVideoDataOutput()
        faceDetectionLayers = [CAShapeLayer]()
    }
    
    private func configureCancellable() {
        /// When face detect request returns obervations, the number of obervations updates the counter in view model, which in turn emits state effect to update the UI accordingly.
        viewModel.stateEffectSubject
            .sink { [weak self] (stateEffect) in
                switch stateEffect {
                case .initialized:
                    /// When the app is initialized, initilized the UI with 0 face detected
                    DispatchQueue.main.async {
                        self?.counterLabel.text = "0"
                        let image = UIImage(systemName: "person" , withConfiguration: self!.imageConfig)?.withTintColor(.gray, renderingMode: .alwaysOriginal)
                        self?.imageView.image = image
                    }
                case .updateCounter(let num):
                    /// Update the UI according to the number of face detected
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
    
    /// Determine SF Symbol depending on the number of faces detected
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
        /// Discover a camera
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInWideAngleCamera], mediaType: .video, position: .front)
        
        guard let device = discoverySession.devices.first,
              let captureDeviceInput = try? AVCaptureDeviceInput(device: device),
              captureSession.canAddInput(captureDeviceInput) else { return }
        
        /// Add the camera to AVCaptureSession to perform a rea-time capture.
        captureSession.addInput(captureDeviceInput)
        configurePreview()
    }
    
    private func configurePreview() {
        /// Container view to include the view finder of the camera
        cameraContainerView = UIView()
        cameraContainerView.accessibilityHint = "Camera view finder"
        cameraContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cameraContainerView)
        
        /// Add the preview layer (the view finder) to the container view
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

    /// Conatiner view for the counter label and a SF Symbol
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

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {

        guard let buffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            return
        }
        
        /// Create a request for detecting face observations specifically
        let faceLandmarksRequest = VNDetectFaceLandmarksRequest { [weak self] request, error in
            
            /// Handle the detection error by updating the view model's counter to 0 and showing an alert message
            if let error = error {
                self?.viewModel.actionSubject.send(.counterError)
                self?.alert.show(error, for: self)
            }
            
            /// Called on the main thread since it updates the UI
            DispatchQueue.main.async {
                /// Once new observations objects are created, remove any pre-existing face detection rectangles on the screen
                self?.faceDetectionLayers.forEach { $0.removeFromSuperlayer() }
                
                if let faceObervations = request.results as? [VNFaceObservation] {
                    /// Update the view model's counter property, which will in turn update the UI
                    self?.viewModel.actionSubject.send(
                        .updateCounter(numberOfFaces: faceObervations.count)
                    )
                    
                    ///Create the face detection rectangles
                    self?.handleObservations(faceObervations)
                }
            }
        }
        
        /// Using the captured image buffer, create a Vision request and perform the request
        let imageRequestHandler = VNImageRequestHandler(cvPixelBuffer: buffer, orientation: .leftMirrored, options: [:])
        
        do {
            try imageRequestHandler.perform([faceLandmarksRequest])
        } catch {
            alert.show(error, for: self)
        }
    }
    
    private func handleObservations(_ observations: [VNFaceObservation]) {
        
        for observation in observations {
            /// converts the coordinate of the observation to the coordinate in the context of the preview layer
            let convertedLayerRect = previewLayer.layerRectConverted(fromMetadataOutputRect: observation.boundingBox)
            /// Create a rectangle CGPath
            let path = CGPath(rect: convertedLayerRect, transform: nil)
            
            /// Create a rectangle layer around a detected face
            let rectangleLayer = CAShapeLayer()
            rectangleLayer.path = path
            rectangleLayer.strokeColor = UIColor.green.cgColor
            rectangleLayer.fillColor = UIColor.clear.cgColor
            
            /// Add the layer to the preview layer
            faceDetectionLayers.append(rectangleLayer)
            previewLayer.addSublayer(rectangleLayer)
        }
    }
}

