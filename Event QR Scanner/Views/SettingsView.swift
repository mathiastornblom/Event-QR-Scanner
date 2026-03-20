//
//  SettingsView.swift
//  Event QR-Scanner
//
//  Created by Mathias Törnblom on 2024-04-09.
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject var stationViewModel: ScanningStationViewModel
    @ObservedObject var appSettings: AppSettings
    @Binding var selectedTab: String
    @StateObject private var eventsViewModel = EventsViewModel()
    @State private var isLoadingStations = false

    var body: some View {
        NavigationView {
            Form {
                // 1. Skanningsinställningar
                Section(header: Text(NSLocalizedString("scan_settings", comment: ""))) {
                    Stepper(
                        NSLocalizedString("scan_delay_seconds", comment: "") + " \(appSettings.scanDelay)",
                        value: $appSettings.scanDelay,
                        in: 0...10
                    )
                }

                // 2. Välj event
                Section(header: Text(NSLocalizedString("select_event", comment: ""))) {
                    if eventsViewModel.isLoading {
                        ProgressView()
                    } else if eventsViewModel.events.isEmpty {
                        Text(NSLocalizedString("no_events_found", comment: "No events found"))
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(eventsViewModel.events, id: \.self) { event in
                            Button {
                                appSettings.selectedEvent = event
                                appSettings.selectedStation = nil
                                appSettings.saveToLocal()
                            } label: {
                                EventCard(
                                    event: event,
                                    isSelected: event == appSettings.selectedEvent
                                )
                            }
                            .buttonStyle(.plain)
                            .listRowInsets(EdgeInsets())
                            .padding(.vertical, 4)
                        }
                    }
                    if let errorMessage = eventsViewModel.lastErrorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                    }
                    if appSettings.isDebugEnabled, let errorDetail = eventsViewModel.lastErrorDetail {
                        Text(errorDetail)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    if let fetchedAt = eventsViewModel.lastFetchAt {
                        Text(String(format: NSLocalizedString("last_updated_format", comment: "Last updated format"), fetchedAt.formatted(date: .numeric, time: .shortened)))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Button(NSLocalizedString("refresh_events", comment: "")) {
                        Task {
                            await refreshEventsAndValidateSelection()
                        }
                    }
                }

                // 3. Välj station för scanning
                Section(header: Text(NSLocalizedString("select_station", comment: "Select station"))) {
                    if appSettings.selectedEvent == nil {
                        Text(NSLocalizedString("select_event_first", comment: "Select event first"))
                            .foregroundColor(.secondary)
                    } else if isLoadingStations {
                        ProgressView()
                    } else if stationViewModel.stations.isEmpty {
                        Text(NSLocalizedString("no_stations_found", comment: "No stations found"))
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(stationViewModel.stations, id: \.self) { station in
                            Button {
                                appSettings.selectedStation = station
                                appSettings.saveToLocal()
                            } label: {
                                StationCard(
                                    station: station,
                                    isSelected: station == appSettings.selectedStation
                                )
                            }
                            .buttonStyle(.plain)
                            .listRowInsets(EdgeInsets())
                            .padding(.vertical, 4)
                        }
                    }
                    Button(NSLocalizedString("refresh_stations", comment: "")) {
                        Task {
                            isLoadingStations = true
                            await stationViewModel.fetchStations(for: appSettings.selectedEvent)
                            isLoadingStations = false
                        }
                    }
                }
            }
            .navigationBarTitle(NSLocalizedString("settings", comment: ""), displayMode: .inline)
            .navigationBarItems(trailing: Button(NSLocalizedString("done", comment: "")) {
                appSettings.saveToLocal()
                selectedTab = "scan"
            })
            .onAppear {
                Task {
                    appSettings.refreshFromSystemSettings()
                    if eventsViewModel.events.isEmpty {
                        await refreshEventsAndValidateSelection()
                    }
                    if stationViewModel.stations.isEmpty {
                        isLoadingStations = true
                        await stationViewModel.fetchStations(for: appSettings.selectedEvent)
                        isLoadingStations = false
                    }
                }
            }
            .onChange(of: appSettings.selectedEvent) { newEvent in
                Task {
                    // Clear selected station, then reload stations for new event
                    appSettings.selectedStation = nil
                    isLoadingStations = true
                    await stationViewModel.fetchStations(for: newEvent)
                    isLoadingStations = false
                }
            }
        }
    }

    @MainActor
    private func refreshEventsAndValidateSelection() async {
        await eventsViewModel.fetchEvents(forceRefresh: true)

        if eventsViewModel.lastErrorMessage == nil {
            if let selectedEvent = appSettings.selectedEvent,
               !eventsViewModel.events.contains(selectedEvent) {
                appSettings.selectedEvent = nil
                appSettings.selectedStation = nil
            }
        }

        appSettings.saveToLocal()
    }
}


struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        let stationVM = ScanningStationViewModel.shared
        let settings = AppSettings(scanDelay: 5, selectedStation: nil, selectedEvent: nil)
        return SettingsView(stationViewModel: stationVM, appSettings: settings, selectedTab: .constant("settings"))
    }
}
