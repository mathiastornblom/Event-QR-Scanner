//
//  QRScannerViewController.swift
//  Event QR-Scanner
//
//  Created by Mathias Törnblom on 2024-04-08.
//


import UIKit
import AVFoundation

/// A view controller that manages the capture and decoding of QR codes using the device's camera.
class QRScannerViewController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var captureSession: AVCaptureSession!
    var previewLayer: AVCaptureVideoPreviewLayer!
    
    /// Callback for when a QR code is successfully scanned.
    var onCodeScanned: ((String) -> Void)?

    private var isProcessingCode = false
    private let debounceDelay: TimeInterval = 2

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCaptureSession()
    }

    /// Sets up the camera capture session for scanning QR codes.
    private func setupCaptureSession() {
        #if !targetEnvironment(simulator)
            captureSession = AVCaptureSession()
            captureSession.beginConfiguration()  // Start configuration changes

            guard let videoCaptureDevice = AVCaptureDevice.default(for: .video) else {
                fatalError(NSLocalizedString("error_no_video_device", comment: "No video device found error"))
            }
            
            do {
                let videoInput = try AVCaptureDeviceInput(device: videoCaptureDevice)
                if captureSession.canAddInput(videoInput) {
                    captureSession.addInput(videoInput)
                } else {
                    fatalError(NSLocalizedString("error_cannot_add_video_input", comment: "Can't add video input error"))
                }
            } catch {
                fatalError(NSLocalizedString("error_unable_to_create_video_input", comment: "Unable to create video input error"))
            }

            let metadataOutput = AVCaptureMetadataOutput()
            if captureSession.canAddOutput(metadataOutput) {
                captureSession.addOutput(metadataOutput)
                metadataOutput.setMetadataObjectsDelegate(self, queue: DispatchQueue.main)
                metadataOutput.metadataObjectTypes = [.qr]
            } else {
                fatalError(NSLocalizedString("error_cannot_add_metadata_output", comment: "Can't add metadata output error"))
            }

            captureSession.commitConfiguration()  // Commit configuration changes

            previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.frame = view.layer.bounds
            previewLayer.videoGravity = .resizeAspectFill
            view.layer.addSublayer(previewLayer)
        #else
            // Implement mock preview setup or informational message for the simulator
            print("Camera setup is skipped in the simulator.")
        #endif
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.startRunning()
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            self?.captureSession.stopRunning()
        }
    }

    /// Handles the output of detected metadata objects from the capture session.
    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard !isProcessingCode, let metadataObject = metadataObjects.first as? AVMetadataMachineReadableCodeObject, let scannedCode = metadataObject.stringValue else { return }

        isProcessingCode = true
        DispatchQueue.main.async { [weak self] in
            self?.onCodeScanned?(scannedCode)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + debounceDelay) { [weak self] in
            self?.isProcessingCode = false
        }
    }
}
