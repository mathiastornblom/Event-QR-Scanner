//
//  ScanningStationViewModel.swift
//  Event QR-Scanner
//
//  Created by Mathias Törnblom on 2024-04-09.
//

import Foundation
import Observation

@Observable
@MainActor
class ScanningStationViewModel {
    var currentEvent: Event?
    var stations: [ScanningStation] = []
    var selectedStation: ScanningStation?

    // Debug state for right loading.
    var lastRequestedEventId: String?
    var lastFetchStatus: String = "idle"
    var lastFetchError: String?
    var lastFetchedCodeCount: Int = 0
    var lastFetchAt: Date?

    static let shared = ScanningStationViewModel()

    private let apiClient: APIClient

    init(stations: [ScanningStation] = [], apiClient: APIClient = .shared) {
        self.stations = stations
        self.currentEvent = nil
        self.selectedStation = nil
        self.apiClient = apiClient
    }

    /// Legacy name retained to avoid larger UI refactors.
    /// This now loads rights from GET /api/rights?eventId=xxx.
    func fetchStations(for event: Event? = nil) async {
        currentEvent = event
        lastRequestedEventId = event?.id
        lastFetchAt = Date()
        lastFetchError = nil
        lastFetchedCodeCount = 0

        guard let eventId = event?.id, !eventId.isEmpty else {
            lastFetchStatus = "missing_event_id"
            stations = []
            return
        }

        lastFetchStatus = "loading"

        do {
            let rights = try await apiClient.fetchRights(eventId: eventId)
            // Sorting is handled by the view so it can be changed without re-fetching
            stations = rights
                .map { right in
                    ScanningStation(
                        id: right.id,
                        name: right.name,
                        slug: right.slug,
                        validFrom: right.validFrom,
                        validTo: right.validTo
                    )
                }
            lastFetchedCodeCount = stations.count
            lastFetchStatus = "success"
        } catch {
            lastFetchStatus = "failed"
            lastFetchError = error.localizedDescription
            stations = []
        }
    }

    func selectStation(_ station: ScanningStation) {
        selectedStation = station
    }
}
