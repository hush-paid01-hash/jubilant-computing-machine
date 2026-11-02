import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0\n    @AppStorage("starterDarkMode") private var isDarkMode = false\n    @AppStorage("starterNotifications") private var notificationsEnabled = true
    @State private var tapCount = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)

            ProjectsView()\n                .tabItem { Label("Projects", systemImage: "folder.fill") }\n                .tag(1)\n\n            ComponentsView(tapCount: $tapCount)
                .tabItem {
                    Label("Components", systemImage: "square.grid.2x2.fill")
                }
                .tag(2)

            SettingsView(
                isDarkMode: $isDarkMode,
                notificationsEnabled: $notificationsEnabled
            )
            .tabItem {
                Label("Settings", systemImage: "gearshape.fill")
            }
            .tag(3)
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
                        Text("YOUR APP WORKSPACE")
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



private struct StarterProject: Identifiable, Codable {
    var id = UUID()
    var name: String
    var kind: String
    var bundleID: String
    var status: String
    var notes: String

    static func load() -> [StarterProject] {
        guard let data = UserDefaults.standard.data(forKey: "starterProjects"),
              let saved = try? JSONDecoder().decode([StarterProject].self, from: data) else {
            return [StarterProject(name: "iOS Starter", kind: "App", bundleID: "com.example.iosstarter", status: "Active", notes: "Reusable SwiftUI starter project.")]
        }
        return saved
    }
}

private struct ProjectsView: View {
    @State private var projects = StarterProject.load()
    @State private var showingAddProject = false
    @State private var searchText = ""
    private var filtered: [StarterProject] {
        searchText.isEmpty ? projects : projects.filter { $0.name.localizedCaseInsensitiveContains(searchText) || $0.kind.localizedCaseInsensitiveContains(searchText) }
    }
    var body: some View {
        NavigationStack {
            List {
                ForEach(filtered) { project in
                    NavigationLink {
                        ProjectDetailView(project: project) { updated in
                            if let i = projects.firstIndex(where: { $0.id == updated.id }) { projects[i] = updated; save() }
                        }
                    } label: {
                        HStack(spacing: 12) {
                            Image(systemName: project.kind == "Game" ? "gamecontroller.fill" : project.kind == "Utility" ? "wrench.and.screwdriver.fill" : "app.fill")
                                .font(.title2).foregroundStyle(.orange).frame(width: 42, height: 42)
                                .background(Color.orange.opacity(0.12)).clipShape(RoundedRectangle(cornerRadius: 12))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(project.name).font(.headline)
                                Text(project.bundleID).font(.caption).foregroundStyle(.secondary)
                                Text(project.status.uppercased()).font(.caption2.bold()).foregroundStyle(project.status == "Active" ? .green : .orange)
                            }
                        }.padding(.vertical, 4)
                    }
                }
                .onDelete { offsets in
                    let ids = offsets.map { filtered[$0].id }
                    projects.removeAll { ids.contains($0.id) }; save()
                }
            }
            .overlay { if filtered.isEmpty { VStack(spacing: 10) { Image(systemName: "folder").font(.largeTitle).foregroundStyle(.secondary); Text("No projects yet").font(.headline); Text("Tap + to create your first project.").font(.subheadline).foregroundStyle(.secondary) }.padding() } }
            .searchable(text: $searchText, prompt: "Search projects")
            .navigationTitle("My Projects")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { EditButton() }
                ToolbarItem(placement: .topBarTrailing) { Button { showingAddProject = true } label: { Image(systemName: "plus.circle.fill").font(.title2).foregroundStyle(.orange) } }
            }
            .sheet(isPresented: $showingAddProject) {
                AddProjectView { project in projects.insert(project, at: 0); save() }
            }
        }
    }
    private func save() {
        if let data = try? JSONEncoder().encode(projects) { UserDefaults.standard.set(data, forKey: "starterProjects") }
    }
}

private struct AddProjectView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var name = ""
    @State private var kind = "App"
    @State private var bundleID = "com.example.newapp"
    @State private var notes = ""
    let onSave: (StarterProject) -> Void
    var body: some View {
        NavigationStack {
            Form {
                Section("Project details") {
                    TextField("Project name", text: $name)
                    Picker("Type", selection: $kind) { ForEach(["App", "Game", "Utility", "Experiment"], id: \.self) { Text($0) } }
                    TextField("Bundle identifier", text: $bundleID).textInputAutocapitalization(.never).autocorrectionDisabled()
                    TextField("Notes (optional)", text: $notes, axis: .vertical).lineLimit(2...4)
                }
                Section { Text("This saves a project entry on this iPhone. It does not create a GitHub repository or a separate Xcode target automatically.").font(.footnote).foregroundStyle(.secondary) }
            }
            .navigationTitle("New Project").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(StarterProject(name: name.trimmingCharacters(in: .whitespacesAndNewlines), kind: kind, bundleID: bundleID.trimmingCharacters(in: .whitespacesAndNewlines), status: "Draft", notes: notes)); dismiss()
                    }.disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || bundleID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

private struct ProjectDetailView: View {
    @State var project: StarterProject
    let onSave: (StarterProject) -> Void
    var body: some View {
        Form {
            Section("Project") {
                TextField("Name", text: $project.name)
                TextField("Bundle identifier", text: $project.bundleID).textInputAutocapitalization(.never).autocorrectionDisabled()
                Picker("Status", selection: $project.status) { ForEach(["Draft", "Active", "In Progress", "Paused"], id: \.self) { Text($0) } }
                Picker("Type", selection: $project.kind) { ForEach(["App", "Game", "Utility", "Experiment"], id: \.self) { Text($0) } }
            }
            Section("Notes") { TextEditor(text: $project.notes).frame(minHeight: 100) }
            Section { Button("Save changes") { onSave(project) }.frame(maxWidth: .infinity) }
        }.navigationTitle(project.name).navigationBarTitleDisplayMode(.inline)
    }
}
\nprivate struct ComponentsView: View {
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
