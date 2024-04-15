//
//  StationSelectionView.swift
//  Event QR-Scanner
//
//  Created by Mathias Törnblom on 2024-04-12.
//

import SwiftUI

struct StationSelectionView: View {
    @ObservedObject var stationViewModel: ScanningStationViewModel
    @ObservedObject var appSettings: AppSettings
    @State private var navigateToMain = false  // State to control navigation

    var body: some View {
        NavigationStack {
            List(stationViewModel.stations, id: \.id) { station in
                Button(action: {
                    appSettings.selectedStation = station
                    appSettings.saveToLocal()  // Save the selection to local storage
                    navigateToMain = true  // Set the navigation trigger
                }) {
                    HStack {
                        Text(station.name)
                        Spacer()
                        if appSettings.selectedStation == station {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                }
            }
            .navigationTitle(NSLocalizedString("select_a_station", comment: "Title for selecting a station"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await stationViewModel.fetchStations()
                        }
                    }) {
                        Image(systemName: "arrow.clockwise").accessibilityLabel(NSLocalizedString("refresh", comment: "Button label for refreshing the list"))
                    }
                }
            }
            .listStyle(.plain)
            .navigationDestination(isPresented: $navigateToMain) {
                MainTabView(viewModel: stationViewModel, appSettings: appSettings)
            }
        }
        .onAppear {
            if stationViewModel.stations.isEmpty {
                Task {
                    await stationViewModel.fetchStations()
                }
            }
        }
    }
}

// Provides a SwiftUI preview of StationSelectionView with a mock setup
struct StationSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        let mockData = ScanningStationViewModel.shared
        let settings = AppSettings(scanDelay: 5, selectedStation: nil)
        // Assuming some stations are preloaded for preview
        mockData.stations = [ScanningStation(id: "1", name: "Station One"), ScanningStation(id: "2", name: "Station Two")]
        return StationSelectionView(stationViewModel: mockData, appSettings: settings)
    }
}
