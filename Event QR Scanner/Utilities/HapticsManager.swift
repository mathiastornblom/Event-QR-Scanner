//
//  HapticsManager.swift
//  Event QR-Scanner
//
//  Created by Mathias Törnblom on 2024-04-13.
//

import Foundation
import CoreHaptics

class HapticsManager {
    static let shared = HapticsManager()
    private var engine: CHHapticEngine?

    init() {
        prepareHaptics()
    }
    
    private func prepareHaptics() {
        do {
            engine = try CHHapticEngine()
            try engine?.start()
        } catch {
            print("Error creating the haptic engine: \(error)")
        }
    }
    
    /// Plays haptic feedback based on the scan result type.
    /// - Parameter type: The type of scan result, either success or failure.
    func playHaptic(type: ScanResultType) {
        guard CHHapticEngine.capabilitiesForHardware().supportsHaptics else {
            print("Haptics not supported on this device.")
            return
        }

        var events = [CHHapticEvent]()

        switch type {
        case .success:
            let event = CHHapticEvent(eventType: .hapticTransient, parameters: [], relativeTime: 0)
            events.append(event)
        case .failure:
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            let event = CHHapticEvent(eventType: .hapticContinuous, parameters: [intensity, sharpness], relativeTime: 0, duration: 1.0)
            events.append(event)
        }

        do {
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine?.makePlayer(with: pattern)
            try player?.start(atTime: 0) // Play immediately
        } catch {
            print("Failed to play haptic feedback: \(error)")
        }
    }
}

