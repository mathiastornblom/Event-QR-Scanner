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

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "bolt.circle")
                .resizable()
                .scaledToFit()
                .frame(width: 34, height: 34)
                .foregroundColor(.accentColor)

            VStack(alignment: .leading, spacing: 4) {
                Text(station.name)
                    .font(.headline)
                    .foregroundColor(.primary)
                if let dateText = formatDateRange(start: station.validFrom, end: station.validTo) {
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
        .accessibilityLabel(station.name)
        .accessibilityValue(stationDateAccessibility)
    }

    private var stationDateAccessibility: String {
        guard let dateText = formatDateRange(start: station.validFrom, end: station.validTo) else {
            return NSLocalizedString("no_date_info", comment: "No date info")
        }
        return String(format: NSLocalizedString("station_date_format", comment: "Station date format"), dateText)
    }
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
