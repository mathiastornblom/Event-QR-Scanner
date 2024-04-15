//
//  SplashView.swift
//  Event QR-Scanner
//
//  Created by Mathias Törnblom on 2024-04-09.
//

import SwiftUI

struct SplashView: View {
    @StateObject private var stationViewModel = ScanningStationViewModel.shared // Using shared instance of the station view model.
    @StateObject private var appSettings = AppSettings(scanDelay: 5, selectedStation: nil) // Initialize AppSettings here.
    @State private var isActive = false // Tracks whether the splash screen should transition to the main content.
    @State private var isDataLoaded = false // Indicates whether initial data loading is complete.
    
    var body: some View {
        VStack {
            if isActive {
                // Conditionally navigate to either the main content or the station selection screen.
                if let _ = stationViewModel.selectedStation {
                    ContentView() // Navigate to the main view if a station is already selected.
                } else {
                    StationSelectionView(stationViewModel: stationViewModel, appSettings: appSettings)
                }
            } else {
                // Splash screen content with a logo and title.
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200, height: 200)
                Text(NSLocalizedString("event_qr_scanner", comment: "Main title on the splash screen"))
                    .font(.largeTitle)
                    .fontWeight(.bold)
                if !isDataLoaded {
                    ProgressView(NSLocalizedString("loading", comment: "Loading indicator text"))
                }
            }
        }
        .onAppear {
            fetchInitialData()
        }
    }

    private func fetchInitialData() {
        Task {
            await stationViewModel.fetchStations()
            isDataLoaded = true
            withAnimation {
                isActive = true
            }
        }
    }
}

// Provides a SwiftUI preview of SplashView.
struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
    }
}
