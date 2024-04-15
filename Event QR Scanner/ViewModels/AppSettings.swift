//
//  AppSettings.swift
//  Event QR-Scanner
//
//  Created by Mathias Törnblom on 2024-04-12.
//

import Foundation

class AppSettings: ObservableObject {
    @Published var scanDelay: Int
    @Published var selectedStation: ScanningStation?

    init(scanDelay: Int, selectedStation: ScanningStation?) {
        self.scanDelay = scanDelay
        self.selectedStation = selectedStation
    }

    func saveToLocal() {
        UserDefaults.standard.set(scanDelay, forKey: "scanDelay")
        // Encode `selectedStation` and save it to UserDefaults
        if let station = selectedStation {
            if let encoded = try? JSONEncoder().encode(station) {
                UserDefaults.standard.set(encoded, forKey: "selectedStation")
            }
        }
    }

    func loadFromLocal() {
        self.scanDelay = UserDefaults.standard.integer(forKey: "scanDelay")
        // Decode `selectedStation` from UserDefaults
        if let data = UserDefaults.standard.data(forKey: "selectedStation"),
           let station = try? JSONDecoder().decode(ScanningStation.self, from: data) {
            self.selectedStation = station
        }
    }

    // Placeholder methods for iCloud sync - these will need to be implemented based on your iCloud setup
    func saveToiCloud() {
        // Implement iCloud save logic
    }

    func loadFromiCloud() {
        // Implement iCloud load logic
    }
}
