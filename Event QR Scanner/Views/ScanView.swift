//
//  ScanView.swift
//  Event QR-Scanner
//
//  Created by Mathias Törnblom on 2024-04-09.
//

import SwiftUI

struct ScanView: View {
    @ObservedObject var stationViewModel: ScanningStationViewModel
    @ObservedObject var appSettings: AppSettings
    @Binding var selectedTab: String
    @StateObject var qrViewModel: QRCodeProcessingViewModel
    @State private var isTorchOn = false

    init(stationViewModel: ScanningStationViewModel, appSettings: AppSettings, selectedTab: Binding<String>) {
        self.stationViewModel = stationViewModel
        self.appSettings = appSettings
        self._selectedTab = selectedTab
        _qrViewModel = StateObject(wrappedValue: QRCodeProcessingViewModel(appSettings: appSettings, historyStore: .shared))
    }

    var body: some View {
        VStack {
            HStack {
                Text(NSLocalizedString("scan_qr", comment: "Title for scanning QR codes"))
                    .font(.headline)
                Spacer()
            }

            Button {
                selectedTab = "settings"
            } label: {
                EventBrandingHeaderView(
                    event: appSettings.selectedEvent,
                    subtitle: String(format: NSLocalizedString("selected_station_format", comment: "Selected station label"), appSettings.selectedStation?.name ?? NSLocalizedString("none_selected", comment: "No selection"))
                )
            }
            .buttonStyle(.plain)
            .padding(.bottom, 8)

            ZStack {
                if qrViewModel.isReadyToScanAgain {
                    scannerView()
                } else if let lastScanResult = qrViewModel.lastScanResult {
                    scanResultView(lastScanResult: lastScanResult)
                } else {
                    ProgressView()
                }
            }
            .frame(width: UIScreen.main.bounds.width * 0.9, height: UIScreen.main.bounds.height * 0.46)
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.secondary, lineWidth: 2))
            .padding(.bottom, 16)

            HStack {
                Spacer()
                Button {
                    isTorchOn.toggle()
                    TorchManager.shared.toggleTorch(on: isTorchOn)
                } label: {
                    Image(systemName: isTorchOn ? "flashlight.on.fill" : "flashlight.off.fill")
                        .foregroundColor(isTorchOn ? .yellow : .gray)
                        .imageScale(.large)
                        .frame(minWidth: 44, minHeight: 44)
                        .contentShape(Rectangle())
                        .padding(4)
                }
                .accessibilityLabel(NSLocalizedString("toggle_flashlight", comment: "Toggle flashlight"))
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
    }

    @ViewBuilder
    private func scannerView() -> some View {
        QRScannerView { scannedCode in
            Task {
                await qrViewModel.processScannedCode(
                    scannedCode,
                    selectedRight: appSettings.selectedStation
                )
            }
        }
        .accessibilityLabel(NSLocalizedString("qr_scanner_view", comment: "QR scanner view"))
    }

    @ViewBuilder
    private func scanResultView(lastScanResult: ScanResult) -> some View {
        ScrollView {
            VStack(spacing: 12) {
                Image(systemName: statusIconName(for: lastScanResult))
                    .resizable()
                    .scaledToFit()
                    .foregroundColor(statusIconColor(for: lastScanResult))
                    .frame(width: 72, height: 72)

                Text(lastScanResult.statusTitle)
                    .font(.headline)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                if let detailMessage = lastScanResult.detailMessage, !detailMessage.isEmpty {
                    Text(detailMessage)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(String(format: NSLocalizedString("code_format", comment: "Code label"), lastScanResult.scannedData))
                    Text(String(format: NSLocalizedString("person_format", comment: "Person label"), lastScanResult.holderName))
                    if let club = lastScanResult.club {
                        Text(String(format: NSLocalizedString("club_format", comment: "Club label"), club))
                    }
                    if let team = lastScanResult.team {
                        Text(String(format: NSLocalizedString("team_format", comment: "Team label"), team))
                    }
                    if let role = lastScanResult.role {
                        Text(String(format: NSLocalizedString("role_format", comment: "Role label"), role))
                    }
                    if let consumed = lastScanResult.consumedRight {
                        Text(String(format: NSLocalizedString("used_station_format", comment: "Used station label"), consumed))
                    }
                    if lastScanResult.showRemaining {
                        Text(lastScanResult.isValid ? String(format: NSLocalizedString("remaining_selected_station_format", comment: "Remaining selected station"), lastScanResult.scansLeft) : String(format: NSLocalizedString("remaining_after_scan_format", comment: "Remaining after scan"), lastScanResult.scansLeft))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)

                if !lastScanResult.isValid, !lastScanResult.rights.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(NSLocalizedString("stations_for_code", comment: "Stations for code"))
                            .font(.headline)
                        ForEach(lastScanResult.rights, id: \.self) { right in
                            HStack {
                                Text(right.name)
                                Spacer()
                                if right.unlimited {
                                    Text(NSLocalizedString("unlimited", comment: "Unlimited quota"))
                                        .foregroundColor(.secondary)
                                } else if let remaining = right.remaining, let total = right.total {
                                    Text(String(format: NSLocalizedString("remaining_total_format", comment: "remaining/total"), remaining, total))
                                        .foregroundColor(.secondary)
                                } else if let total = right.total {
                                    Text(String(format: NSLocalizedString("total_only_format", comment: "Total only"), total))
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                if appSettings.isDebugEnabled, let debugMessage = lastScanResult.debugMessage, !debugMessage.isEmpty {
                    Text(String(format: NSLocalizedString("scan_debug_detail_format", comment: "Debug detail"), debugMessage))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
        .cornerRadius(20)
    }

    private func statusIconName(for result: ScanResult) -> String {
        if result.isTechnicalError {
            return "exclamationmark.triangle.fill"
        }
        return result.isValid ? "checkmark.circle.fill" : "xmark.circle.fill"
    }

    private func statusIconColor(for result: ScanResult) -> Color {
        if result.isTechnicalError {
            return .yellow
        }
        return result.isValid ? .green : .red
    }
}

struct ScanView_Previews: PreviewProvider {
    static var previews: some View {
        let mockData = ScanningStationViewModel()
        let mockStation = ScanningStation(id: "1", name: "USM26-0001 - Preview")
        let appSettings = AppSettings(scanDelay: 2, selectedStation: mockStation)
        return ScanView(stationViewModel: mockData, appSettings: appSettings, selectedTab: .constant("scan"))
    }
}
