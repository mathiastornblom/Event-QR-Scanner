//
//  EventBrandingHeaderView.swift
//  Event QR Scanner
//

import SwiftUI

struct EventBrandingHeaderView: View {
    let event: Event?
    var subtitle: String?

    var body: some View {
        HStack(spacing: 12) {
            if let event {
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
                .frame(width: 42, height: 42)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .accessibilityLabel(String(format: NSLocalizedString("event_logo_format", comment: "Event logo"), event.name))
            } else {
                fallbackLogo
                    .frame(width: 42, height: 42)
                    .accessibilityLabel(NSLocalizedString("event_logo", comment: "Event logo"))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(event?.name ?? NSLocalizedString("no_event_selected", comment: "No event selected"))
                    .font(.headline)
                    .foregroundColor(.primary)

                if let subtitle, !subtitle.isEmpty {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.primary.opacity(0.85))
                        .lineLimit(2)
                }
            }
            Spacer()
        }
        .padding(10)
        .background(Color(UIColor.secondarySystemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(eventPrimaryColor.opacity(0.35), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }

    private var fallbackLogo: some View {
        Image(systemName: "ticket")
            .resizable()
            .scaledToFit()
            .padding(8)
            .foregroundColor(.primary)
            .background(eventPrimaryColor.opacity(0.20))
            .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var eventPrimaryColor: Color {
        Color(hex: event?.primaryColor) ?? .blue
    }
}

private extension Color {
    init?(hex: String?) {
        guard var hex, !hex.isEmpty else { return nil }
        hex = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hex = hex.replacingOccurrences(of: "#", with: "")

        guard let intValue = Int(hex, radix: 16) else { return nil }

        switch hex.count {
        case 6:
            let r = Double((intValue >> 16) & 0xFF) / 255.0
            let g = Double((intValue >> 8) & 0xFF) / 255.0
            let b = Double(intValue & 0xFF) / 255.0
            self = Color(red: r, green: g, blue: b)
        case 8:
            let a = Double((intValue >> 24) & 0xFF) / 255.0
            let r = Double((intValue >> 16) & 0xFF) / 255.0
            let g = Double((intValue >> 8) & 0xFF) / 255.0
            let b = Double(intValue & 0xFF) / 255.0
            self = Color(red: r, green: g, blue: b, opacity: a)
        default:
            return nil
        }
    }
}
