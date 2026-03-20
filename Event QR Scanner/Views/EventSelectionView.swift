//
//  EventSelectionView.swift
//  Event QR Scanner
//
//  Created by Mathias Törnblom on 2025-04-30.
//  Copyright © 2025 net.tornbloms. All rights reserved.
//

import SwiftUI

struct EventSelectionView: View {
    @ObservedObject var eventsVM: EventsViewModel
    @ObservedObject var appSettings: AppSettings
    @State private var isLoading = false
    @State private var navigate = false

    var body: some View {
        NavigationView {
            Form {
                Section {
                    EventBrandingHeaderView(event: appSettings.selectedEvent, subtitle: NSLocalizedString("select_event", comment: "Select event"))
                }

                Section(NSLocalizedString("select_event", comment: "Select event")) {
                    if eventsVM.isLoading {
                        ProgressView()
                    } else if eventsVM.events.isEmpty {
                        EmptyStateView(
                            systemImageName: "calendar.badge.exclamationmark",
                            title: NSLocalizedString("no_events_found", comment: "No events found"),
                            message: NSLocalizedString("check_selected_event_try_again", comment: "Check selected event and try again"),
                            actionTitle: NSLocalizedString("refresh_events", comment: "Update list of events"),
                            action: {
                                Task {
                                    isLoading = true
                                    await eventsVM.fetchEvents(forceRefresh: true)
                                    isLoading = false
                                }
                            }
                        )
                    } else {
                        ForEach(eventsVM.events, id: \.self) { event in
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
                    if let errorMessage = eventsVM.lastErrorMessage {
                        Text(errorMessage)
                            .font(.footnote)
                            .foregroundColor(.red)
                    }
                    if appSettings.isDebugEnabled, let errorDetail = eventsVM.lastErrorDetail {
                        Text(errorDetail)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    if let fetchedAt = eventsVM.lastFetchAt {
                        Text(String(format: NSLocalizedString("last_updated_format", comment: "Last updated format"), fetchedAt.formatted(date: .numeric, time: .shortened)))
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }

                Button(NSLocalizedString("refresh_events", comment: "Update list of events")) {
                    Task {
                        isLoading = true
                        await eventsVM.fetchEvents(forceRefresh: true)
                        isLoading = false
                    }
                }
            }
            .navigationTitle(NSLocalizedString("select_event", comment: "Select event"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(NSLocalizedString("next", comment: "Next")) {
                        appSettings.selectedStation = nil
                        appSettings.saveToLocal()
                        navigate = true
                    }.disabled(appSettings.selectedEvent == nil)
                }
            }
            .background(
                NavigationLink("", destination: StationSelectionView(
                    stationViewModel: .shared,
                    appSettings: appSettings
                ), isActive: $navigate)
            )
            .onAppear {
                if eventsVM.events.isEmpty {
                    Task {
                        appSettings.refreshFromSystemSettings()
                        await eventsVM.fetchEvents()
                    }
                }
            }
            .onChange(of: appSettings.selectedEvent) { newEvent in
                appSettings.selectedStation = nil
                appSettings.saveToLocal()

                Task {
                    await ScanningStationViewModel.shared.fetchStations(for: newEvent)
                }
            }
        }
    }
}

// MARK: - Previews

struct EventSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        // Create a sample EventsViewModel with mock events
        let sampleVM = EventsViewModel()
        sampleVM.events = [
            Event(id: "1", name: "Sample Event A"),
            Event(id: "2", name: "Sample Event B")
        ]
        // Initialize AppSettings without a selected event
        let sampleSettings = AppSettings(scanDelay: 5, selectedStation: nil, selectedEvent: nil)

        // Return the view for preview
        return EventSelectionView(eventsVM: sampleVM, appSettings: sampleSettings)
    }
}
