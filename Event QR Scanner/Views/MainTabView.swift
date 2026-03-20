//
//  MainTabView.swift
//  Event QR-Scanner
//
//  Created by Mathias Törnblom on 2024-04-09.
//

import SwiftUI

struct MainTabView: View {
    @ObservedObject var viewModel: ScanningStationViewModel
    @ObservedObject var appSettings: AppSettings
    @State private var selectedTab = "scan"

    var body: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                if appSettings.selectedStation != nil {
                    ScanView(stationViewModel: viewModel, appSettings: appSettings, selectedTab: $selectedTab)
                        .tabItem {
                            Label(NSLocalizedString("scan", comment: "Tab title for scanning QR codes"), systemImage: "qrcode.viewfinder")
                        }
                        .tag("scan")
                } else {
                    VStack(spacing: 12) {
                        Text(NSLocalizedString("please_select_a_scanning_station", comment: "Prompt to select a scanning station"))
                            .multilineTextAlignment(.center)
                        Button(NSLocalizedString("open_settings", comment: "Open settings")) {
                            selectedTab = "settings"
                        }
                    }
                    .padding()
                    .tag("scan")
                }
                
                SettingsView(stationViewModel: viewModel, appSettings: appSettings, selectedTab: $selectedTab)
                    .tabItem {
                        Label(NSLocalizedString("settings", comment: "Tab title for settings"), systemImage: "gear")
                    }
                    .tag("settings")

                CodeLookupView(appSettings: appSettings, selectedTab: $selectedTab)
                    .tabItem {
                        Label(NSLocalizedString("lookup_tab", comment: "Lookup tab"), systemImage: "magnifyingglass")
                    }
                    .tag("lookup")

                HistoryView(historyStore: .shared, appSettings: appSettings)
                    .tabItem {
                        Label(NSLocalizedString("history", comment: "History"), systemImage: "clock")
                    }
                    .tag("history")

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
