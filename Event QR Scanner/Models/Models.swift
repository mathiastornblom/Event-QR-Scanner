//
//  Models.swift
//  Event QR-Scanner
//
//  Created by Mathias Törnblom on 2024-04-08.
//

import Foundation

enum ScanResultType {
    case success
    case failure
    case technical
}

/// Represents a selectable scan right in the UI.
struct ScanningStation: Hashable, Identifiable, Codable {
    let id: String
    let name: String
    let slug: String?
    let validFrom: String?
    let validTo: String?

    init(id: String, name: String, slug: String? = nil, validFrom: String? = nil, validTo: String? = nil) {
        self.id = id
        self.name = name
        self.slug = slug
        self.validFrom = validFrom
        self.validTo = validTo
    }
}

struct Event: Identifiable, Codable, Equatable, Hashable {
    let id: String
    let name: String
    let slug: String?
    let startDate: String?
    let endDate: String?
    let active: Bool?
    let primaryColor: String?
    let secondaryColor: String?
    let accentColor: String?
    let backgroundColor: String?
    let textColor: String?
    let logoUrl: String?

    init(
        id: String,
        name: String,
        slug: String? = nil,
        startDate: String? = nil,
        endDate: String? = nil,
        active: Bool? = nil,
        primaryColor: String? = nil,
        secondaryColor: String? = nil,
        accentColor: String? = nil,
        backgroundColor: String? = nil,
        textColor: String? = nil,
        logoUrl: String? = nil
    ) {
        self.id = id
        self.name = name
        self.slug = slug
        self.startDate = startDate
        self.endDate = endDate
        self.active = active
        self.primaryColor = primaryColor
        self.secondaryColor = secondaryColor
        self.accentColor = accentColor
        self.backgroundColor = backgroundColor
        self.textColor = textColor
        self.logoUrl = logoUrl
    }
}

struct EventRight: Identifiable, Codable, Hashable {
    let id: String
    let name: String
    let slug: String?
    let description: String?
    let validFrom: String?
    let validTo: String?
}

struct PersonSummary: Codable, Hashable {
    let name: String
}

struct EventCode: Identifiable, Codable, Hashable {
    let id: String
    let code: String
    let person: PersonSummary?
    let club: String?
    let team: String?
    let role: String?
}

struct CodesPageResponse: Codable {
    let data: [EventCode]
    let total: Int
    let page: Int
}

struct CodeRightUsage: Codable, Hashable {
    let timestamp: Date
    let station: String?
    let by: String?

    enum CodingKeys: String, CodingKey {
        case timestamp
        case station
        case by
    }
}

struct CodeRight: Codable, Hashable {
    let name: String
    let remaining: Int?
    let total: Int?
    let used: Int?
    let unlimited: Bool
    let slug: String?
    let uses: [CodeRightUsage]?

    enum CodingKeys: String, CodingKey {
        case name
        case remaining
        case total
        case used
        case unlimited
        case slug
        case uses
    }

    init(name: String, remaining: Int?, total: Int?, used: Int?, unlimited: Bool, slug: String?, uses: [CodeRightUsage]?) {
        self.name = name
        self.remaining = remaining
        self.total = total
        self.used = used
        self.unlimited = unlimited
        self.slug = slug
        self.uses = uses
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let name = (try? container.decode(String.self, forKey: .name)) ?? "Unknown"

        let remaining = container.decodeFlexibleInt(forKey: .remaining)
        let total = container.decodeFlexibleInt(forKey: .total)
        let used = container.decodeFlexibleInt(forKey: .used)
        let unlimited = (try? container.decode(Bool.self, forKey: .unlimited)) ?? (remaining == nil)
        let slug = try? container.decode(String.self, forKey: .slug)
        let uses = try? container.decode([CodeRightUsage].self, forKey: .uses)

        self.init(name: name, remaining: remaining, total: total, used: used, unlimited: unlimited, slug: slug, uses: uses)
    }
}

struct VerifyPerson: Codable, Hashable {
    let name: String
    let role: String?
}

struct VerifyScanResponse: Codable {
    let code: String
    let event: String?
    let eventId: String?
    let person: VerifyPerson
    let club: String?
    let team: String?
    let role: String?
    let rights: [CodeRight]

    enum CodingKeys: String, CodingKey {
        case code
        case event
        case eventId
        case person
        case club
        case team
        case role
        case rights
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        code = try container.decode(String.self, forKey: .code)
        event = try? container.decode(String.self, forKey: .event)
        eventId = try? container.decode(String.self, forKey: .eventId)
        club = try? container.decode(String.self, forKey: .club)
        team = try? container.decode(String.self, forKey: .team)

        if let decodedPerson = try? container.decode(VerifyPerson.self, forKey: .person) {
            person = decodedPerson
        } else if let personName = try? container.decode(String.self, forKey: .person) {
            person = VerifyPerson(name: personName, role: nil)
        } else {
            person = VerifyPerson(name: "Okänd", role: nil)
        }

        role = (try? container.decode(String.self, forKey: .role)) ?? person.role
        rights = (try? container.decode([CodeRight].self, forKey: .rights)) ?? []
    }
}

