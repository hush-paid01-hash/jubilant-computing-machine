import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @State private var isDarkMode = false
    @State private var notificationsEnabled = true
    @State private var tapCount = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            ComponentsView(tapCount: $tapCount)
                .tabItem {
                    Label("Components", systemImage: "square.grid.2x2.fill")
                }
                .tag(1)

            SettingsView(
                isDarkMode: $isDarkMode,
                notificationsEnabled: $notificationsEnabled
            )
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(2)
        }
        .tint(.orange)
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

private struct HomeView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("WELCOME")
                            .font(.caption.weight(.bold))
                            .tracking(1.5)
                            .foregroundStyle(.orange)
                        Text("Build something\nwonderful.")
                            .font(.largeTitle.bold())
                            .fixedSize(horizontal: false, vertical: true)
                        Text("Your SwiftUI workspace is ready. Use this starter as the foundation for your next iPhone app.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "swift")
                            .font(.system(size: 34, weight: .medium))
                            .foregroundStyle(.orange)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Native iOS app")
                                .font(.headline)
                            Text("Built with SwiftUI and Xcode")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundStyle(.green)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 18))

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Your next steps")
                            .font(.title3.bold())
                        NextStepRow(number: "01", title: "Choose an app idea", detail: "Decide what problem your app will solve.")
                        NextStepRow(number: "02", title: "Customize the screens", detail: "Edit the SwiftUI views in the Sources folder.")
                        NextStepRow(number: "03", title: "Build and install", detail: "Run the Build iOS IPA workflow in GitHub Actions.")
                    }
                }
                .padding()
            }
            .navigationTitle("iOS Starter")
        }
    }
}

private struct NextStepRow: View {
    let number: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Text(number)
                .font(.headline.monospacedDigit())
                .foregroundStyle(.orange)
                .frame(width: 34, height: 34)
                .background(Color.orange.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private struct ComponentsView: View {
    @Binding var tapCount: Int

    var body: some View {
        NavigationStack {
            List {
                Section("Interactive example") {
                    HStack {
                        Label("Button taps", systemImage: "hand.tap")
                        Spacer()
                        Text("\(tapCount)")
                            .font(.headline.monospacedDigit())
                            .foregroundStyle(.orange)
                    }
                    Button {
                        tapCount += 1
                    } label: {
                        Label("Try the button", systemImage: "plus.circle.fill")
                    }
                    Button(role: .destructive) {
                        tapCount = 0
                    } label: {
                        Label("Reset counter", systemImage: "arrow.counterclockwise")
                    }
                }

                Section("Reusable SwiftUI building blocks") {
                    Label("Navigation", systemImage: "arrow.left.and.right")
                    Label("Lists and sections", systemImage: "list.bullet")
                    Label("Buttons and state", systemImage: "cursorarrow.click")
                    Label("System icons", systemImage: "square.grid.3x3")
                }
            }
            .navigationTitle("Components")
        }
    }
}

private struct SettingsView: View {
    @Binding var isDarkMode: Bool
    @Binding var notificationsEnabled: Bool

    var body: some View {
        NavigationStack {
            Form {
                Section("Appearance") {
                    Toggle("Dark mode", isOn: $isDarkMode)
                }
                Section("Preferences") {
                    Toggle("Notifications", isOn: $notificationsEnabled)
                }
                Section("About") {
                    LabeledContent("App", value: "iOS Starter")
                    LabeledContent("UI framework", value: "SwiftUI")
                    LabeledContent("Minimum iOS", value: "16.0")
                }
            }
            .navigationTitle("Settings")
        }
    }
}
