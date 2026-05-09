//
//  QRCodeProcessingViewModel.swift
//  Event QR-Scanner
//
//  Created by Mathias Törnblom on 2024-04-09.
//

import Foundation
import Observation

@Observable
@MainActor
class QRCodeProcessingViewModel {
    var lastScanResult: ScanResult?
    var isReadyToScanAgain = true

    private let appSettings: AppSettings
    private let apiClient: APIClient
    private let historyStore: ScanHistoryStore
    private let soundManager = SoundManager.shared
    private let hapticManager = HapticsManager.shared

    private var lastProcessedCode: String?
    private var lastProcessedAt: Date?

    init(appSettings: AppSettings, apiClient: APIClient = .shared, historyStore: ScanHistoryStore) {
        self.appSettings = appSettings
        self.apiClient = apiClient
        self.historyStore = historyStore
    }

    func processScannedCode(_ scannedCode: String, selectedRight: ScanningStation?) async {
        guard isReadyToScanAgain else { return }

        if shouldSkipDuplicate(scannedCode) {
            return
        }

        isReadyToScanAgain = false
        lastScanResult = nil

        let result = await performVerifyAndConsume(scannedCode: scannedCode, selectedRight: selectedRight)
        lastScanResult = result
        addHistoryItem(from: result)

        if result.isValid {
            soundManager.playSound(type: .success)
            hapticManager.playHaptic(type: .success)
        } else if result.isTechnicalError {
            soundManager.playSound(type: .technical)
            hapticManager.playHaptic(type: .technical)
        } else {
            soundManager.playSound(type: .failure)
            hapticManager.playHaptic(type: .failure)
        }

        let delay = appSettings.scanDelay
        if delay > 0 {
            try? await Task.sleep(nanoseconds: UInt64(delay) * 1_000_000_000)
        }

        isReadyToScanAgain = true
    }

    private func addHistoryItem(from result: ScanResult) {
        let stationName = appSettings.selectedStation?.name ?? NSLocalizedString("none_selected", comment: "No selection")
        let eventName = appSettings.selectedEvent?.name ?? NSLocalizedString("no_event_selected", comment: "No event selected")
        let item = ScanHistoryItem(
            code: result.scannedData,
            person: result.holderName,
            isApproved: result.isValid,
            timestamp: Date(),
            stationName: stationName,
            eventName: eventName
        )
        historyStore.add(item)
    }

    private func shouldSkipDuplicate(_ code: String) -> Bool {
        let now = Date()
        defer {
            lastProcessedCode = code
            lastProcessedAt = now
        }

        guard let previousCode = lastProcessedCode,
              let previousDate = lastProcessedAt else {
            return false
        }

        return previousCode == code && now.timeIntervalSince(previousDate) < 0.8
    }

    private func performVerifyAndConsume(scannedCode: String, selectedRight: ScanningStation?) async -> ScanResult {
        do {
            let verification = try await apiClient.verifyScan(
                code: scannedCode,
                eventId: appSettings.selectedEvent?.id,
                limit: 10
            )

            guard let selectedRight else {
                return ScanResult.denied(
                    code: verification.code,
                    person: verification.person.name,
                    statusTitle: NSLocalizedString("scan_denied_title", comment: "Scan denied title"),
                    detailMessage: NSLocalizedString("no_station_selected", comment: "No station selected"),
                    remaining: nil,
                    club: verification.club,
                    team: verification.team,
                    role: verification.role ?? verification.person.role,
                    rights: verification.rights
                )
            }

            let rightIdentifier = selectedRight.slug ?? slugify(selectedRight.name)
            let consumption = try await apiClient.consumeRight(
                code: scannedCode,
                right: rightIdentifier,
                eventId: appSettings.selectedEvent?.id,
                location: selectedRight.name
            )

            if consumption.status == "ok" {
                return ScanResult.success(
                    code: verification.code,
                    person: consumption.personName ?? verification.person.name,
                    statusTitle: NSLocalizedString("scan_ok_title", comment: "Scan ok title"),
                    detailMessage: NSLocalizedString("scan_ok_message", comment: "Scan ok message"),
                    consumedRight: consumption.rightName ?? selectedRight.name,
                    remaining: consumption.remaining,
                    club: verification.club,
                    team: verification.team,
                    role: verification.role ?? verification.person.role,
                    rights: verification.rights
                )
            }

            let deniedReason = readableDeniedReason(consumption.reason)
            return ScanResult.denied(
                code: verification.code,
                person: verification.person.name,
                statusTitle: NSLocalizedString("scan_denied_title", comment: "Scan denied title"),
                detailMessage: deniedReason,
                remaining: consumption.remaining,
                club: verification.club,
                team: verification.team,
                role: verification.role,
                rights: verification.rights
            )
        } catch {
            let feedback = userFriendlyErrorFeedback(from: error)
            if feedback.isTechnicalError {
                return ScanResult.error(
                    code: scannedCode,
                    person: NSLocalizedString("unknown_person", comment: "Unknown person"),
                    statusTitle: feedback.statusTitle,
                    detailMessage: feedback.detailMessage,
                    debugMessage: feedback.debugMessage
                )
            }
            return ScanResult.denied(
                code: scannedCode,
                person: NSLocalizedString("unknown_person", comment: "Unknown person"),
                statusTitle: feedback.statusTitle,
                detailMessage: feedback.detailMessage,
                remaining: nil,
                club: nil,
                team: nil,
                role: nil,
                rights: []
            )
        }
    }

