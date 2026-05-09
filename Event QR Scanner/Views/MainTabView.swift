//
//  MainTabView.swift
//  Event QR-Scanner
//
//  Created by Mathias Törnblom on 2024-04-09.
//

import SwiftUI

struct MainTabView: View {
    var viewModel: ScanningStationViewModel
    var appSettings: AppSettings
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var selectedTab = "scan"
    // List(selection:) on iOS requires an optional binding
    @State private var sidebarSelection: String? = "scan"

    var body: some View {
        if #available(iOS 16.0, *), horizontalSizeClass == .regular {
            ipadSidebarView
        } else {
            iPhoneTabView
        }
    }

    // MARK: - iPad sidebar (iOS 16+)

    @available(iOS 16.0, *)
    private var ipadSidebarView: some View {
        NavigationSplitView {
            // iOS List(selection:) requires Binding<SelectionValue?> (optional)
            List(selection: $sidebarSelection) {
                Label(NSLocalizedString("scan", comment: "Tab title for scanning QR codes"), systemImage: "qrcode.viewfinder")
                    .tag("scan")
                Label(NSLocalizedString("lookup_tab", comment: "Lookup tab"), systemImage: "magnifyingglass")
                    .tag("lookup")
                Label(NSLocalizedString("history", comment: "History"), systemImage: "clock")
                    .tag("history")
                Label(NSLocalizedString("settings", comment: "Tab title for settings"), systemImage: "gear")
                    .tag("settings")
                Label(NSLocalizedString("about", comment: "Tab title for about page"), systemImage: "person.fill")
                    .tag("about")
            }
            .navigationTitle(NSLocalizedString("app_name", comment: "App name"))
            .listStyle(.sidebar)
            .onChange(of: sidebarSelection) { _, newValue in
                if let tab = newValue { selectedTab = tab }
            }
        } detail: {
            detailView(for: selectedTab)
        }
    }

    @ViewBuilder
    private func detailView(for tab: String) -> some View {
        switch tab {
        case "scan":     scanTab
        case "lookup":   CodeLookupView(appSettings: appSettings, selectedTab: $selectedTab)
        case "history":  HistoryView(historyStore: .shared, appSettings: appSettings)
        case "settings": SettingsView(stationViewModel: viewModel, appSettings: appSettings, selectedTab: $selectedTab)
        case "about":    AboutView()
        default:         scanTab
        }
    }

    // MARK: - iPhone tab bar

    private var iPhoneTabView: some View {
        NavigationView {
            TabView(selection: $selectedTab) {
                scanTab
                    .tabItem { Label(NSLocalizedString("scan", comment: "Tab title for scanning QR codes"), systemImage: "qrcode.viewfinder") }
                    .tag("scan")

                SettingsView(stationViewModel: viewModel, appSettings: appSettings, selectedTab: $selectedTab)
                    .tabItem { Label(NSLocalizedString("settings", comment: "Tab title for settings"), systemImage: "gear") }
                    .tag("settings")

                CodeLookupView(appSettings: appSettings, selectedTab: $selectedTab)
                    .tabItem { Label(NSLocalizedString("lookup_tab", comment: "Lookup tab"), systemImage: "magnifyingglass") }
                    .tag("lookup")

                HistoryView(historyStore: .shared, appSettings: appSettings)
                    .tabItem { Label(NSLocalizedString("history", comment: "History"), systemImage: "clock") }
                    .tag("history")

                AboutView()
                    .tabItem { Label(NSLocalizedString("about", comment: "Tab title for about page"), systemImage: "person.fill") }
                    .tag("about")
            }
        }
    }

    @ViewBuilder
    private var scanTab: some View {
        if appSettings.selectedStation != nil {
            ScanView(stationViewModel: viewModel, appSettings: appSettings, selectedTab: $selectedTab)
        } else {
            VStack(spacing: 12) {
                Text(NSLocalizedString("please_select_a_scanning_station", comment: "Prompt to select a scanning station"))
                    .multilineTextAlignment(.center)
                Button(NSLocalizedString("open_settings", comment: "Open settings")) {
                    selectedTab = "settings"
                }
            }
            .padding()
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView(viewModel: ScanningStationViewModel.shared, appSettings: AppSettings(scanDelay: 5, selectedStation: nil))
    }
}
