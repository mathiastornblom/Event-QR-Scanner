//
//  APIClient.swift
//  Event QR Scanner
//

import Foundation

final class APIClient {
    static let shared = APIClient(baseURL: URL(string: "http://qrapi.handbollost.se:3001")!)

    private let baseURL: URL
    private let session: URLSession
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let bearerToken: String?
    private let apiKey: String

    init(baseURL: URL) {
        self.baseURL = baseURL

        self.bearerToken = Bundle.main.object(forInfoDictionaryKey: "API_BEARER_TOKEN") as? String

        let plistKey = Bundle.main.object(forInfoDictionaryKey: "API_KEY") as? String
        let resolvedApiKey: String
        if let plistKey, !plistKey.isEmpty {
            resolvedApiKey = plistKey
        } else {
            resolvedApiKey = "usm2026-scanner-key-change-me"
        }
        self.apiKey = resolvedApiKey

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 6
        configuration.timeoutIntervalForResource = 10
        configuration.waitsForConnectivity = true
        configuration.requestCachePolicy = .useProtocolCachePolicy
        configuration.urlCache = URLCache(memoryCapacity: 20 * 1024 * 1024, diskCapacity: 150 * 1024 * 1024)
        configuration.httpAdditionalHeaders = [
            "X-Api-Key": resolvedApiKey,
            "Accept": "application/json"
        ]

        self.session = URLSession(configuration: configuration)
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
        self.encoder = JSONEncoder()
    }

    func fetchEvents(forceRefresh: Bool = false) async throws -> [Event] {
        let request = makeRequest(
            url: baseURL.appendingPathComponent("api/events"),
            cachePolicy: forceRefresh ? .reloadIgnoringLocalCacheData : nil
        )
        return try await perform(request, as: [Event].self)
    }

    func fetchEvent(eventId: String) async throws -> Event {
        let request = makeRequest(url: baseURL.appendingPathComponent("api/events").appendingPathComponent(eventId))
        return try await perform(request, as: Event.self)
    }

    func eventLogoURL(eventId: String) -> URL {
        baseURL
            .appendingPathComponent("api/events")
            .appendingPathComponent(eventId)
            .appendingPathComponent("logo")
    }

    var apiKeyDiagnostics: String {
        if apiKey.isEmpty {
            return "missing"
        }
        return "len \(apiKey.count)"
    }

    func prefetchEventLogo(eventId: String) {
        let url = eventLogoURL(eventId: eventId)
        let request = URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad, timeoutInterval: 6)
        session.dataTask(with: request).resume()
    }

    func fetchCodes(eventId: String, page: Int = 1) async throws -> CodesPageResponse {
        var components = URLComponents(url: baseURL.appendingPathComponent("api/codes"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "eventId", value: eventId),
            URLQueryItem(name: "page", value: String(page))
        ]

        guard let url = components?.url else { throw APIError.invalidURL }
        return try await perform(makeRequest(url: url), as: CodesPageResponse.self)
    }

    func fetchRights(eventId: String) async throws -> [EventRight] {
        var components = URLComponents(url: baseURL.appendingPathComponent("api/rights"), resolvingAgainstBaseURL: false)
        components?.queryItems = [
            URLQueryItem(name: "eventId", value: eventId)
        ]

        guard let url = components?.url else { throw APIError.invalidURL }
        return try await perform(makeRequest(url: url), as: [EventRight].self)
    }

    func verifyScan(code: String, eventId: String? = nil, limit: Int? = nil) async throws -> VerifyScanResponse {
        let encodedCode = code.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? code
        let base = baseURL.appendingPathComponent("api/scan/verify/").appendingPathComponent(encodedCode)

        if eventId != nil || limit != nil {
            var components = URLComponents(url: base, resolvingAgainstBaseURL: false)
            var items: [URLQueryItem] = []
            if let eventId, !eventId.isEmpty {
                items.append(URLQueryItem(name: "eventId", value: eventId))
            }
            if let limit {
                items.append(URLQueryItem(name: "limit", value: String(limit)))
            }
            components?.queryItems = items.isEmpty ? nil : items
            guard let url = components?.url else { throw APIError.invalidURL }
            return try await perform(makeRequest(url: url), as: VerifyScanResponse.self)
        }

        return try await perform(makeRequest(url: base), as: VerifyScanResponse.self)
    }

    func consumeRight(code: String, right: String, eventId: String? = nil, location: String? = nil) async throws -> ConsumeScanResponse {
        let url = baseURL.appendingPathComponent("api/scan")
        let body = try encoder.encode(
            ConsumeScanRequest(
                code: code,
                right: right,
                eventId: eventId,
                scannerDevice: nil,
                location: location
            )
        )
        let request = makeRequest(url: url, method: "POST", body: body)
        // Use performAllowingDenied so that 403 "denied" responses are decoded
        // as ConsumeScanResponse instead of thrown as httpError.
        return try await performAllowingDenied(request, as: ConsumeScanResponse.self)
    }

    func fetchCodeRights(codeId: String) async throws -> [CodeRight] {
        var components = URLComponents(url: baseURL.appendingPathComponent("api/code-rights"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "codeId", value: codeId)]

        guard let url = components?.url else { throw APIError.invalidURL }
        return try await perform(makeRequest(url: url), as: [CodeRight].self)
    }

    func fetchCodeRightsGrid(eventId: String) async throws -> [CodeRightsGridRow] {
        var components = URLComponents(url: baseURL.appendingPathComponent("api/code-rights/grid"), resolvingAgainstBaseURL: false)
        components?.queryItems = [URLQueryItem(name: "eventId", value: eventId)]

        guard let url = components?.url else { throw APIError.invalidURL }
        return try await perform(makeRequest(url: url), as: [CodeRightsGridRow].self)
    }

    private func makeRequest(
        url: URL,
        method: String = "GET",
        body: Data? = nil,
        cachePolicy: URLRequest.CachePolicy? = nil
    ) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let cachePolicy {
            request.cachePolicy = cachePolicy
        }

        if let body {
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
        }

        if let token = bearerToken, !token.isEmpty {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        request.setValue(apiKey, forHTTPHeaderField: "X-Api-Key")

        return request
    }

    private func perform<T: Decodable>(_ request: URLRequest, as type: T.Type) async throws -> T {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let responseText = String(data: data, encoding: .utf8)
            throw APIError.httpError(httpResponse.statusCode, responseText)
        }

        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw APIError.decodingFailed(error)
        }
    }

    /// Like `perform`, but also decodes 403 responses instead of throwing.
    /// Used for the scan/consume endpoint where 403 carries a structured
    /// { status: "denied", reason: "..." } body that must be decoded, not thrown.
    private func performAllowingDenied<T: Decodable>(_ request: URLRequest, as type: T.Type) async throws -> T {
        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if (200...299).contains(httpResponse.statusCode) || httpResponse.statusCode == 403 {
            do {
                return try decoder.decode(T.self, from: data)
            } catch {
                throw APIError.decodingFailed(error)
            }
        }

        let responseText = String(data: data, encoding: .utf8)
        throw APIError.httpError(httpResponse.statusCode, responseText)
    }
}

enum APIError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(Int, String?)
    case decodingFailed(Error)

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Ogiltig URL."
        case .invalidResponse:
            return "Ogiltigt svar från servern."
        case .httpError(let statusCode, let responseText):
            if let responseText, !responseText.isEmpty {
                return "HTTP-fel: \(statusCode). Svar: \(responseText)"
            }
            return "HTTP-fel: \(statusCode)."
        case .decodingFailed(let error):
            return "Kunde inte tolka serverdata: \(error.localizedDescription)"
        }
    }
}
