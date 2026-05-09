//
//  EventsViewModel.swift
//  Event QR Scanner
//
//  Created by Mathias Törnblom on 2025-04-30.
//  Copyright © 2025 net.tornbloms. All rights reserved.
//

import Foundation
import Observation

@Observable
@MainActor
class EventsViewModel {
    var events: [Event] = []
    var isLoading = false
    var lastErrorMessage: String?
    var lastErrorDetail: String?
    var lastFetchAt: Date?

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
