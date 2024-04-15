//
//  QRCodeViewModel.swift
//  Event QR-Scanner
//
//  Created by Mathias Törnblom on 2024-04-08.
//

import Foundation

class QRCodeViewModel: ObservableObject {
    @Published var lastScanResult: ScanResult?

    // New method signature includes all required parameters for the API call
    func validateQRCode(_ code: String, forEvent event: String, atScanStation scanStation: String) async {
        let urlString = "https://prod-23.westeurope.logic.azure.com:443/workflows/ba63d86f962b403b983f83b8a3af381a/triggers/manual/paths/invoke?api-version=2016-06-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=kIDw9TpFLGUiEkobEZr-VCJjYRQ54yjS0Iqa9euJqHk"
        
        guard let url = URL(string: urlString) else {
            print("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["code": code, "event": event, "scanstation": scanStation]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        do {
            let (data, _) = try await URLSession.shared.data(for: request)
            let decoder = JSONDecoder()
            if let scanResult = try? decoder.decode(ScanResult.self, from: data) {
                DispatchQueue.main.async { [weak self] in
                    // Update the published property with the decoded result
                    self?.lastScanResult = scanResult
                }
            } else {
                print("Failed to decode the scan result.")
            }
        } catch {
            print("Network request failed: \(error.localizedDescription)")
        }
    }
}

