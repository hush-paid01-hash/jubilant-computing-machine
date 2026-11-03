import SwiftUI

private struct WorkspaceFile: Identifiable, Hashable {
    let id: String
    let title: String
    let symbol: String
    let starter: String
}

struct SwiftWorkspaceView: View {
    @AppStorage("starterWorkspaceSwiftSource") private var source = WorkspaceFile.defaultSource
    @AppStorage("starterWorkspaceSelectedFile") private var selectedFile = "ContentView.swift"
    @State private var showConsole = true
    @State private var showTools = false

    private let files = [
        WorkspaceFile(id: "ContentView.swift", title: "ContentView.swift", symbol: "swift", starter: WorkspaceFile.defaultSource),
        WorkspaceFile(id: "App.swift", title: "App.swift", symbol: "swift", starter: WorkspaceFile.appSource),
        WorkspaceFile(id: "README.md", title: "README.md", symbol: "doc.text", starter: WorkspaceFile.readme)
    ]

    private var lineCount: Int { max(1, source.components(separatedBy: "\n").count) }
    private var characterCount: Int { source.count }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text("iOS Starter Workspace").font(.headline)
                        Text("Project: iOSStarter · v3.0").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button { showTools = true } label: {
                        Image(systemName: "wrench.and.screwdriver").font(.title3).foregroundStyle(.orange)
                    }
                    .accessibilityLabel("Workspace tools")
                }
                .padding()

                HStack(spacing: 8) {
                    Image(systemName: "folder.fill").foregroundStyle(.orange)
                    Text("IOSStarter").font(.subheadline.weight(.semibold))
                    Spacer()
                    Text("PROJECT NAVIGATOR").font(.caption2.weight(.bold)).tracking(0.8).foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color(uiColor: .secondarySystemBackground))

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(files) { file in
                            Button {
                                selectedFile = file.id
                                if file.id == "ContentView.swift" { source = UserDefaults.standard.string(forKey: "starterWorkspaceContentView") ?? file.starter }
                                else { source = UserDefaults.standard.string(forKey: "starterWorkspace_" + file.id) ?? file.starter }
                            } label: {
                                Label(file.title, systemImage: file.symbol)
                                    .font(.caption.weight(.medium))
                                    .padding(.horizontal, 11)
                                    .padding(.vertical, 9)
                                    .background(selectedFile == file.id ? Color.orange.opacity(0.18) : Color(uiColor: .secondarySystemBackground))
                                    .foregroundStyle(selectedFile == file.id ? .orange : .primary)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 9)
                }

                HStack {
                    Text(selectedFile).font(.caption.weight(.semibold))
                    Spacer()
                    Text("Swift").font(.caption2).foregroundStyle(.secondary)
                    Circle().fill(.green).frame(width: 7, height: 7)
                    Text("Saved locally").font(.caption2).foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.vertical, 8)

                HStack(alignment: .top, spacing: 0) {
                    VStack(alignment: .trailing, spacing: 0) {
                        ForEach(1...min(lineCount, 180), id: \.self) { number in
                            Text("\(number)")
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(.tertiary)
                                .frame(width: 34, height: 19, alignment: .trailing)
                        }
                    }
                    .padding(.top, 11)
                    .padding(.trailing, 8)
                    .background(Color(uiColor: .secondarySystemBackground))
                    TextEditor(text: $source)
                        .font(.system(size: 13, design: .monospaced))
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 4)
                        .onChange(of: source) { newValue in
                            let key = selectedFile == "ContentView.swift" ? "starterWorkspaceContentView" : "starterWorkspace_" + selectedFile
                            UserDefaults.standard.set(newValue, forKey: key)
                        }
                }
                .background(Color(uiColor: .systemBackground))
                .frame(maxHeight: .infinity)

                HStack(spacing: 16) {
                    Label("\(lineCount) lines", systemImage: "text.alignleft")
                    Label("\(characterCount) chars", systemImage: "character.cursor.ibeam")
                    Spacer()
                    Button {
                        showConsole.toggle()
                    } label: {
                        Label("Console", systemImage: "terminal")
                    }
                }
                .font(.caption)
                .padding(.horizontal)
                .padding(.vertical, 10)
                .background(Color(uiColor: .secondarySystemBackground))

                if showConsole {
                    VStack(alignment: .leading, spacing: 9) {
                        HStack {
                            Label("BUILD & COMPILER", systemImage: "hammer")
                                .font(.caption.weight(.bold))
                                .tracking(0.7)
                            Spacer()
                            Text("Ready to build").font(.caption2).foregroundStyle(.secondary)
                        }
                        HStack(spacing: 8) {
                            Circle().fill(.green).frame(width: 7, height: 7)
                            Text("Swift compiler: Apple Swift via Xcode (cloud runner)")
                                .font(.caption)
                        }
                        Text("Build output will appear in GitHub Actions after you start a cloud build. This editor saves drafts on this iPhone; it does not compile or execute Swift locally.")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                        Link(destination: URL(string: "https://github.com/hush-paid01-hash/jubilant-computing-machine/actions/workflows/build-ios-ipa.yml")!) {
                            Label("Open Xcode Cloud Build", systemImage: "arrow.up.right.square")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 11)
                                .background(Color.orange)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 11))
                        }
                    }
                    .padding()
                    .background(Color(uiColor: .secondarySystemBackground))
                }
            }
            .navigationBarHidden(true)
            .sheet(isPresented: $showTools) {
                NavigationStack {
                    List {
                        Section("Editor") {
                            Label("Swift source editor with local draft saving", systemImage: "chevron.left.forwardslash.chevron.right")
                            Label("Project navigator with starter Swift and README files", systemImage: "folder")
                            Label("Live line and character counts", systemImage: "text.alignleft")
                        }
                        Section("Xcode build tools") {
                            Label("Apple Swift compiler on macOS Xcode runner", systemImage: "swift")
                            Label("Unsigned iOS device build and IPA packaging", systemImage: "shippingbox")
                            Label("Build logs and errors in GitHub Actions", systemImage: "list.bullet.rectangle")
                            Link("Open build history", destination: URL(string: "https://github.com/hush-paid01-hash/jubilant-computing-machine/actions")!)
                        }
                        Section("Limitations") {
                            Text("iOS does not permit this app to launch macOS Xcode or run arbitrary project binaries locally. The cloud workflow currently builds the iOS Starter repository; it does not yet import and build every third-party project.")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                    .navigationTitle("Xcode Tools")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showTools = false } } }
                }
            }
        }
        .onAppear {
            if source == WorkspaceFile.defaultSource && selectedFile == "ContentView.swift" {
                source = UserDefaults.standard.string(forKey: "starterWorkspaceContentView") ?? WorkspaceFile.defaultSource
            }
        }
    }
}

private extension WorkspaceFile {
    static let defaultSource = """
import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: "swift")
                    .font(.system(size: 48))
                    .foregroundStyle(.orange)
                Text("Hello, iOS Starter!")
                    .font(.title.bold())
                Text("Edit this SwiftUI view and build your app.")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("My App")
        }
    }
}
"""
    static let appSource = """
import SwiftUI

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
"""
    static let readme = """
# My iOS Project

Created with iOS Starter v3.

## Build
Use the Xcode Tools workspace to edit Swift drafts, then start a supported GitHub Actions build.
"""
}
