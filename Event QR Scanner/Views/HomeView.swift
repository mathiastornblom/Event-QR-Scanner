//
//  HomeView.swift
//  Event QR-Scanner
//
//  Created by Mathias Törnblom on 2024-04-08.
//

import SwiftUI

struct HomeView: View {
    @ObservedObject var viewModel: ScanningStationViewModel
    @State private var isLoading = true // Initially set to true to show the progress indicator
    
    var body: some View {
        NavigationView {
            ZStack {
                List(viewModel.stations) { station in
                    Button(action: {
                        viewModel.selectStation(station)
                    }) {
                        Text(station.name)
                            .padding()
                    }
                }
                .navigationTitle(NSLocalizedString("select_scanning_station", comment: "Title for selecting a scanning station"))
                // Ensure the progress view is on top of the list
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                        .scaleEffect(1.5)
                }
            }
        }
        .onAppear {
            print("HomeView appearing with \(viewModel.stations.count) stations.")
            Task {
                await viewModel.fetchStations()
                // Once stations are fetched, set isLoading to false
                isLoading = false
                print("HomeView loaded with \(viewModel.stations.count) stations.")
            }
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        let mockStations = [
            ScanningStation(id: "1", name: "Mock Station 1"),
            ScanningStation(id: "2", name: "Mock Station 2"),
            ScanningStation(id: "3", name: "Mock Station 3")
        ]
        HomeView(viewModel: ScanningStationViewModel(stations: mockStations))
    }
}
