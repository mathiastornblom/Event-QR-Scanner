//
//  SettingsView.swift
//  Event QR-Scanner
//
//  Created by Mathias Törnblom on 2024-04-09.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var stationViewModel: ScanningStationViewModel
    @ObservedObject var appSettings: AppSettings
    @Environment(\.presentationMode) var presentationMode
    @State private var isLoading = false  // State to manage loading indicator
    
    var body: some View {
            Form {
                Section(header: Text(NSLocalizedString("scan_settings", comment: "Section header for scan settings"))) {
                    Stepper(NSLocalizedString("scan_delay_seconds", comment: "Stepper label for scan delay") + " \(appSettings.scanDelay)", value: $appSettings.scanDelay, in: 0...10)
                }

                Section(header: Text(NSLocalizedString("select_scanning_station", comment: "Section header for selecting a scanning station"))) {
                    if isLoading {
                        ProgressView() // Display spinner when loading
                    } else {
                        Picker(NSLocalizedString("scanning_station", comment: "Picker label for selecting a station"), selection: $appSettings.selectedStation) {
                            Text(NSLocalizedString("none", comment: "Picker item for no station selection")).tag(ScanningStation?.none)
                            ForEach(stationViewModel.stations, id: \.self) { station in
                                Text(station.name).tag(station as ScanningStation?)
                            }
                        }
                        .pickerStyle(WheelPickerStyle()) // Improved picker style for better UX
                    }
                    Button(NSLocalizedString("refresh_stations", comment: "Button text for refreshing station list")) {
                        Task {
                            isLoading = true
                            await stationViewModel.fetchStations()
                            isLoading = false
                        }
                    }
                }
            }
        .onAppear {
            // Ensure the stations are loaded upon view appearance
            if stationViewModel.stations.isEmpty {
                Task {
                    await stationViewModel.fetchStations()
                }
            }
            print("SettingsView loaded with current scan delay: \(appSettings.scanDelay) and selected station: \(String(describing: appSettings.selectedStation?.name))")
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        let stationViewModel = ScanningStationViewModel.shared
        let appSettings = AppSettings(scanDelay: 5, selectedStation: nil)
        return SettingsView(stationViewModel: stationViewModel, appSettings: appSettings)
    }
}
