//
//  QRScannerView.swift
//  Event QR-Scanner
//
//  Created by Mathias Törnblom on 2024-04-09.
//

import SwiftUI
import AVFoundation

struct QRScannerView: UIViewControllerRepresentable {
    var onCodeScanned: ((String) -> Void)
    
    func makeUIViewController(context: Context) -> QRScannerViewController {
        let viewController = QRScannerViewController()
        viewController.onCodeScanned = onCodeScanned
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: QRScannerViewController, context: Context) {
        // If you later add properties to QRScannerViewController that need to be updated, do it here.
        // Example: uiViewController.isScanningEnabled = someCondition
    }
    
    // Optionally, implement other lifecycle methods to manage resources or respond to SwiftUI view lifecycle events.
}
