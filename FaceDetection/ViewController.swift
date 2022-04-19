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
    private var containerView: UIView!
    private var stackView: UIStackView!
    
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
        containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(containerView)
        
        previewLayer.videoGravity = .resizeAspectFill
        
    }
    
    private func configureCounter() {
        stackView = UIStackView()
        stackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stackView)
    }

    private func setConstraints() {
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.6),
            
            stackView.topAnchor.constraint(equalTo: containerView.bottomAnchor)
        ])
    }
}

