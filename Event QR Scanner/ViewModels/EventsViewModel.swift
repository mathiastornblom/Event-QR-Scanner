//
//  EventsViewModel.swift
//  Event QR Scanner
//
//  Created by Mathias Törnblom on 2025-04-30.
//  Copyright © 2025 net.tornbloms. All rights reserved.
//

import Foundation

@MainActor
class EventsViewModel: ObservableObject {
    @Published var events: [Event] = []
    @Published var isLoading = false
    @Published var lastErrorMessage: String?
    @Published var lastErrorDetail: String?
    @Published var lastFetchAt: Date?

    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func fetchEvents(forceRefresh: Bool = false) async {
        isLoading = true
        defer { isLoading = false }

        do {
            events = try await apiClient.fetchEvents(forceRefresh: forceRefresh)
            lastErrorMessage = nil
            lastErrorDetail = nil
            lastFetchAt = Date()
            for event in events {
                apiClient.prefetchEventLogo(eventId: event.id)
            }
        } catch {
            print("Failed to fetch events:", error)
            lastErrorMessage = NSLocalizedString("events_fetch_failed", comment: "Events fetch failed")
            lastErrorDetail = error.localizedDescription
            lastFetchAt = Date()
            events = []
        }
    }
}
