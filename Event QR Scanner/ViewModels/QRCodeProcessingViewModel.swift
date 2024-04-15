//
//  QRCodeProcessingViewModel.swift
//  Event QR-Scanner
//
//  Created by Mathias Törnblom on 2024-04-09.
//

import Foundation
import Combine

class QRCodeProcessingViewModel: ObservableObject {
    // Properties to manage the scan state and results.
    @Published var lastScanResult: ScanResult? = nil
    @Published var isReadyToScanAgain = true
    
    
    // Reference to settings view model to access global settings.
    private var appSettings: AppSettings
    private var soundManager = SoundManager.shared
    private var hapticManager = HapticsManager.shared
    
    init(appSettings: AppSettings) {
        self.appSettings = appSettings
    }

    // Processes a scanned QR code by making an API call and then applying a delay.
     // Ensures that the operation is performed on the main thread and respects the current scan delay setting.
     @MainActor
     func processScannedCode(_ scannedCode: String, event: String, scanStation: String) async {
         // Ensure we do not process a new scan until the current one is complete and the delay has passed.
         guard isReadyToScanAgain else { return }
         
         isReadyToScanAgain = false // Prevent starting a new scan.
         
         // Perform the network request to process the scanned code.
         // This might involve sending the code to a backend service for validation.
         await performNetworkRequest(scannedCode: scannedCode, event: event, scanStation: scanStation)
         
         // Sound and haptic feedback based on scan result
          if let result = lastScanResult {
              if result.isValid {
                  soundManager.playSound(type: .success)
                  hapticManager.playHaptic(type: .success)
              } else {
                  soundManager.playSound(type: .failure)
                  hapticManager.playHaptic(type: .failure)
              }
          }
         
         // Retrieve the current scan delay setting.
         let delay = appSettings.scanDelay
         print("Current scanDelay value: \(delay) seconds.")
         
         // Apply the delay using Task.sleep, which suspends the current task for the specified duration.
         // Here, we convert the delay from seconds to nanoseconds as required by Task.sleep.
         print("Wait for \(delay) seconds. Start time: \(NSDate())")
         do {
             try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
         } catch {
             // Handle potential cancellation of the sleep task.
             print("Sleep was interrupted: \(error)")
         }
                  
         // After the delay has passed, allow for a new scan.
         isReadyToScanAgain = true
         print("Finish waiting. Stop time: \(NSDate())")
     }
     
     // Placeholder for the network request implementation.
     // This method should be adapted to perform the actual network request for processing the scanned code.
    
    private func performNetworkRequest(scannedCode: String, event: String, scanStation: String) async {
        let urlString = "https://prod-23.westeurope.logic.azure.com:443/workflows/ba63d86f962b403b983f83b8a3af381a/triggers/manual/paths/invoke?api-version=2016-06-01&sp=%2Ftriggers%2Fmanual%2Frun&sv=1.0&sig=kIDw9TpFLGUiEkobEZr-VCJjYRQ54yjS0Iqa9euJqHk"
        
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async { self.isReadyToScanAgain = true }
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = ["code": scannedCode, "event": event, "scanstation": scanStation]
        request.httpBody = try? JSONSerialization.data(withJSONObject: body, options: [])
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
                print("Server responded with an error")
                await MainActor.run { self.isReadyToScanAgain = true }
                return
            }

            let decoder = JSONDecoder()
            if let scanResult = try? decoder.decode(ScanResult.self, from: data) {
                // Update the UI with the result on the main thread.
                await updateUIWithResult(scanResult)
            } else {
                print("Failed to decode the scan result.")
            }
        } catch {
            print("Network request failed: \(error.localizedDescription)")
        }
        

    }

    // Ensures updates are performed on the main thread.
    @MainActor
    private func updateUIWithResult(_ scanResult: ScanResult) {
        self.lastScanResult = scanResult
    }

    // Manually resets the ViewModel to be ready for a new scan.
    @MainActor
    func resetForNewScan() {
       isReadyToScanAgain = true
    lastScanResult = nil
    }
}