struct ConsumeScanRequest: Codable {
    let code: String
    let right: String
    let eventId: String?
    let scannerDevice: String?
    let location: String?

    enum CodingKeys: String, CodingKey {
        case code
        case right
        case eventId = "event_id"
        case scannerDevice = "scanner_device"
        case location
    }
}

struct ConsumeScanResponse: Decodable {
    let status: String
    let reason: String?
    let remaining: Int?
    let used: Int?
    let personName: String?
    let personRole: String?
    let rightName: String?
    let rightSlug: String?

    private struct ResponsePerson: Codable {
        let id: String?
        let name: String
        let role: String?
    }

    private struct ResponseRight: Codable {
        let id: String?
        let name: String
        let slug: String?
    }

    enum CodingKeys: String, CodingKey {
        case status
        case reason
        case remaining
        case used
        case person
        case right
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        status = (try? container.decode(String.self, forKey: .status)) ?? "unknown"
        reason = try? container.decode(String.self, forKey: .reason)
        remaining = container.decodeFlexibleInt(forKey: .remaining)
        used = container.decodeFlexibleInt(forKey: .used)

        if let personObject = try? container.decode(ResponsePerson.self, forKey: .person) {
            personName = personObject.name
            personRole = personObject.role
        } else if let personString = try? container.decode(String.self, forKey: .person) {
            personName = personString
            personRole = nil
        } else {
            personName = nil
            personRole = nil
        }

        if let rightObject = try? container.decode(ResponseRight.self, forKey: .right) {
            rightName = rightObject.name
            rightSlug = rightObject.slug
        } else if let rightString = try? container.decode(String.self, forKey: .right) {
            rightName = rightString
            rightSlug = nil
        } else {
            rightName = nil
            rightSlug = nil
        }
    }
}

struct CodeRightsGridRow: Codable, Hashable {
    let data: [String: String]

    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        data = try container.decode([String: String].self)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(data)
    }
}

/// UI model used by the scanner view.
struct ScanHistoryItem: Identifiable, Codable, Hashable {
    let id: UUID
    let code: String
    let person: String
    let isApproved: Bool
    let timestamp: Date
    let stationName: String
    let eventName: String

    init(code: String, person: String, isApproved: Bool, timestamp: Date, stationName: String, eventName: String) {
        self.id = UUID()
        self.code = code
        self.person = person
        self.isApproved = isApproved
        self.timestamp = timestamp
        self.stationName = stationName
        self.eventName = eventName
    }
}

struct ScanResult: Codable, Hashable {
    let isValid: Bool
    let isTechnicalError: Bool
    let holderName: String
    let scannedData: String
    let statusTitle: String
    let detailMessage: String?
    let debugMessage: String?
    let scansLeft: Int
    let showRemaining: Bool
    let consumedRight: String?
    let club: String?
    let team: String?
    let role: String?
    let rights: [CodeRight]

    static func success(
        code: String,
        person: String,
        statusTitle: String,
        detailMessage: String?,
        consumedRight: String?,
        remaining: Int?,
        club: String?,
        team: String?,
        role: String?,
        rights: [CodeRight]
    ) -> ScanResult {
        ScanResult(
            isValid: true,
            isTechnicalError: false,
            holderName: person,
            scannedData: code,
            statusTitle: statusTitle,
            detailMessage: detailMessage,
            debugMessage: nil,
            scansLeft: remaining ?? rights.first?.remaining ?? 0,
            showRemaining: true,
            consumedRight: consumedRight,
            club: club,
            team: team,
            role: role,
            rights: rights
        )
    }

    static func denied(
        code: String,
        person: String,
        statusTitle: String,
        detailMessage: String?,
        remaining: Int?,
        club: String?,
        team: String?,
        role: String?,
        rights: [CodeRight]
    ) -> ScanResult {
        ScanResult(
            isValid: false,
            isTechnicalError: false,
            holderName: person,
            scannedData: code,
            statusTitle: statusTitle,
            detailMessage: detailMessage,
            debugMessage: nil,
            scansLeft: remaining ?? rights.first?.remaining ?? 0,
            showRemaining: true,
            consumedRight: nil,
            club: club,
            team: team,
            role: role,
            rights: rights
        )
    }

    static func error(
        code: String,
        person: String,
        statusTitle: String,
        detailMessage: String?,
        debugMessage: String?
    ) -> ScanResult {
        ScanResult(
            isValid: false,
            isTechnicalError: true,
            holderName: person,
            scannedData: code,
            statusTitle: statusTitle,
            detailMessage: detailMessage,
            debugMessage: debugMessage,
            scansLeft: 0,
            showRemaining: false,
            consumedRight: nil,
            club: nil,
            team: nil,
            role: nil,
            rights: []
        )
    }
}

private extension KeyedDecodingContainer {
    func decodeFlexibleInt(forKey key: Key) -> Int? {
        if let intValue = try? decode(Int.self, forKey: key) {
            return intValue
        }

        if let stringValue = try? decode(String.self, forKey: key),
           let intValue = Int(stringValue) {
            return intValue
        }

        return nil
    }
}
