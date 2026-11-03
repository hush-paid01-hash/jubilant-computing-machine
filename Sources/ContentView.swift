import SwiftUI

struct ContentView: View {
    @State private var selectedTab = 0
    @AppStorage("starterDarkMode") private var isDarkMode = false
    @AppStorage("starterNotifications") private var notificationsEnabled = true

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(selectedTab: $selectedTab, notificationsEnabled: $notificationsEnabled)
                .tabItem { Label("Home", systemImage: "house.fill") }
                .tag(0)
            ProjectsView()
                .tabItem { Label("Projects", systemImage: "square.layers.3d") }
                .tag(1)
            GitHubWorkspaceView()
                .tabItem { Label("GitHub", systemImage: "chevron.left.forwardslash.chevron.right") }
                .tag(2)
            TaskCenterView()
                .tabItem { Label("Tasks", systemImage: "checklist") }
                .tag(3)
            SwiftWorkspaceView()
                .tabItem { Label("Editor", systemImage: "curlybraces") }
                .tag(4)
            ComponentsView()
                .tabItem { Label("Components", systemImage: "square.grid.2x2.fill") }
                .tag(5)
            SettingsView(isDarkMode: $isDarkMode, notificationsEnabled: $notificationsEnabled)
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
                .tag(6)
        }
        .tint(.orange)
        .preferredColorScheme(isDarkMode ? .dark : .light)
    }
}

private struct HomeView: View {
    @Binding var selectedTab: Int
    @Binding var notificationsEnabled: Bool
    @State private var showingTools = false
    @State private var showingGuide = false
    @State private var projects = StarterProject.load()

    private let columns = [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    HStack(spacing: 10) {
                        Image("StarterMark")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 38, height: 38)
                            .accessibilityLabel("iOS Starter logo")
                        Text("iOS Starter")
                            .font(.title2.bold())
                            .foregroundStyle(.orange)
                        Spacer()
                        Button {
                            notificationsEnabled.toggle()
                        } label: {
                            Image(systemName: notificationsEnabled ? "bell.badge" : "bell.slash")
                                .font(.title2)
                                .foregroundStyle(.primary)
                                .padding(8)
                        }
                        .accessibilityLabel("Toggle notifications")
                    }
                    .padding(.top, 8)

                    VStack(alignment: .leading, spacing: 9) {
                        Text("WELCOME")
                            .font(.caption.weight(.heavy))
                            .tracking(1.8)
                            .foregroundStyle(.orange)
                        Text("Build, Manage, and\nShip iPhone Apps.")
                            .font(.system(size: 30, weight: .heavy, design: .rounded))
                            .fixedSize(horizontal: false, vertical: true)
                        Text("A complete SwiftUI workspace to create, organize, build, and install your apps — all from GitHub and your iPhone.")
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    LazyVGrid(columns: columns, spacing: 12) {
                        HomeTile(title: "My Projects", subtitle: "Create & manage apps", symbol: "square.stack.3d.up.fill", color: .orange) { selectedTab = 1 }
                        HomeTile(title: "Components", subtitle: "Reusable UI examples", symbol: "chevron.left.forwardslash.chevron.right", color: .purple) { selectedTab = 3 }
                        HomeTile(title: "Tools", subtitle: "Build, sign & install", symbol: "wrench.and.screwdriver.fill", color: .blue) { showingTools = true }
                        HomeTile(title: "Guide", subtitle: "Step-by-step help", symbol: "book.closed.fill", color: .green) { showingGuide = true }
                    }

                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text("Recent Projects").font(.title3.bold())
                            Spacer()
                            Button("See All") { selectedTab = 1 }
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.orange)
                        }
                        ForEach(projects.prefix(3)) { project in
                            NavigationLink {
                                ProjectDetailView(project: project) { updated in
                                    if let index = projects.firstIndex(where: { $0.id == updated.id }) {
                                        projects[index] = updated
                                        saveProjects()
                                    }
                                }
                            } label: {
                                RecentProjectRow(
                                    name: project.name == "iOSStarter" ? "iOS Starter" : project.name,
                                    detail: project.name == "iOSStarter" ? "Last opened today" : "\(project.kind) • iOS",
                                    symbol: project.kind == "Game" ? "gamecontroller.fill" : project.kind == "Utility" ? "desktopcomputer" : "app.fill",
                                    color: project.kind == "Game" ? .purple : project.kind == "Utility" ? .blue : .orange
                                )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 24)
            }
            .background(Color(uiColor: .systemBackground))
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingTools) { ToolsView() }
            .sheet(isPresented: $showingGuide) { StarterGuideView() }
        }
    }

    private func saveProjects() {
        if let data = try? JSONEncoder().encode(projects) {
            UserDefaults.standard.set(data, forKey: "starterProjects")
        }
    }
}

