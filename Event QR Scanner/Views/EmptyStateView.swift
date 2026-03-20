//
//  EmptyStateView.swift
//  Event QR Scanner
//

import SwiftUI

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
