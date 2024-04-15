//
//  TorchManager.swift
//  Event QR-Scanner
//
//  Created by Mathias Törnblom on 2024-04-13.
//

import Foundation
import AVFoundation

class TorchManager {
    static let shared = TorchManager()
    
    func toggleTorch(on flag: Bool) {
        guard let device = AVCaptureDevice.default(for: .video), device.hasTorch else { return }
        
        do {
            try device.lockForConfiguration()
            if flag && device.torchMode == .off {
                try device.setTorchModeOn(level: AVCaptureDevice.maxAvailableTorchLevel)
            } else {
                device.torchMode = .off
            }
            device.unlockForConfiguration()
        } catch {
            print("Torch could not be used")
        }
    }
}
