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
    @State private var isLoading = false  // State to control the loading indicator

    var body: some View {
        NavigationView {
            List(stationViewModel.stations, id: \.id) { station in
                Button(action: {
                    appSettings.selectedStation = station
                    appSettings.saveToLocal()
                    navigateToMain = true
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
                .background(
                    NavigationLink("", destination: MainTabView(viewModel: stationViewModel, appSettings: appSettings), isActive: $navigateToMain)
                )
            }
            .navigationTitle(NSLocalizedString("select_a_station", comment: "Title for selecting a station"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isLoading = true
                        Task {
                            await stationViewModel.fetchStations()
                            isLoading = false
                        }
                    }) {
                        if isLoading {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise").accessibilityLabel(NSLocalizedString("refresh", comment: "Button label for refreshing the list"))
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
        .onAppear {
            if stationViewModel.stations.isEmpty {
                isLoading = true
                Task {
                    await stationViewModel.fetchStations()
                    isLoading = false
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