private struct HomeTile: View {
    let title: String
    let subtitle: String
    let symbol: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: symbol)
                    .font(.system(size: 29, weight: .semibold))
                    .foregroundStyle(color)
                    .frame(height: 38)
                Text(title).font(.headline).foregroundStyle(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity, minHeight: 112)
            .padding(10)
            .background(Color(uiColor: .secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(Color.primary.opacity(0.06), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

private struct RecentProjectRow: View {
    let name: String
    let detail: String
    let symbol: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 46, height: 46)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 13))
            VStack(alignment: .leading, spacing: 3) {
                Text(name).font(.subheadline.bold()).foregroundStyle(.primary)
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.tertiary)
        }
        .padding(11)
        .background(Color(uiColor: .secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct StarterProject: Identifiable, Codable {
    var id = UUID()
    var name: String
    var kind: String
    var bundleID: String
    var status: String
    var notes: String

    static var samples: [StarterProject] {
        [
            StarterProject(name: "iOSStarter", kind: "App", bundleID: "com.example.iosstarter", status: "Active", notes: "SwiftUI workspace and app builder."),
            StarterProject(name: "Hush (PS2 Emulator)", kind: "Game", bundleID: "com.hush.ps2", status: "In Progress", notes: "Original PS2 emulator project for iPhone."),
            StarterProject(name: "Sales Dashboard", kind: "App", bundleID: "com.example.sales", status: "Draft", notes: "Revenue, deals, and recent leads."),
            StarterProject(name: "UTM VM Helper", kind: "Utility", bundleID: "com.example.utmhelper", status: "Draft", notes: "Virtual machine helper tools.")
        ]
    }

    static func load() -> [StarterProject] {
        guard let data = UserDefaults.standard.data(forKey: "starterProjects"),
              let saved = try? JSONDecoder().decode([StarterProject].self, from: data) else {
            return samples
        }
        return saved
    }
}

private struct ProjectsView: View {
    @State private var projects = StarterProject.load()
    @State private var showingAddProject = false
    @State private var searchText = ""
    @State private var selectedFilter = "All"
    private let filters = ["All", "Apps", "Games", "Tools"]

    private var filtered: [StarterProject] {
        projects.filter { project in
            let matchesSearch = searchText.isEmpty || project.name.localizedCaseInsensitiveContains(searchText) || project.kind.localizedCaseInsensitiveContains(searchText)
            let matchesFilter = selectedFilter == "All" ||
                (selectedFilter == "Apps" && project.kind == "App") ||
                (selectedFilter == "Games" && project.kind == "Game") ||
                (selectedFilter == "Tools" && project.kind == "Utility")
            return matchesSearch && matchesFilter
        }
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 14) {
                HStack {
                    Text("My Projects").font(.largeTitle.bold())
                    Spacer()
                    Button { showingAddProject = true } label: {
                        Image(systemName: "plus").font(.title2.bold()).foregroundStyle(.white)
                            .frame(width: 42, height: 42).background(.orange).clipShape(Circle())
                    }
                    .accessibilityLabel("Create project")
                }
                .padding(.horizontal, 18)
                .padding(.top, 8)

                HStack(spacing: 9) {
                    Image(systemName: "magnifyingglass").foregroundStyle(.secondary)
                    TextField("Search projects", text: $searchText)
                }
                .padding(12)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .padding(.horizontal, 18)

                HStack(spacing: 9) {
                    ForEach(filters, id: \.self) { filter in
                        Button { selectedFilter = filter } label: {
                            Text(filter).font(.subheadline.weight(.semibold))
                                .foregroundStyle(selectedFilter == filter ? .white : .primary)
                                .frame(maxWidth: .infinity).padding(.vertical, 10)
                                .background(selectedFilter == filter ? Color.orange : Color(uiColor: .secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 13))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 18)

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(filtered) { project in
                            NavigationLink {
                                ProjectDetailView(project: project) { updated in
                                    if let index = projects.firstIndex(where: { $0.id == updated.id }) {
                                        projects[index] = updated
                                        save()
                                    }
                                }
                            } label: {
                                ProjectCard(project: project)
                            }
                            .buttonStyle(.plain)
                            Divider().padding(.leading, 68)
                        }
                    }
                    .padding(.horizontal, 18)
                }

                Button { showingAddProject = true } label: {
                    Label("Create New Project", systemImage: "plus")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(Color.orange)
                        .clipShape(RoundedRectangle(cornerRadius: 15))
                }
                .padding(.horizontal, 18)
                .padding(.bottom, 8)
            }
            .background(Color(uiColor: .systemBackground))
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showingAddProject) {
                AddProjectView { project in projects.insert(project, at: 0); save() }
            }
        }
    }

    private func save() {
        if let data = try? JSONEncoder().encode(projects) {
            UserDefaults.standard.set(data, forKey: "starterProjects")
        }
    }
}

