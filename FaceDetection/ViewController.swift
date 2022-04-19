//
//  ViewController.swift
//  FaceDetection
//
//  Created by J on 2022-04-19.
//

import UIKit
import Vision
import AVFoundation

final class ViewController: UIViewController {
    private var captureSession: AVCaptureSession!
    private var previewLayer: AVCaptureVideoPreviewLayer!
    private var videoDataOutput: AVCaptureVideoDataOutput!
    private var faceLayers: [CAShapeLayer]!
    private var cameraContainerView: UIView!
    private var counterContainrView: UIView!
    private var stackView: UIStackView!
    private var counterLabel: UILabel!
    private var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureInitialSetup()
        configureCamera()
        configureCounter()
        setConstraints()
    }

    private func configureInitialSetup() {
        captureSession = AVCaptureSession()
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoDataOutput = AVCaptureVideoDataOutput()
        faceLayers = [CAShapeLayer]()
    }
    
    private func configureCamera() {
        let discoverySession = AVCaptureDevice.DiscoverySession(deviceTypes: [.builtInTrueDepthCamera, .builtInWideAngleCamera], mediaType: .video, position: .front)
        
        guard let device = discoverySession.devices.first,
              let captureDeviceInput = try? AVCaptureDeviceInput(device: device),
              captureSession.canAddInput(captureDeviceInput) else { return }
        
        configurePreview()
    }
    
    private func configurePreview() {
        cameraContainerView = UIView()
        cameraContainerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(cameraContainerView)
        
        previewLayer.videoGravity = .resizeAspectFill
        cameraContainerView.layer.addSublayer(previewLayer)
        previewLayer.frame = CGRect(origin: .zero, size: CGSize(width: cameraContainerView.bounds.width, height: cameraContainerView.bounds.height))
        
        self.videoDataOutput.videoSettings = [(kCVPixelBufferPixelFormatTypeKey as NSString) : NSNumber(value: kCVPixelFormatType_32BGRA)] as [String : Any]
        self.videoDataOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "camera"))
        self.captureSession.addOutput(self.videoDataOutput)
        
        let videoConnection = self.videoDataOutput.connection(with: .video)
        videoConnection?.videoOrientation = .portrait
    }
    
    private func configureCounter() {
        counterContainrView = UIView()
        counterContainrView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(counterContainrView)
        
        counterLabel = UILabel()
        counterLabel.text = "0"
        counterLabel.font = UIFont.systemFont(ofSize: 50, weight: .bold)
        counterLabel.adjustsFontForContentSizeCategory = true
        counterLabel.accessibilityHint = "Number of faces detected"
        counterLabel.textAlignment = .center
        
        let imageConfig = UIImage.SymbolConfiguration(scale: .medium)
        let image = UIImage(systemName: "person.2.fill", withConfiguration: imageConfig)?.withTintColor(.gray, renderingMode: .alwaysOriginal)
        imageView = UIImageView(image: image)
        imageView.contentMode = .scaleAspectFit
        imageView.accessibilityHint = "Camera to detect faces"
        
        stackView = UIStackView(arrangedSubviews: [counterLabel, imageView])
        stackView.distribution = .fillEqually
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
    }

    private func setConstraints() {
        NSLayoutConstraint.activate([
            cameraContainerView.topAnchor.constraint(equalTo: view.topAnchor),
            cameraContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            cameraContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            cameraContainerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.6),
            
            counterContainrView.topAnchor.constraint(equalTo: cameraContainerView.bottomAnchor),
            counterContainrView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            counterContainrView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            counterContainrView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            
            stackView.heightAnchor.constraint(equalTo: counterContainrView.heightAnchor, multiplier: 0.6),
            stackView.widthAnchor.constraint(equalToConstant: 100),
            stackView.centerXAnchor.constraint(equalTo: counterContainrView.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: counterContainrView.centerYAnchor)
        ])
    }
}

extension ViewController: AVCaptureVideoDataOutputSampleBufferDelegate {

}
