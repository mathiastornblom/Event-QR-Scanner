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
    @Environment(\.dismiss) private var dismiss
    @State private var navigateToMain = false
    @State private var isLoading = false

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                EventBrandingHeaderView(event: appSettings.selectedEvent, subtitle: NSLocalizedString("select_station", comment: "Select station"))
                    .padding([.horizontal, .top])

                Group {
                    if isLoading {
                        ProgressView(NSLocalizedString("loading_stations", comment: "Loading stations"))
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if stationViewModel.stations.isEmpty {
                        let secondaryMessage = stationViewModel.lastFetchError.map {
                            appSettings.isDebugEnabled
                                ? String(format: NSLocalizedString("stations_fetch_failed_format", comment: "Stations fetch failed"), $0)
                                : NSLocalizedString("stations_fetch_failed", comment: "Stations fetch failed")
                        }
                        EmptyStateView(
                            systemImageName: "qrcode",
                            title: NSLocalizedString("no_stations_found", comment: "No stations found"),
                            message: NSLocalizedString("check_selected_event_try_again", comment: "Check selected event and try again"),
                            secondaryMessage: secondaryMessage,
                            actionTitle: NSLocalizedString("refresh_stations", comment: "Refresh stations"),
                            secondaryActionTitle: NSLocalizedString("change_event", comment: "Change event"),
                            action: {
                                Task {
                                    await reloadCodes()
                                }
                            },
                            secondaryAction: {
                                dismiss()
                            }
                        )
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 10) {
                                ForEach(stationViewModel.stations, id: \.id) { station in
                                    Button(action: {
                                        appSettings.selectedStation = station
                                        appSettings.saveToLocal()
                                        navigateToMain = true
                                    }) {
                                        StationCard(
                                            station: station,
                                            isSelected: station == appSettings.selectedStation
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 4)
                            .background(
                                NavigationLink("", destination: MainTabView(viewModel: stationViewModel, appSettings: appSettings), isActive: $navigateToMain)
                            )
                        }
                        lastUpdatedView
                    }
                }

                if appSettings.isDebugEnabled {
                    debugPanel
                }
            }
            .navigationTitle(NSLocalizedString("select_station", comment: "Select station"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        Task {
                            await reloadCodes()
                        }
                    }) {
                        if isLoading {
                            ProgressView()
                        } else {
                            Image(systemName: "arrow.clockwise")
                                .accessibilityLabel(NSLocalizedString("refresh", comment: "Button label for refreshing the list"))
                        }
                    }
                }
            }
        }
        .onAppear {
            Task {
                appSettings.refreshFromSystemSettings()
                await reloadCodes()
            }
        }
    }

    private var debugPanel: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(NSLocalizedString("debug", comment: "Debug section title"))
                .font(.caption)
                .fontWeight(.bold)
            Text(String(format: NSLocalizedString("debug_selected_event_name_format", comment: "Debug selected event name"), appSettings.selectedEvent?.name ?? "nil"))
            Text(String(format: NSLocalizedString("debug_selected_event_id_format", comment: "Debug selected event id"), appSettings.selectedEvent?.id ?? "nil"))
            Text(String(format: NSLocalizedString("debug_requested_event_id_format", comment: "Debug requested event id"), stationViewModel.lastRequestedEventId ?? "nil"))
            Text(String(format: NSLocalizedString("debug_fetch_status_format", comment: "Debug fetch status"), stationViewModel.lastFetchStatus))
            Text(String(format: NSLocalizedString("debug_stations_loaded_format", comment: "Debug stations loaded"), stationViewModel.lastFetchedCodeCount))
            Text(String(format: NSLocalizedString("debug_visible_rows_format", comment: "Debug visible rows"), stationViewModel.stations.count))
            Text(String(format: NSLocalizedString("debug_api_key_status_format", comment: "Debug API key status"), APIClient.shared.apiKeyDiagnostics))
            if let error = stationViewModel.lastFetchError {
                Text(String(format: NSLocalizedString("debug_last_error_format", comment: "Debug last error"), error))
                    .foregroundColor(.red)
            }
            if let fetchedAt = stationViewModel.lastFetchAt {
                Text(String(format: NSLocalizedString("debug_last_fetch_format", comment: "Debug last fetch"), fetchedAt.formatted(date: .omitted, time: .standard)))
            }
        }
        .font(.caption2)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(UIColor.secondarySystemBackground))
    }

    private var lastUpdatedView: some View {
        Group {
            if let fetchedAt = stationViewModel.lastFetchAt {
                Text(String(format: NSLocalizedString("last_updated_format", comment: "Last updated format"), fetchedAt.formatted(date: .numeric, time: .shortened)))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .padding(.top, 6)
            }
        }
    }

    @MainActor
    private func reloadCodes() async {
        isLoading = true
        await stationViewModel.fetchStations(for: appSettings.selectedEvent)
        isLoading = false
    }
}

struct StationSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        let mockData = ScanningStationViewModel.shared
        let settings = AppSettings(scanDelay: 5, selectedStation: nil)
        mockData.stations = [
            ScanningStation(id: "1", name: "USM26-0001 - Anna Svensson"),
            ScanningStation(id: "2", name: "USM26-0002 - Kalle Karlsson")
        ]
        return StationSelectionView(stationViewModel: mockData, appSettings: settings)
    }
}
