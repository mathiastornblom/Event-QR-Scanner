//
//  SplashView.swift
//  Event QR-Scanner
//
//  Created by Mathias Törnblom on 2024-04-09.
//

import SwiftUI

struct SplashView: View {
    @StateObject private var eventsViewModel = EventsViewModel()
    @StateObject private var stationViewModel = ScanningStationViewModel.shared
    @StateObject private var appSettings = AppSettings(scanDelay: 5, selectedStation: nil, selectedEvent: nil)
    @State private var isActive = false
    @State private var isDataLoaded = false

    var body: some View {
        VStack {
            if isActive {
                // 1) If no event selected → show event picker
                if appSettings.selectedEvent == nil {
                    EventSelectionView(eventsVM: eventsViewModel, appSettings: appSettings)

                // 2) If event selected but no station → station selection
                } else if appSettings.selectedStation == nil {
                    StationSelectionView(stationViewModel: stationViewModel, appSettings: appSettings)

                // 3) Both event & station selected → main content
                } else {
                    MainTabView(viewModel: stationViewModel, appSettings: appSettings)
                }
            } else {
                // Splash screen content with logo and title
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

    /// Loads initial data: events and stations (if event saved), then activates navigation
    private func fetchInitialData() {
        Task {
            // Fetch events first
            await eventsViewModel.fetchEvents()

            // If an event was already selected (from previous run), fetch stations for it
            if let savedEvent = appSettings.selectedEvent {
                await stationViewModel.fetchStations(for: savedEvent)
            }

            // All data loaded, transition away from splash
            isDataLoaded = true
            withAnimation {
                isActive = true
            }
        }
    }
}

struct SplashView_Previews: PreviewProvider {
    static var previews: some View {
        SplashView()
    }
}
