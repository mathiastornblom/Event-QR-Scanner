//
//  ScanView.swift
//  Event QR-Scanner
//
//  Created by Mathias Törnblom on 2024-04-09.
//

import SwiftUI

/// Enum to represent different types of scan results.
enum ScanResultType {
    case success
    case failure
}

struct ScanView: View {
    @ObservedObject var stationViewModel: ScanningStationViewModel
    @ObservedObject var appSettings: AppSettings
    @StateObject var qrViewModel: QRCodeProcessingViewModel
    @State private var isTorchOn: Bool = false  // State to track torch status

    init(stationViewModel: ScanningStationViewModel, appSettings: AppSettings) {
        self.stationViewModel = stationViewModel
        self.appSettings = appSettings
        _qrViewModel = StateObject(wrappedValue: QRCodeProcessingViewModel(appSettings: appSettings))
    }
     
    var body: some View {
        VStack {
            Text(NSLocalizedString("scan_qr", comment: "Title for scanning QR codes")).font(.title)
            Text("\(NSLocalizedString("scanning_at", comment: "Label for scanning location")) \(appSettings.selectedStation?.name ?? NSLocalizedString("no_station_selected", comment: "Fallback text when no station is selected"))").font(.headline).padding()
            ZStack {
                if qrViewModel.isReadyToScanAgain {
                    scannerView()
                } else if let lastScanResult = qrViewModel.lastScanResult {
                    scanResultView(lastScanResult: lastScanResult)
                }
            }
            .frame(width: UIScreen.main.bounds.width * 0.9, height: UIScreen.main.bounds.height * 0.4)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.secondary, lineWidth: 4))
            .padding(.bottom, 20)
            // Using HStack to align the torch button to the right
            HStack {
                Spacer()  // This pushes the button to the right
                Button(action: {
                    isTorchOn.toggle()
                    TorchManager.shared.toggleTorch(on: isTorchOn)
                }) {
                    Image(systemName: isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                        .foregroundColor(isTorchOn ? .yellow : .gray)
                        .imageScale(.large)
                        .padding()
                }
            }
        }
        .padding()
    }

    @ViewBuilder
    private func scannerView() -> some View {
        QRScannerView { scannedCode in
            Task {
                if let currentStation = appSettings.selectedStation {
                    await qrViewModel.processScannedCode(scannedCode, event: "EventName", scanStation: currentStation.name)
                }
            }
        }
    }

    @ViewBuilder
    private func scanResultView(lastScanResult: ScanResult) -> some View {
        VStack {
            Image(systemName: lastScanResult.isValid ? "checkmark.circle.fill" : "xmark.circle.fill")
                .resizable()
                .scaledToFit()
                .foregroundColor(lastScanResult.isValid ? .green : .red)
                .frame(width: 100, height: 100)

            VStack(alignment: .leading) {
                Text("\(NSLocalizedString("qr_code_data", comment: "Label for QR code data")) \(lastScanResult.scannedData)")
                Text("\(NSLocalizedString("holder", comment: "Label for QR code holder")) \(lastScanResult.holderName)")
                Text("\(NSLocalizedString("scans_left", comment: "Label for scans left")) \(lastScanResult.scansLeft)")
                Text("\(NSLocalizedString("message", comment: "Label for additional message")) \(lastScanResult.message)")
            }
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(20)
    }
}

struct ScanView_Previews: PreviewProvider {
    static var previews: some View {
        let mockData = ScanningStationViewModel()
        let mockStation = ScanningStation(id: "1", name: "Preview Station")
        let appSettings = AppSettings(scanDelay: 5, selectedStation: mockStation)
        return ScanView(stationViewModel: mockData, appSettings: appSettings)
    }
}
