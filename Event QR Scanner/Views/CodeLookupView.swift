//
//  CodeLookupView.swift
//  Event QR Scanner
//

import SwiftUI

struct CodeLookupView: View {
    var appSettings: AppSettings
    @Binding var selectedTab: String
    @State private var viewModel = CodeLookupViewModel()
    @State private var manualCode = ""
    @State private var isResultSheetPresented = false

    var body: some View {
        GeometryReader { geo in
            let isLandscape = geo.size.width > geo.size.height
            if isLandscape {
                landscapeLayout(geo: geo)
            } else {
                portraitLayout(geo: geo)
            }
        }
        .background(Color(UIColor.systemBackground))
        .onChange(of: hasResultOrError) {
            updateResultSheet()
        }
        .sheet(isPresented: $isResultSheetPresented, onDismiss: {
            viewModel.clear()
        }) {
            NavigationView {
                Group {
                    if let result = viewModel.result {
                        resultView(result)
                    } else if let error = viewModel.errorMessage {
                        ScrollView {
                            EmptyStateView(
                                systemImageName: "exclamationmark.triangle",
                                title: NSLocalizedString("lookup_failed", comment: "Lookup failed"),
                                message: error,
                                secondaryMessage: appSettings.isDebugEnabled ? viewModel.debugMessage : nil
                            )
                            .padding(.top, 24)
                        }
                    } else {
                        EmptyStateView(
                            systemImageName: "qrcode",
                            title: NSLocalizedString("lookup_scan_prompt", comment: "Lookup scan prompt"),
                            message: NSLocalizedString("lookup_scan_instruction", comment: "Lookup scan instruction")
                        )
                    }
                }
                .padding(.horizontal)
                .navigationTitle(NSLocalizedString("lookup_title", comment: "Lookup title"))
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button(NSLocalizedString("close", comment: "Close")) {
                            isResultSheetPresented = false
                        }
                    }
                }
            }
        }
    }

    // MARK: - Layouts

    @ViewBuilder
    private func portraitLayout(geo: GeometryProxy) -> some View {
        VStack(spacing: 12) {
            headerSection
            searchField
            scannerBox(width: geo.size.width * 0.9, height: geo.size.height * 0.3)
            statusArea
        }
        .padding()
    }

    @ViewBuilder
    private func landscapeLayout(geo: GeometryProxy) -> some View {
        HStack(alignment: .top, spacing: 16) {
            // Left: scanner
            VStack(spacing: 8) {
                searchField
                scannerBox(width: geo.size.width * 0.5 - 24, height: geo.size.height - 100)
            }
            .frame(width: geo.size.width * 0.5)

            // Right: status / result
            VStack(spacing: 0) {
                headerSection
                statusArea
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding()
    }

    // MARK: - Shared subviews

    private var headerSection: some View {
        VStack(spacing: 0) {
            HStack {
                Text(NSLocalizedString("lookup_title", comment: "Lookup title"))
                    .font(.headline)
                Spacer()
            }
            Button {
                selectedTab = "settings"
            } label: {
                EventBrandingHeaderView(
                    event: appSettings.selectedEvent,
                    subtitle: String(
                        format: NSLocalizedString("selected_station_format", comment: "Selected station label"),
                        appSettings.selectedStation?.name ?? NSLocalizedString("none_selected", comment: "No selection")
                    )
                )
            }
            .buttonStyle(.plain)
            .padding(.bottom, 4)
        }
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            TextField(NSLocalizedString("lookup_placeholder", comment: "Lookup placeholder"), text: $manualCode)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled(true)
                .textFieldStyle(.roundedBorder)

            Button {
                Task {
                    await viewModel.lookup(
                        code: manualCode,
                        eventId: appSettings.selectedEvent?.id,
                        isDebugEnabled: appSettings.isDebugEnabled
                    )
                }
            } label: {
                Image(systemName: "magnifyingglass")
                    .imageScale(.large)
                    .frame(minWidth: 44, minHeight: 44)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(NSLocalizedString("lookup_action", comment: "Lookup action"))
        }
    }

    private func scannerBox(width: CGFloat, height: CGFloat) -> some View {
        QRScannerView { scannedCode in
            Task {
                await viewModel.lookup(
                    code: scannedCode,
                    eventId: appSettings.selectedEvent?.id,
                    isDebugEnabled: appSettings.isDebugEnabled
                )
            }
        }
        .frame(width: width, height: height)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.secondary, lineWidth: 1))
    }

    private var statusArea: some View {
        ZStack {
            if viewModel.isLoading {
                ProgressView()
            } else {
                EmptyStateView(
                    systemImageName: "qrcode",
                    title: NSLocalizedString("lookup_scan_prompt", comment: "Lookup scan prompt"),
                    message: NSLocalizedString("lookup_scan_instruction", comment: "Lookup scan instruction")
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Result view

    @ViewBuilder
    private func resultView(_ result: VerifyScanResponse) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "person.crop.circle")
                        .font(.title2)
                    Text(result.person.name)
                        .font(.headline)
                }

                if let event = result.event {
                    Text(String(format: NSLocalizedString("event_format", comment: "Event name"), event))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                if let eventId = result.eventId {
                    Text(String(format: NSLocalizedString("event_id_format", comment: "Event id"), eventId))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }

                if let club = result.club {
                    Text(String(format: NSLocalizedString("club_format", comment: "Club label"), club))
                }
                if let team = result.team {
                    Text(String(format: NSLocalizedString("team_format", comment: "Team label"), team))
                }
                if let role = result.role ?? result.person.role {
                    Text(String(format: NSLocalizedString("role_format", comment: "Role label"), role))
                }

                Text(String(format: NSLocalizedString("code_format", comment: "Code label"), result.code))
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Divider()

                VStack(alignment: .leading, spacing: 10) {
                    Text(NSLocalizedString("rights_title", comment: "Rights title"))
                        .font(.headline)

                    ForEach(result.rights, id: \.self) { right in
                        RightCardView(right: right)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical)
            .padding(.horizontal)
        }
    }

    private func updateResultSheet() {
        isResultSheetPresented = viewModel.result != nil || viewModel.errorMessage != nil
    }

    private var hasResultOrError: Bool {
        viewModel.result != nil || viewModel.errorMessage != nil
    }
}

private struct RightCardView: View {
    let right: CodeRight

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .center, spacing: 8) {
                Image(systemName: statusIconName)
                    .foregroundColor(statusIconColor)
                Text(right.name)
                    .font(.headline)
                Spacer()
            }

            if right.unlimited {
                Text(NSLocalizedString("unlimited", comment: "Unlimited quota"))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                let usedCount = right.used ?? right.uses?.count
                if let usedCount {
                    Text(String(format: NSLocalizedString("used_count_format", comment: "Used count"), usedCount))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            } else if let remaining = right.remaining, let total = right.total {
                Text(String(format: NSLocalizedString("remaining_total_format", comment: "remaining/total"), remaining, total))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                if let used = right.used {
                    Text(String(format: NSLocalizedString("used_count_format", comment: "Used count"), used))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            } else if let total = right.total {
                Text(String(format: NSLocalizedString("total_only_format", comment: "Total only"), total))
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                if let used = right.used {
                    Text(String(format: NSLocalizedString("used_count_format", comment: "Used count"), used))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if let uses = right.uses, !uses.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text(NSLocalizedString("usage_title", comment: "Usage title"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ForEach(uses, id: \.self) { use in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(use.timestamp.formatted(date: .numeric, time: .shortened))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                            if let station = use.station {
                                Text(station)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            if let by = use.by {
                                Text(by)
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(Color(UIColor.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statusIconName: String {
        if right.unlimited {
            return "checkmark.circle.fill"
        }
        if let remaining = right.remaining {
            return remaining > 0 ? "checkmark.circle.fill" : "xmark.circle.fill"
        }
        return "questionmark.circle"
    }

    private var statusIconColor: Color {
        if right.unlimited {
            return .green
        }
        if let remaining = right.remaining {
            return remaining > 0 ? .green : .red
        }
        return .secondary
    }
}