    private func readableDeniedReason(_ reason: String?) -> String {
        switch reason {
        case "no_remaining":
            return NSLocalizedString("denied_no_remaining", comment: "Denied no quota")
        case "not_yet_valid":
            return NSLocalizedString("denied_not_yet_valid", comment: "Denied not yet valid")
        case "expired":
            return NSLocalizedString("denied_expired", comment: "Denied expired")
        case "outside_time_window":
            return NSLocalizedString("denied_outside_time_window", comment: "Denied outside time window")
        case "code_not_found":
            return NSLocalizedString("denied_code_not_found", comment: "Denied code not found")
        case "right_not_found", "no_right_assigned":
            return NSLocalizedString("denied_no_right_assigned", comment: "Denied no right assigned")
        case .some(let value):
            return String(format: NSLocalizedString("denied_reason_format", comment: "Denied reason format"), value)
        case .none:
            return NSLocalizedString("denied", comment: "Denied generic")
        }
    }

    private func userFriendlyErrorFeedback(from error: Error) -> (statusTitle: String, detailMessage: String, debugMessage: String?, isTechnicalError: Bool) {
        let statusTitle = NSLocalizedString("scan_error_title", comment: "Scan error title")

        if let urlError = error as? URLError {
            return (
                statusTitle,
                NSLocalizedString("scan_error_network", comment: "Network error"),
                urlError.localizedDescription,
                true
            )
        }

        guard let apiError = error as? APIError else {
            return (
                statusTitle,
                NSLocalizedString("scan_error_unknown", comment: "Unknown error"),
                error.localizedDescription,
                true
            )
        }

        switch apiError {
        case .httpError(let statusCode, let responseText):
            if statusCode == 401 {
                return (
                    statusTitle,
                    NSLocalizedString("scan_error_unauthorized", comment: "Unauthorized"),
                    responseText,
                    true
                )
            }
            if statusCode == 404, let responseText, responseText.localizedCaseInsensitiveContains("code not found") {
                return (
                    NSLocalizedString("scan_denied_title", comment: "Scan denied title"),
                    NSLocalizedString("code_not_found", comment: "Code not found"),
                    responseText,
                    false
                )
            }
            if statusCode >= 500 {
                return (
                    statusTitle,
                    NSLocalizedString("scan_error_backend", comment: "Backend error"),
                    responseText,
                    true
                )
            }
            return (
                statusTitle,
                NSLocalizedString("scan_error_backend", comment: "Backend error"),
                responseText,
                true
            )
        case .decodingFailed(let decodeError):
            return (
                statusTitle,
                NSLocalizedString("scan_error_invalid_response", comment: "Invalid response"),
                decodeError.localizedDescription,
                true
            )
        case .invalidResponse:
            return (
                statusTitle,
                NSLocalizedString("scan_error_invalid_response", comment: "Invalid response"),
                nil,
                true
            )
        case .invalidURL:
            return (
                statusTitle,
                NSLocalizedString("scan_error_invalid_url", comment: "Invalid URL"),
                nil,
                true
            )
        }
    }

    private func slugify(_ value: String) -> String {
        value
            .lowercased()
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: " ", with: "-")
            .replacingOccurrences(of: "_", with: "-")
    }

    func resetForNewScan() {
        isReadyToScanAgain = true
        lastScanResult = nil
    }
}
