import SwiftUI

private struct WorkspaceFile: Identifiable, Hashable {
    let id: String
    let symbol: String
    let starter: String
}

struct SwiftWorkspaceView: View {
    @AppStorage("starterWorkspaceSwiftSource") private var source = WorkspaceFile.defaultSource
    @AppStorage("starterWorkspaceSelectedFile") private var selectedFile = "ContentView.swift"
    @State private var showConsole = true
    @State private var showTools = false
    @State private var showImport = false
    @State private var importMessage = "Ready"
    @State private var files = [
        WorkspaceFile(id: "ContentView.swift", symbol: "swift", starter: WorkspaceFile.defaultSource),
        WorkspaceFile(id: "App.swift", symbol: "swift", starter: WorkspaceFile.appSource),
        WorkspaceFile(id: "README.md", symbol: "doc.text", starter: WorkspaceFile.readme)
    ]

    private var lineCount: Int { max(1, source.components(separatedBy: "\n").count) }
    private var selectedSymbol: String { files.first(where: { $0.id == selectedFile })?.symbol ?? "swift" }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: 10) {
                    Image(systemName: "hammer.fill").foregroundStyle(.orange).font(.title3)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("iOS Starter IDE").font(.headline)
                        Text("WORKSPACE  /  IOSSTARTER").font(.system(size: 9, weight: .bold, design: .monospaced)).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Button { showImport = true } label: { Image(systemName: "square.and.arrow.down").font(.title3) }
                        .accessibilityLabel("Import source file")
                    Button { showTools = true } label: { Image(systemName: "ellipsis.circle").font(.title3) }
                        .accessibilityLabel("IDE tools")
                }
                .padding(.horizontal, 14).padding(.vertical, 12)
                .background(Color(red: 0.12, green: 0.13, blue: 0.15))

                HStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("PROJECT").font(.system(size: 9, weight: .heavy, design: .monospaced)).foregroundStyle(.gray)
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.down").font(.system(size: 9, weight: .bold))
                            Image(systemName: "folder.fill").foregroundStyle(.orange)
                            Text("iOSStarter").font(.system(size: 11, weight: .semibold, design: .monospaced))
                        }
                        ForEach(files) { file in
                            Button {
                                saveCurrent()
                                selectedFile = file.id
                                source = UserDefaults.standard.string(forKey: storageKey(file.id)) ?? file.starter
                            } label: {
                                HStack(spacing: 6) {
                                    Image(systemName: file.symbol).foregroundStyle(file.symbol == "swift" ? .orange : .cyan)
                                    Text(file.id).lineLimit(1)
                                }
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundStyle(selectedFile == file.id ? .white : .gray)
                                .padding(.vertical, 5).padding(.horizontal, 5)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(selectedFile == file.id ? Color.orange.opacity(0.20) : .clear)
                                .clipShape(RoundedRectangle(cornerRadius: 5))
                            }
                            .buttonStyle(.plain)
                        }
                        Spacer()
                        Text("iOS · Swift 5").font(.system(size: 9, design: .monospaced)).foregroundStyle(.gray)
                    }
                    .padding(9).frame(width: 112).background(Color(red: 0.105, green: 0.115, blue: 0.13))

                    VStack(spacing: 0) {
                        HStack(spacing: 7) {
                            Circle().fill(Color(red: 1, green: 0.35, blue: 0.32)).frame(width: 7, height: 7)
                            Circle().fill(.orange).frame(width: 7, height: 7)
                            Circle().fill(.green).frame(width: 7, height: 7)
                            Spacer()
                            Image(systemName: selectedSymbol).foregroundStyle(.orange)
                            Text(selectedFile).font(.system(size: 10, weight: .medium, design: .monospaced))
                            Spacer()
                            Image(systemName: "ellipsis").foregroundStyle(.gray)
                        }
                        .padding(10).background(Color(red: 0.16, green: 0.17, blue: 0.19))
                        HStack(alignment: .top, spacing: 0) {
                            VStack(alignment: .trailing, spacing: 0) {
                                ForEach(1...min(lineCount, 250), id: \.self) { n in
                                    Text("\(n)").font(.system(size: 11, design: .monospaced))
                                        .foregroundStyle(.gray.opacity(0.7)).frame(width: 29, height: 19, alignment: .trailing)
                                }
                            }.padding(.top, 10).padding(.trailing, 7)
                            TextEditor(text: $source)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundStyle(Color(red: 0.86, green: 0.88, blue: 0.91))
                                .tint(.orange).scrollContentBackground(.hidden)
                                .autocorrectionDisabled().textInputAutocapitalization(.never)
                                .padding(.top, 3)
                                .onChange(of: source) { _ in saveCurrent() }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                        .background(Color(red: 0.075, green: 0.085, blue: 0.10))
                        HStack {
                            Text("Ln \(lineCount), Col 1")
                            Spacer()
                            Text("UTF-8")
                            Text("  ·  ")
                            Text("Swift")
                        }
                        .font(.system(size: 9, design: .monospaced)).foregroundStyle(.gray)
                        .padding(.horizontal, 10).padding(.vertical, 7)
                        .background(Color(red: 0.15, green: 0.16, blue: 0.18))
                    }
                }
                .frame(maxHeight: .infinity)

                HStack(spacing: 14) {
                    Button { showConsole.toggle() } label: {
                        Label("Console", systemImage: "terminal").foregroundStyle(showConsole ? .orange : .gray)
                    }
                    Button { showImport = true } label: { Label("Open File", systemImage: "doc.badge.plus") }
                    Spacer()
                    Text("\(lineCount) lines").foregroundStyle(.gray)
                }
                .font(.system(size: 10, weight: .medium, design: .monospaced))
                .padding(10).background(Color(red: 0.13, green: 0.14, blue: 0.16))

                if showConsole {
                    VStack(alignment: .leading, spacing: 7) {
                        HStack {
                            Text("ISSUE / BUILD CONSOLE").font(.system(size: 9, weight: .heavy, design: .monospaced))
                            Spacer()
                            Circle().fill(.green).frame(width: 6, height: 6)
                            Text("CLOUD TOOLCHAIN").font(.system(size: 9, design: .monospaced)).foregroundStyle(.green)
                        }
                        Text("Apple Swift and Xcode run on a macOS cloud runner. Build iOS apps as unsigned IPAs, or build and test Swift packages remotely.")
                            .font(.system(size: 10)).foregroundStyle(.gray).fixedSize(horizontal: false, vertical: true)
                        Link(destination: URL(string: "https://github.com/hush-paid01-hash/jubilant-computing-machine/actions/workflows/build-project.yml")!) {
                            HStack {
                                Image(systemName: "play.fill")
                                Text("BUILD / RUN PROJECT")
                                Spacer()
                                Image(systemName: "arrow.up.right")
                            }
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundStyle(.white).padding(11).background(Color.orange)
                            .clipShape(RoundedRectangle(cornerRadius: 7))
                        }
                    }
                    .padding(11).background(Color(red: 0.10, green: 0.11, blue: 0.13))
                }
            }
            .background(Color(red: 0.075, green: 0.085, blue: 0.10))
            .preferredColorScheme(.dark)
            .toolbar(.hidden, for: .navigationBar)
            .fileImporter(isPresented: $showImport, allowedContentTypes: [.swiftSource, .plainText, .sourceCode], allowsMultipleSelection: true) { result in
                switch result {
                case .success(let urls):
                    for url in urls {
                        let access = url.startAccessingSecurityScopedResource()
                        defer { if access { url.stopAccessingSecurityScopedResource() } }
                        if let text = try? String(contentsOf: url, encoding: .utf8) {
                            let name = url.lastPathComponent
                            if let index = files.firstIndex(where: { $0.id == name }) {
                                files[index] = WorkspaceFile(id: name, symbol: "swift", starter: text)
                            } else {
                                files.append(WorkspaceFile(id: name, symbol: name.hasSuffix(".swift") ? "swift" : "doc.text", starter: text))
                            }
                            selectedFile = name
                            source = text
                            UserDefaults.standard.set(text, forKey: storageKey(name))
                            importMessage = "Imported \(name)"
                        }
                    }
                case .failure(let error): importMessage = error.localizedDescription
                }
            }
            .sheet(isPresented: $showTools) {
                NavigationStack {
                    List {
                        Section("Editor") {
                            Label("Dark Xcode-inspired source editor", systemImage: "chevron.left.forwardslash.chevron.right")
                            Label("Import Swift and text source files from Files", systemImage: "folder")
                            Label("Local draft persistence and line numbering", systemImage: "externaldrive")
                        }
                        Section("Universal project build") {
                            Link("Open Universal GitHub Project Runner", destination: URL(string: "https://github.com/hush-paid01-hash/jubilant-computing-machine/actions/workflows/build-project.yml")!)
                            Text("Enter a public GitHub repository and branch. Choose Auto, iOS app, or Swift package. Xcode projects build for a generic iOS device and publish an unsigned IPA; Swift packages run swift test and a Release build, then publish the build output.")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                        Section("Compiler reality") {
                            Text("This iPhone editor cannot host Apple's macOS Xcode compiler locally or execute arbitrary iOS apps inside itself. Compilation and tests run remotely on a macOS runner through GitHub Actions. The runner supports public GitHub Xcode iOS projects and Swift packages. Imported source files remain local drafts and are not yet uploaded as a buildable project.")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                        Section("Import status") { Text(importMessage).font(.footnote) }
                    }
                    .navigationTitle("Developer Tools")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar { ToolbarItem(placement: .confirmationAction) { Button("Done") { showTools = false } } }
                }
            }
        }
        .onAppear {
            source = UserDefaults.standard.string(forKey: storageKey(selectedFile)) ?? source
        }
    }

    private func storageKey(_ name: String) -> String { "starterWorkspaceFile_" + name }
    private func saveCurrent() { UserDefaults.standard.set(source, forKey: storageKey(selectedFile)) }
}

private extension WorkspaceFile {
    static let defaultSource = """
import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "swift")
                .font(.system(size: 48))
                .foregroundStyle(.orange)
            Text("Hello, iOS Starter!")
                .font(.title.bold())
            Text("Edit this view and build it with Xcode.")
                .foregroundStyle(.secondary)
        }
        .padding()
    }
}
"""
    static let appSource = """
import SwiftUI

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup { ContentView() }
    }
}
"""
    static let readme = "# My iOS Project\n\nCreated with iOS Starter IDE."
}
