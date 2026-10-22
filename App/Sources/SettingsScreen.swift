import SwiftUI

/// Everything touched only now and then: the export, What's new, How it works and the
/// version — the same place AMS Packing keeps them.
struct SettingsScreen: View {
    @Environment(\.dismiss) private var dismiss
    let csv: String

    var body: some View {
        NavigationStack {
            Form {
                Section("Your expenses") {
                    ShareLink(item: CSVExport(csv: csv), preview: SharePreview("Expenses.csv")) {
                        Label("Export all as CSV", systemImage: "square.and.arrow.up")
                    }
                    .accessibilityIdentifier("settings-export")
                }
                Section("About") {
                    NavigationLink { WhatsNewScreen() } label: { Text("What's new") }
                        .accessibilityIdentifier("settings-whatsnew")
                    NavigationLink { GuideScreen() } label: { Text("How it works") }
                        .accessibilityIdentifier("settings-howitworks")
                    HStack {
                        Text("Version")
                        Spacer()
                        Text(AppVersion.text)
                            .foregroundStyle(.secondary)
                            .accessibilityIdentifier("settings-version")
                    }
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .accessibilityIdentifier("settings-done")
                }
            }
        }
    }
}

/// "1.0 (3)": the version and the TestFlight build, read from the app itself.
enum AppVersion {
    static var version: String { Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?" }
    static var build: String { Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?" }
    static var text: String { "\(version) (\(build))" }
}

struct WhatsNewScreen: View {
    var body: some View {
        List {
            ForEach(Array(Releases.all.enumerated()), id: \.element.version) { index, release in
                Section {
                    ForEach(release.lines, id: \.self) { Text($0) }
                } header: {
                    HStack {
                        Text(release.version)
                            .accessibilityIdentifier("whatsnew-\(index)-version")
                        Spacer()
                        Text(release.date)
                    }
                }
            }
        }
        .navigationTitle("What's new")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct GuideScreen: View {
    var body: some View {
        List {
            ForEach(Guide.sections, id: \.title) { section in
                Section(section.title) {
                    ForEach(section.lines, id: \.self) { Text($0) }
                }
            }
        }
        .navigationTitle("How it works")
        .navigationBarTitleDisplayMode(.inline)
    }
}
