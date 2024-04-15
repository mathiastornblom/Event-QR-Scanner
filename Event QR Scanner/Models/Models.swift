//
//  Models.swift
//  Event QR-Scanner
//
//  Created by Mathias Törnblom on 2024-04-08.
//

import Foundation

/// Represents a physical or logical scanning station in the QR scanning system.
/// - Tag: ScanningStation
struct ScanningStation: Hashable, Identifiable, Codable {
    let id: String
    let name: String
}

/// Encapsulates the result of scanning a QR code, providing details about the scan's validity, associated data, and any relevant metadata.
/// - Tag: ScanResult
struct ScanResult: Codable {
    var isValid: Bool  // Indicates if the QR code is valid.
    var holderName: String  // Name associated with the QR code.
    var scansLeft: Int  // Number of scans left for this QR code, if applicable.
    var scannedData: String  // The actual data from the scanned QR code.
    var message: String
    
    /// Returns a textual representation suitable for display, encapsulating the scan result's validity and message.
    var summary: String {
        "Scan for \(holderName) is \(isValid ? "valid" : "invalid"): \(message)"
    }
}
