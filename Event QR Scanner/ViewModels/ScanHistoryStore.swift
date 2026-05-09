//
//  ScanHistoryStore.swift
//  Event QR Scanner
//

import Foundation
import Observation

@Observable
@MainActor
final class ScanHistoryStore {
    static let shared = ScanHistoryStore()

    private(set) var items: [ScanHistoryItem] = []

    private let storageKey = "scanHistory"
    private let maxItems = 200

    init() {
        load()
    }

    func add(_ item: ScanHistoryItem) {
        items.insert(item, at: 0)
        if items.count > maxItems {
            items = Array(items.prefix(maxItems))
        }
        save()
    }

    func clear() {
        items = []
        save()
    }

    func clear(eventName: String?, stationName: String?) {
        let filtered = items.filter { item in
            let matchesEvent = eventName == nil || item.eventName == eventName
            let matchesStation = stationName == nil || item.stationName == stationName
            return !matchesEvent || !matchesStation
        }
        items = filtered
        save()
    }


    private func save() {
        if let data = try? JSONEncoder().encode(items) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let saved = try? JSONDecoder().decode([ScanHistoryItem].self, from: data) else {
            items = []
            return
        }
        items = saved
    }
}
