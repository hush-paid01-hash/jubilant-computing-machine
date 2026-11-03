import SwiftUI
import Security

// Read-only repository browser. Uses the same Keychain token created by GitHubWorkspaceView.
struct GitHubRepositoryBrowserView: View {
    let repository: String
    let path: String
    @State private var items: [GitHubContentItem] = []
    @State private var isLoading = false
    @State private var errorMessage: String?

    init(repository: String, path: String = "") {
        self.repository = repository
        self.path = path
    }

    var body: some View {
        Group {
            if isLoading && items.isEmpty {
                ProgressView("Loading files…")
            } else if let errorMessage, items.isEmpty {
                VStack(spacing: 8) { Image(systemName: "exclamationmark.triangle"); Text("Could not load repository"); Text(errorMessage).font(.footnote).foregroundStyle(.secondary) }.padding()
            } else {
                List(items) { item in
                    if item.type == "dir" {
                        NavigationLink {
                            GitHubRepositoryBrowserView(repository: repository, path: item.path)
                        } label: {
                            Label(item.name, systemImage: "folder")
                        }
                    } else {
                        NavigationLink {
                            GitHubFilePreviewView(repository: repository, item: item)
                        } label: {
                            HStack {
                                Label(item.name, systemImage: item.isTextFile ? "doc.text" : "doc")
                                Spacer()
                                Text(ByteCountFormatter.string(fromByteCount: Int64(item.size), countStyle: .file))
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
                .overlay {
                    if items.isEmpty && !isLoading {
                        Text("This folder is empty.").foregroundStyle(.secondary)
                    }
                }
                .refreshable { await load() }
            }
        }
        .navigationTitle(path.isEmpty ? repository.components(separatedBy: "/").last ?? repository : path.components(separatedBy: "/").last ?? "Files")
        .navigationBarTitleDisplayMode(.inline)
        .task { if items.isEmpty { await load() } }
    }

    private func load() async {
        guard let token = GitHubBrowserToken.read() else {
            errorMessage = "Your GitHub session is missing. Sign out and connect again."
            return
        }
        isLoading = true
        defer { isLoading = false }
        do {
            var suffix = ""
            if !path.isEmpty {
                let encodedParts: [String] = path.split(separator: "/").map { part in
                    let text = String(part)
                    return text.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? text
                }
                suffix = "/" + encodedParts.joined(separator: "/")
            }
            let address = "https://api.github.com/repos/\(repository)/contents\(suffix)"
            let fetched: [GitHubContentItem] = try await GitHubBrowserAPI.get(address, token: token)
            let visible = fetched.filter { $0.type == "dir" || $0.type == "file" }
            items = visible.sorted { (lhs: GitHubContentItem, rhs: GitHubContentItem) -> Bool in
                let lhsIsDir = lhs.type == "dir"
                let rhsIsDir = rhs.type == "dir"
                if lhsIsDir != rhsIsDir { return lhsIsDir }
                return lhs.name.localizedCaseInsensitiveCompare(rhs.name) == .orderedAscending
            }
            errorMessage = nil
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

private struct GitHubFilePreviewView: View {
    let repository: String
    let item: GitHubContentItem
    @State private var text = ""
    @State private var loading = true
    @State private var errorMessage: String?

    var body: some View {
        Group {
            if loading {
                ProgressView("Loading file…")
            } else if let errorMessage {
                VStack(spacing: 8) { Image(systemName: "doc.questionmark"); Text("Unable to display file"); Text(errorMessage).font(.footnote).foregroundStyle(.secondary) }.padding()
            } else {
                ScrollView([.horizontal, .vertical]) {
                    Text(text)
                        .font(.system(.footnote, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
        }
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .task { await load() }
    }

    private func load() async {
        guard item.isTextFile, item.size <= 500_000 else {
            errorMessage = "This file is binary or too large for the in-app preview."
            loading = false
            return
        }
        guard let token = GitHubBrowserToken.read() else {
            errorMessage = "Your GitHub session is missing. Sign out and connect again."
            loading = false
            return
        }
        do {
            let encoded: GitHubEncodedContent = try await GitHubBrowserAPI.get("https://api.github.com/repos/\(repository)/contents/\(item.path.split(separator: "/").map { $0.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? String($0) }.joined(separator: "/"))", token: token)
            guard let data = Data(base64Encoded: encoded.content.replacingOccurrences(of: "\n", with: "")),
                  let decoded = String(data: data, encoding: .utf8) else {
                throw GitHubBrowserError.unreadable
            }
            text = decoded
        } catch {
            errorMessage = error.localizedDescription
        }
        loading = false
    }
}

private struct GitHubContentItem: Decodable, Identifiable {
    let name: String
    let path: String
    let type: String
    let size: Int
    var id: String { path }
    var isTextFile: Bool {
        let ext = (name as NSString).pathExtension.lowercased()
        return ["swift", "md", "txt", "json", "yml", "yaml", "plist", "xml", "html", "css", "js", "ts", "c", "h", "cpp", "hpp", "m", "mm", "sh", "py", "rb", "toml", "gitignore"].contains(ext) || name == "Dockerfile" || name == "Makefile"
    }
}

private struct GitHubEncodedContent: Decodable {
    let content: String
    let encoding: String
}

private enum GitHubBrowserAPI {
    static func get<T: Decodable>(_ address: String, token: String) async throws -> T {
        guard let url = URL(string: address) else { throw GitHubBrowserError.invalidURL }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw GitHubBrowserError.requestFailed
        }
        return try JSONDecoder().decode(T.self, from: data)
    }
}

private struct GitHubBrowserToken {
    static func read() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.example.iosstarter.github",
            kSecAttrAccount as String: "oauth-access-token",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

private enum GitHubBrowserError: LocalizedError {
    case invalidURL, requestFailed, unreadable
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "The GitHub file address is invalid."
        case .requestFailed: return "GitHub could not return this file. Check repository permissions and try again."
        case .unreadable: return "GitHub returned content that could not be decoded as text."
        }
    }
}
