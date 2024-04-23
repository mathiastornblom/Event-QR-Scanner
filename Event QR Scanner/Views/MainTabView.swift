//
//  MainTabView.swift
//  Event QR-Scanner
//
//  Created by Mathias Törnblom on 2024-04-09.
//

import SwiftUI

struct MainTabView: View {
    @ObservedObject var viewModel: ScanningStationViewModel
    @ObservedObject var appSettings: AppSettings  // Using AppSettings

    var body: some View {
        NavigationView {
            TabView {
                if appSettings.selectedStation != nil {
                    ScanView(stationViewModel: viewModel, appSettings: appSettings)
                        .tabItem {
                            Label(NSLocalizedString("scan", comment: "Tab title for scanning QR codes"), systemImage: "qrcode.viewfinder")
                        }
                        .tag("scan")
                } else {
                    Text(NSLocalizedString("please_select_a_scanning_station", comment: "Prompt to select a scanning station"))
                }
                
                SettingsView(stationViewModel: viewModel, appSettings: appSettings)
                    .tabItem {
                        Label(NSLocalizedString("settings", comment: "Tab title for settings"), systemImage: "gear")
                    }
                    .tag("settings")
                
                AboutView()
                    .tabItem {
                        Label(NSLocalizedString("about", comment: "Tab title for about page"), systemImage: "person.fill")
                    }
                    .tag("about")
            }
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView(viewModel: ScanningStationViewModel.shared, appSettings: AppSettings(scanDelay: 5, selectedStation: nil))
    }
}