private struct ProjectCard: View {
    let project: StarterProject
    private var symbol: String {
        project.kind == "Game" ? "gamecontroller.fill" : project.kind == "Utility" ? "desktopcomputer" : "app.fill"
    }
    private var tint: Color { project.kind == "Game" ? .purple : project.kind == "Utility" ? .blue : .orange }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: symbol).font(.title2).foregroundStyle(tint)
                .frame(width: 48, height: 48).background(tint.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 13))
            VStack(alignment: .leading, spacing: 4) {
                Text(project.name).font(.subheadline.bold()).foregroundStyle(.primary)
                Text("\(project.kind) • iOS").font(.caption).foregroundStyle(.secondary)
                Text(project.status)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(project.status == "Active" ? .green : project.status == "In Progress" ? .blue : .secondary)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background((project.status == "Active" ? Color.green : project.status == "In Progress" ? Color.blue : Color.gray).opacity(0.12))
                    .clipShape(Capsule())
            }
            Spacer()
            Image(systemName: "chevron.right").font(.caption.bold()).foregroundStyle(.tertiary)
        }
        .padding(.vertical, 12)
        .contentShape(Rectangle())
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
                    Picker("Type", selection: $kind) {
                        ForEach(["App", "Game", "Utility", "Experiment"], id: \.self) { Text($0) }
                    }
                    TextField("Bundle identifier", text: $bundleID).textInputAutocapitalization(.never).autocorrectionDisabled()
                    TextField("Notes (optional)", text: $notes, axis: .vertical).lineLimit(2...4)
                }
                Section {
                    Text("Project entries are saved locally on this iPhone. They do not automatically create GitHub repositories or Xcode targets.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("New Project").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(StarterProject(name: name.trimmingCharacters(in: .whitespacesAndNewlines), kind: kind, bundleID: bundleID, status: "Draft", notes: notes))
                        dismiss()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
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
                Picker("Status", selection: $project.status) {
                    ForEach(["Draft", "Active", "In Progress", "Paused"], id: \.self) { Text($0) }
                }
                Picker("Type", selection: $project.kind) {
                    ForEach(["App", "Game", "Utility", "Experiment"], id: \.self) { Text($0) }
                }
            }
            Section("Notes") { TextEditor(text: $project.notes).frame(minHeight: 100) }
            Section { Button("Save changes") { onSave(project) }.frame(maxWidth: .infinity) }
        }
        .navigationTitle(project.name).navigationBarTitleDisplayMode(.inline)
    }
}

private struct ComponentsView: View {
    @State private var tapCount = 0

