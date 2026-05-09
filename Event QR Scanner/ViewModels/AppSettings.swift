//
//  AppSettings.swift
//  Event QR-Scanner
//
//  Created by Mathias Törnblom on 2024-04-12.
//

import Foundation
import Observation

@Observable
@MainActor
class AppSettings {
    var scanDelay: Int
    var selectedStation: ScanningStation?
    var selectedEvent: Event?
    var isDebugEnabled: Bool

    init(
        scanDelay: Int,
        selectedStation: ScanningStation?,
        selectedEvent: Event? = nil,
        isDebugEnabled: Bool = false
    ) {
        self.scanDelay = scanDelay
        self.selectedStation = selectedStation
        self.selectedEvent = selectedEvent
        self.isDebugEnabled = isDebugEnabled
        loadFromLocal()
    }

    func saveToLocal() {
        UserDefaults.standard.set(scanDelay, forKey: "scanDelay")
        UserDefaults.standard.set(isDebugEnabled, forKey: "isDebugEnabled")

        if let station = selectedStation,
           let encStation = try? JSONEncoder().encode(station) {
            UserDefaults.standard.set(encStation, forKey: "selectedStation")
        }

        if let event = selectedEvent,
           let encEvent = try? JSONEncoder().encode(event) {
            UserDefaults.standard.set(encEvent, forKey: "selectedEvent")
        }
    }

    func loadFromLocal() {
        scanDelay = UserDefaults.standard.integer(forKey: "scanDelay")
        isDebugEnabled = UserDefaults.standard.bool(forKey: "isDebugEnabled")

        if let data = UserDefaults.standard.data(forKey: "selectedStation"),
           let station = try? JSONDecoder().decode(ScanningStation.self, from: data) {
            selectedStation = station
        }

        if let data = UserDefaults.standard.data(forKey: "selectedEvent"),
           let event = try? JSONDecoder().decode(Event.self, from: data) {
            selectedEvent = event
        }
    }

    func refreshFromSystemSettings() {
        isDebugEnabled = UserDefaults.standard.bool(forKey: "isDebugEnabled")
    }

    func saveToiCloud() {
        // Implement iCloud save logic
    }

    func loadFromiCloud() {
        // Implement iCloud load logic
    }
}
