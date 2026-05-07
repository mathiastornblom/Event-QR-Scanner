//
//  CardViews.swift
//  Event QR Scanner
//

import SwiftUI

struct EventCard: View {
    let event: Event
    let isSelected: Bool

    var body: some View {
        HStack(spacing: 12) {
            AsyncImage(url: APIClient.shared.eventLogoURL(eventId: event.id)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .scaledToFit()
                case .failure:
                    fallbackLogo
                case .empty:
                    ProgressView()
                @unknown default:
                    fallbackLogo
                }
            }
            .frame(width: 44, height: 44)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(event.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                if let dateText = formatDateRange(start: event.startDate, end: event.endDate) {
                    Text(dateText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isSelected ? Color.green.opacity(0.6) : Color.clear, lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
        .accessibilityLabel(event.name)
        .accessibilityValue(eventDateAccessibility)
    }

    private var eventDateAccessibility: String {
        guard let dateText = formatDateRange(start: event.startDate, end: event.endDate) else {
            return NSLocalizedString("no_date_info", comment: "No date info")
        }
        return String(format: NSLocalizedString("event_date_format", comment: "Event date format"), dateText)
    }

    private var fallbackLogo: some View {
        Image(systemName: "ticket")
            .resizable()
            .scaledToFit()
            .padding(8)
            .foregroundColor(.primary)
            .background(Color(UIColor.tertiarySystemFill))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct StationCard: View {
    let station: ScanningStation
    let isSelected: Bool

    private var isExpired: Bool {
        guard let to = parseISO(station.validTo) else { return false }
        return to < Date()
    }

    private var isFuture: Bool {
        guard let from = parseISO(station.validFrom) else { return false }
        return from > Date()
    }

    /// Outside the validity window (either not yet started or already expired).
    private var isOutside: Bool { isExpired || isFuture }

    /// Dot colour mirrors the web PWA: blue=selected, gray=expired, yellow=future, green=active.
    private var dotColor: Color {
        if isSelected { return .accentColor }
        if isExpired  { return Color(UIColor.systemGray3) }
        if isFuture   { return .yellow }
        return .green
    }

    var body: some View {
        HStack(spacing: 12) {

            // Status dot — same semantic as web PWA
            Circle()
                .fill(dotColor)
                .frame(width: 8, height: 8)
                .padding(.top, 2)   // align with first text baseline

            VStack(alignment: .leading, spacing: 3) {
                Text(station.name)
                    .font(.headline)
                    .foregroundColor(isOutside ? .secondary : .primary)

                if let timeText = formatStationTimeRange(from: station.validFrom, to: station.validTo) {
                    Group {
                        if isExpired {
                            Text(timeText + " · Expired")
                        } else if isFuture {
                            Text(timeText + " · Not yet started")
                        } else {
                            Text(timeText)
                        }
                    }
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                }
            }

            Spacer()

            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
            }
        }
        .padding(12)
        .background(
            isSelected
                ? Color.accentColor.opacity(0.12)
                : Color(UIColor.secondarySystemBackground)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(
                    isSelected ? Color.accentColor.opacity(0.5) : Color.clear,
                    lineWidth: 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .opacity(isOutside ? 0.45 : 1.0)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(station.name)
        .accessibilityValue(stationDateAccessibility)
    }

    private var stationDateAccessibility: String {
        guard let timeText = formatStationTimeRange(from: station.validFrom, to: station.validTo) else {
            return NSLocalizedString("no_date_info", comment: "No date info")
        }
        return String(format: NSLocalizedString("station_date_format", comment: "Station date format"), timeText)
    }
}

// MARK: - Time-range formatter (date + time, mirrors web PWA)

private let stationDateFmt: DateFormatter = {
    let f = DateFormatter()
    f.locale = Locale(identifier: "sv_SE")
    f.dateFormat = "d MMM"
    return f
}()

private let stationTimeFmt: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "HH:mm"
    return f
}()

/// Returns a human-readable time range string, e.g. "1 jun  09:00 – 12:00"
/// or "1 jun 09:00 – 2 jun 14:00" for multi-day windows.
func formatStationTimeRange(from: String?, to: String?) -> String? {
    let fromDate = parseISO(from)
    let toDate   = parseISO(to)
    guard fromDate != nil || toDate != nil else { return nil }

    if let f = fromDate, let t = toDate {
        let sameDay = Calendar.current.isDate(f, inSameDayAs: t)
        if sameDay {
            return "\(stationDateFmt.string(from: f))  \(stationTimeFmt.string(from: f)) – \(stationTimeFmt.string(from: t))"
        }
        return "\(stationDateFmt.string(from: f)) \(stationTimeFmt.string(from: f)) – \(stationDateFmt.string(from: t)) \(stationTimeFmt.string(from: t))"
    }
    if let f = fromDate {
        return "From \(stationDateFmt.string(from: f)) \(stationTimeFmt.string(from: f))"
    }
    if let t = toDate {
        return "Until \(stationDateFmt.string(from: t)) \(stationTimeFmt.string(from: t))"
    }
    return nil
}

/// Parses an ISO-8601 string (with or without fractional seconds) into a Date.
/// Full datetime formatters are tried first so that the date-only formatter
/// cannot strip the time component from a full ISO timestamp.
func parseISO(_ raw: String?) -> Date? {
    guard let raw, !raw.isEmpty else { return nil }
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    return isoDateFormatterDateTime.date(from: trimmed)
        ?? isoDateFormatterDateTimeNoFraction.date(from: trimmed)
        ?? isoDateFormatterFull.date(from: trimmed)
}

func formatDateRange(start: String?, end: String?) -> String? {
    let startText = formatDateString(start)
    let endText = formatDateString(end)

    switch (startText, endText) {
    case let (s?, e?):
        return String(format: NSLocalizedString("valid_range_format", comment: "Valid range format"), s, e)
    case let (s?, nil):
        return String(format: NSLocalizedString("valid_from_format", comment: "Valid from format"), s)
    case let (nil, e?):
        return String(format: NSLocalizedString("valid_to_format", comment: "Valid to format"), e)
    default:
        return nil
    }
}

func formatDateString(_ raw: String?) -> String? {
    guard let raw, !raw.isEmpty else { return nil }
    let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    if let date = isoDateFormatterFull.date(from: trimmed)
        ?? isoDateFormatterDateTime.date(from: trimmed)
        ?? isoDateFormatterDateTimeNoFraction.date(from: trimmed) {
        return date.formatted(date: .abbreviated, time: .omitted)
    }
    return trimmed
}

private let isoDateFormatterFull: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withFullDate]
    return formatter
}()

private let isoDateFormatterDateTime: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
}()

struct EmptyStateView: View {
    let systemImageName: String
    let title: String
    let message: String
    var secondaryMessage: String?
    var actionTitle: String?
    var secondaryActionTitle: String?
    var action: (() -> Void)?
    var secondaryAction: (() -> Void)?

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImageName)
                .font(.largeTitle)
                .foregroundColor(.secondary)
            Text(title)
                .font(.headline)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            if let secondaryMessage, !secondaryMessage.isEmpty {
                Text(secondaryMessage)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            if actionTitle != nil || secondaryActionTitle != nil {
                HStack(spacing: 12) {
                    if let actionTitle {
                        Button(actionTitle) {
                            action?()
                        }
                    }
                    if let secondaryActionTitle {
                        Button(secondaryActionTitle) {
                            secondaryAction?()
                        }
                    }
                }
                .padding(.top, 6)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

private let isoDateFormatterDateTimeNoFraction: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter
}()
