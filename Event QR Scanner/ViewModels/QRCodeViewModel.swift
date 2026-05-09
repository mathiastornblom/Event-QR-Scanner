//
//  QRCodeViewModel.swift
//  Event QR-Scanner
//
//  Created by Mathias Törnblom on 2024-04-08.
//

import Foundation
import Observation

@Observable
@MainActor
class QRCodeViewModel {
    var lastScanResult: ScanResult?

    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    /// Legacy helper retained for compatibility with existing previews/tests.
    func validateQRCode(_ code: String, forEvent event: String, atScanStation scanStation: String) async {
        do {
            let verification = try await apiClient.verifyScan(code: code, eventId: event, limit: 10)
            lastScanResult = ScanResult.success(
                code: verification.code,
                person: verification.person.name,
                statusTitle: NSLocalizedString("scan_ok_title", comment: "Scan ok title"),
                detailMessage: "Verifierad",
                consumedRight: nil,
                remaining: verification.rights.first?.remaining,
                club: verification.club,
                team: verification.team,
                role: verification.role ?? verification.person.role,
                rights: verification.rights
            )
        } catch {
            lastScanResult = ScanResult.error(
                code: code,
                person: NSLocalizedString("unknown_person", comment: "Unknown person"),
                statusTitle: NSLocalizedString("scan_error_title", comment: "Scan error title"),
                detailMessage: NSLocalizedString("scan_error_unknown", comment: "Unknown error"),
                debugMessage: error.localizedDescription
            )
        }
    }
}