    var body: some View {
        NavigationStack {
            List {
                Section("Interactive example") {
                    HStack {
                        Label("Button taps", systemImage: "hand.tap")
                        Spacer()
                        Text("\(tapCount)").font(.headline.monospacedDigit()).foregroundStyle(.orange)
                    }
                    Button { tapCount += 1 } label: { Label("Try the button", systemImage: "plus.circle.fill") }
                    Button(role: .destructive) { tapCount = 0 } label: { Label("Reset counter", systemImage: "arrow.counterclockwise") }
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


private struct ToolsView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Build tools") {
                    Link(destination: URL(string: "https://github.com/hush-paid01-hash/jubilant-computing-machine/actions/workflows/build-ios-ipa.yml")!) {
                        Label {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Build iOS IPA")
                                Text("Open the exact workflow, start a build, and check its result").font(.caption).foregroundStyle(.secondary)
                            }
                        } icon: { Image(systemName: "hammer.fill").foregroundStyle(.orange) }
                    }
                    Link(destination: URL(string: "https://github.com/hush-paid01-hash/jubilant-computing-machine/actions")!) {
                        Label("Build history & artifacts", systemImage: "clock.arrow.circlepath")
                    }
                    Link(destination: URL(string: "https://github.com/hush-paid01-hash/jubilant-computing-machine")!) {
                        Label("Open project repository", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                }
                Section("Signing & installation") {
                    Label("Download the IOSStarter-Unsigned-IPA artifact from a successful run", systemImage: "square.and.arrow.down")
                    Label("Import the unsigned IPA into ESign", systemImage: "doc.badge.arrow.up")
                    Label("Choose your certificate and matching profile", systemImage: "signature")
                    Label("Sign and install the app on this iPhone", systemImage: "checkmark.iphone")
                }
                Section {
                    Text("These tools open the real GitHub project and provide the ESign workflow. Signing still happens in ESign on your device.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Tools")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

private struct StarterGuideView: View {
    var body: some View {
        NavigationStack {
            List {
                Section("Getting started") {
                    Label("Create or select a project in My Projects", systemImage: "1.circle.fill")
                    Label("Make source changes in the connected GitHub repository", systemImage: "2.circle.fill")
                    Label("Run the iOS build workflow in GitHub Actions", systemImage: "3.circle.fill")
                    Label("Download the unsigned IPA and sign it with ESign", systemImage: "4.circle.fill")
                }
                Section("Important") {
                    Text("A successful cloud build confirms compilation. Always install the signed IPA and test it on your iPhone.")
                    Text("Project entries in this starter app are stored locally; they do not automatically create GitHub repositories or Xcode targets.")
                }
            }
            .navigationTitle("Getting Started")
            .navigationBarTitleDisplayMode(.inline)
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
                    Toggle(isOn: $isDarkMode) {
                        Label("Dark Mode", systemImage: "moon")
                    }
                    .tint(.orange)
                }
                Section("App") {
                    NavigationLink {
                        AppInfoView()
                    } label: {
                        Label {
                            HStack { Text("App Name"); Spacer(); Text("iOS Starter").foregroundStyle(.secondary) }
                        } icon: { Image(systemName: "square.grid.2x2") }
                    }
                    NavigationLink {
                        AppInfoView()
                    } label: {
                        Label("App Icon", systemImage: "photo")
                    }
                    LabeledContent("Bundle Identifier", value: "com.example.iosstarter")
                    LabeledContent("Version", value: "3.0.0")
                }
                Section("Build & Install") {
                    NavigationLink {
                        BuildGuideView()
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("GitHub Actions")
                                Text("Build IPA in the cloud").font(.caption).foregroundStyle(.secondary)
                            }
                        } icon: { Image(systemName: "chevron.left.forwardslash.chevron.right") }
                    }
                    NavigationLink {
                        SigningGuideView()
                    } label: {
                        Label {
                            VStack(alignment: .leading, spacing: 3) {
                                Text("Signing Guide")
                                Text("Sign and install with ESign").font(.caption).foregroundStyle(.secondary)
                            }
                        } icon: { Image(systemName: "pencil.and.outline") }
                    }
                }
                Section("Preferences") {
                    Toggle("Notifications", isOn: $notificationsEnabled).tint(.orange)
                }
                Section("About") {
                    LabeledContent("About", value: "iOS Starter")
                    Link(destination: URL(string: "https://github.com/hush-paid01-hash/jubilant-computing-machine")!) {
                        Label("Support & Source Code", systemImage: "heart")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}

private struct AppInfoView: View {
    var body: some View {
        List {
            Label("iOS Starter", systemImage: "bird.fill").foregroundStyle(.orange)
            LabeledContent("Bundle Identifier", value: "com.example.iosstarter")
            LabeledContent("Minimum iOS", value: "16.0")
            Text("The app icon is generated from the repository's Assets/AppIcon.svg during the cloud build.")
                .font(.footnote).foregroundStyle(.secondary)
        }
        .navigationTitle("App Details")
    }
}

private struct BuildGuideView: View {
    var body: some View {
        List {
            Section("Build from your iPhone") {
                Label("Open the repository on GitHub", systemImage: "1.circle.fill")
                Label("Tap Actions, then Build iOS IPA", systemImage: "2.circle.fill")
                Label("Run workflow on the main branch", systemImage: "3.circle.fill")
                Label("Download IOSStarter-Unsigned-IPA after success", systemImage: "4.circle.fill")
            }
            Section {
                Link("Open GitHub Actions", destination: URL(string: "https://github.com/hush-paid01-hash/jubilant-computing-machine/actions")!)
            }
            Text("The cloud runner uses Xcode to build the device app. The IPA is unsigned until you sign it with ESign.")
                .font(.footnote).foregroundStyle(.secondary)
        }
        .navigationTitle("Build with GitHub")
    }
}

private struct SigningGuideView: View {
    var body: some View {
        List {
            Section("Install with ESign") {
                Label("Download the unsigned IPA artifact from a successful Actions run", systemImage: "1.circle.fill")
                Label("Open the IPA in Files and share it to ESign", systemImage: "2.circle.fill")
                Label("Select your signing certificate and matching provisioning profile", systemImage: "3.circle.fill")
                Label("Sign, then install the signed app", systemImage: "4.circle.fill")
            }
            Text("Your provisioning profile must authorize this app's bundle identifier. Never share or upload your certificate's private key.")
                .font(.footnote).foregroundStyle(.secondary)
        }
        .navigationTitle("Signing Guide")
    }
}
