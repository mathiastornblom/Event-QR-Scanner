//
//  ContentView.swift
//  Event QR-Scanner
//
//  Created by Mathias Törnblom on 2024-04-09.
//

import SwiftUI

struct ContentView: View {
    @StateObject var viewModel = ScanningStationViewModel.shared  // Use the shared instance
    @StateObject var appSettings = AppSettings(scanDelay: 5, selectedStation: nil)  // Initialize AppSettings with default values

    var body: some View {
        NavigationStack {
            if viewModel.selectedStation != nil {
                // If a station is selected, navigate to the MainTabView
                // Pass both viewModel and appSettings to MainTabView
                MainTabView(viewModel: viewModel, appSettings: appSettings)
            } else {
                // If no station is selected, present the HomeView
                // Assuming HomeView also needs appSettings based on your app's logic
                HomeView(viewModel: viewModel)
            }
        }
    }
}

// Provides a SwiftUI preview of ContentView.
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
