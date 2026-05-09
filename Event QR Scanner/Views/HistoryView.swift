//
//  HistoryView.swift
//  Event QR Scanner
//

import SwiftUI

struct HistoryView: View {
    var historyStore: ScanHistoryStore
    var appSettings: AppSettings
    @State private var showingClearConfirmation = false
    @State private var showingClearAllConfirmation = false

    var body: some View {
        NavigationView {
            Group {
                if appSettings.selectedEvent == nil {
                    EmptyStateView(
                        systemImageName: "calendar.badge.exclamationmark",
                        title: NSLocalizedString("select_event_first", comment: "Select event first"),
                        message: NSLocalizedString("history_requires_event", comment: "History requires event")
                    )
                } else if filteredItems.isEmpty {
                    EmptyStateView(
                        systemImageName: "clock",
                        title: NSLocalizedString("no_history", comment: "No history"),
                        message: NSLocalizedString("history_empty_message", comment: "History empty message")
                    )
                } else {
                    ScrollView {
                        LazyVStack(spacing: 10) {
                            ForEach(filteredItems) { item in
                                HistoryCard(item: item)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.top, 8)
                    }
                }
            }
            .navigationTitle(NSLocalizedString("history", comment: "History"))
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(role: .destructive) {
                        showingClearConfirmation = true
                    } label: {
                        Text(clearButtonTitle)
                    }
                    .disabled(filteredItems.isEmpty)
                }
            }
            .alert(clearConfirmationTitle, isPresented: $showingClearConfirmation) {
                Button(NSLocalizedString("cancel", comment: "Cancel"), role: .cancel) {}
                Button(clearButtonTitle, role: .destructive) {
                    historyStore.clear(eventName: appSettings.selectedEvent?.name, stationName: appSettings.selectedStation?.name)
                }
            } message: {
                Text(clearConfirmationMessage)
            }
            .alert(NSLocalizedString("confirm_clear_all_title", comment: "Confirm clear all title"), isPresented: $showingClearAllConfirmation) {
                Button(NSLocalizedString("cancel", comment: "Cancel"), role: .cancel) {}
                Button(NSLocalizedString("clear_all", comment: "Clear all"), role: .destructive) {
                    historyStore.clear()
                }
            } message: {
                Text(NSLocalizedString("confirm_clear_all_message", comment: "Confirm clear all message"))
            }
        }
        .onAppear {
            if UserDefaults.standard.bool(forKey: "clearHistoryRequested") {
                UserDefaults.standard.set(false, forKey: "clearHistoryRequested")
                showingClearAllConfirmation = true
            }
        }
    }

    private var filteredItems: [ScanHistoryItem] {
        let eventName = appSettings.selectedEvent?.name
        let stationName = appSettings.selectedStation?.name

        return historyStore.items.filter { item in
            let matchesEvent = eventName == nil || item.eventName == eventName
            let matchesStation = stationName == nil || item.stationName == stationName
            return matchesEvent && matchesStation
        }
    }

    private var clearButtonTitle: String {
        if appSettings.selectedStation != nil {
            return NSLocalizedString("clear_station", comment: "Clear station history")
        }
        if appSettings.selectedEvent != nil {
            return NSLocalizedString("clear_event", comment: "Clear event history")
        }
        return NSLocalizedString("clear", comment: "Clear")
    }

    private var clearConfirmationTitle: String {
        NSLocalizedString("confirm_clear_title", comment: "Confirm clear title")
    }

    private var clearConfirmationMessage: String {
        if appSettings.selectedStation != nil {
            return NSLocalizedString("confirm_clear_station_message", comment: "Confirm clear station message")
        }
        return NSLocalizedString("confirm_clear_event_message", comment: "Confirm clear event message")
    }
}

private struct HistoryCard: View {
    let item: ScanHistoryItem

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: item.isApproved ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(item.isApproved ? .green : .red)
                .font(.title2)

            VStack(alignment: .leading, spacing: 4) {
                Text(item.code)
                    .font(.headline)
                Text(item.person)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(item.stationName)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(item.eventName)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(item.timestamp.formatted(date: .numeric, time: .shortened))
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }
}
