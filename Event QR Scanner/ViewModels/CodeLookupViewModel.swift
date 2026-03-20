//
//  CodeLookupViewModel.swift
//  Event QR Scanner
//

import Foundation

@MainActor
final class CodeLookupViewModel: ObservableObject {
    @Published var result: VerifyScanResponse?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var debugMessage: String?

    private let apiClient: APIClient

    init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
    }

    func lookup(code: String, eventId: String?, isDebugEnabled: Bool) async {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        isLoading = true
        errorMessage = nil
        debugMessage = nil
        result = nil
        defer { isLoading = false }

        do {
            result = try await apiClient.verifyScan(code: trimmed, eventId: eventId, limit: 10)
        } catch {
            if let apiError = error as? APIError {
                errorMessage = userFriendlyError(apiError)
                if isDebugEnabled {
                    debugMessage = apiError.localizedDescription
                }
            } else {
                errorMessage = NSLocalizedString("scan_error_unknown", comment: "Unknown error")
                if isDebugEnabled {
                    debugMessage = error.localizedDescription
                }
            }
        }
    }

    func clear() {
        result = nil
        errorMessage = nil
        debugMessage = nil
    }

    private func userFriendlyError(_ apiError: APIError) -> String {
        switch apiError {
        case .httpError(let statusCode, let responseText):
            if statusCode == 404, let responseText, responseText.localizedCaseInsensitiveContains("code not found") {
                return NSLocalizedString("code_not_found", comment: "Code not found")
            }
            if statusCode == 401 {
                return NSLocalizedString("scan_error_unauthorized", comment: "Unauthorized")
            }
            if statusCode >= 500 {
                return NSLocalizedString("scan_error_backend", comment: "Backend error")
            }
            if let responseText, !responseText.isEmpty {
                return String(format: NSLocalizedString("lookup_http_error_format", comment: "HTTP error format"), statusCode)
            }
            return String(format: NSLocalizedString("lookup_http_error_format", comment: "HTTP error format"), statusCode)
        case .decodingFailed:
            return NSLocalizedString("scan_error_invalid_response", comment: "Invalid response")
        case .invalidResponse:
            return NSLocalizedString("scan_error_invalid_response", comment: "Invalid response")
        case .invalidURL:
            return NSLocalizedString("scan_error_invalid_url", comment: "Invalid URL")
        }
    }
}
