import SwiftUI
import Security

struct GitHubFileEditorView: View {
    let repository: String
    let item: GitHubEditableFile

    @State private var source = ""
    @State private var commitMessage = ""
    @State private var originalSource = ""
    @State private var fileSHA: String?
    @State private var isLoading = true
    @State private var isSaving = false
    @State private var notice: String?
    @State private var isError = false

    var body: some View {
        VStack(spacing: 0) {
            if isLoading {
                ProgressView("Loading file…").frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                TextEditor(text: $source)
                    .font(.system(.footnote, design: .monospaced))
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .padding(.horizontal, 8)
                Divider()
                VStack(spacing: 10) {
                    TextField("Commit message", text: $commitMessage)
                        .textFieldStyle(.roundedBorder)
                    HStack {
                        if source != originalSource {
                            Text("Unsaved changes").font(.caption).foregroundStyle(.orange)
                        } else {
                            Text("No changes").font(.caption).foregroundStyle(.secondary)
                        }
                        Spacer()
                        Button {
                            Task { await save() }
                        } label: {
                            if isSaving { ProgressView() } else { Label("Commit changes", systemImage: "checkmark.circle.fill") }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(isSaving || source == originalSource || commitMessage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || fileSHA == nil)
                    }
                }
                .padding()
            }
        }
        .navigationTitle(item.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !isLoading {
                    Button("Reload") { Task { await load() } }.disabled(isSaving)
                }
            }
        }
        .alert(isPresented: Binding(get: { notice != nil }, set: { if !$0 { notice = nil } })) {
            Alert(title: Text(isError ? "GitHub error" : "Saved"), message: Text(notice ?? ""), dismissButton: .default(Text("OK")))
        }
        .task { await load() }
    }

    private func load() async {
        guard let token = GitHubEditorToken.read() else {
            isLoading = false
            isError = true
            notice = "Your GitHub session is missing. Sign out and connect again."
            return
        }
        do {
            let file: GitHubEditorContent = try await GitHubEditorAPI.request(repository: repository, path: item.path, token: token)
            guard file.encoding == "base64",
                  let data = Data(base64Encoded: file.content.replacingOccurrences(of: "\n", with: "")),
                  let decoded = String(data: data, encoding: .utf8) else {
                throw GitHubEditorError.unreadable
            }
            source = decoded
            originalSource = decoded
            fileSHA = file.sha
            commitMessage = "Update \(item.name)"
        } catch {
            isError = true
            notice = error.localizedDescription
        }
        isLoading = false
    }

    private func save() async {
        guard let token = GitHubEditorToken.read(), let fileSHA else { return }
        isSaving = true
        defer { isSaving = false }
        do {
            let newSHA = try await GitHubEditorAPI.commit(repository: repository, path: item.path, token: token,
                                                     sha: fileSHA, text: source,
                                                     message: commitMessage.trimmingCharacters(in: .whitespacesAndNewlines))
            self.fileSHA = newSHA
            originalSource = source
            isError = false
            notice = "Your changes were committed to the current GitHub branch."
        } catch {
            isError = true
            notice = error.localizedDescription
        }
    }
}

struct GitHubEditableFile {
    let name: String
    let path: String
}

private struct GitHubEditorContent: Decodable {
    let content: String
    let encoding: String
    let sha: String
}

private struct GitHubEditorCommitResponse: Decodable {
    let content: GitHubEditorCommittedContent?
}
private struct GitHubEditorCommittedContent: Decodable {
    let sha: String
}

private enum GitHubEditorAPI {
    static func endpoint(repository: String, path: String) throws -> URL {
        let safePath = path.split(separator: "/").map {
            String($0).addingPercentEncoding(withAllowedCharacters: .alphanumerics.union(CharacterSet(charactersIn: "-._~"))) ?? String($0)
        }.joined(separator: "/")
        guard let url = URL(string: "https://api.github.com/repos/\(repository)/contents/\(safePath)") else {
            throw GitHubEditorError.invalidURL
        }
        return url
    }

    static func request(repository: String, path: String, token: String) async throws -> GitHubEditorContent {
        let url = try endpoint(repository: repository, path: path)
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        authorize(&request, token: token)
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response, data: data)
        return try JSONDecoder().decode(GitHubEditorContent.self, from: data)
    }

    static func commit(repository: String, path: String, token: String, sha: String, text: String, message: String) async throws -> String {
        let url = try endpoint(repository: repository, path: path)
        var request = URLRequest(url: url)
        request.httpMethod = "PUT"
        authorize(&request, token: token)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let payload: [String: Any] = [
            "message": message,
            "content": Data(text.utf8).base64EncodedString(),
            "sha": sha
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response, data: data)
        let result = try JSONDecoder().decode(GitHubEditorCommitResponse.self, from: data)
        guard let newSHA = result.content?.sha else { throw GitHubEditorError.requestFailed }
        return newSHA
    }

    private static func authorize(_ request: inout URLRequest, token: String) {
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
    }

    private static func validate(_ response: URLResponse, data: Data) throws {
        guard let http = response as? HTTPURLResponse else { throw GitHubEditorError.requestFailed }
        guard (200..<300).contains(http.statusCode) else {
            let apiError = try? JSONDecoder().decode(GitHubEditorAPIError.self, from: data)
            throw GitHubEditorError.api(apiError?.message ?? "GitHub rejected the request (HTTP \(http.statusCode)).")
        }
    }
}

private struct GitHubEditorAPIError: Decodable { let message: String }

private struct GitHubEditorToken {
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

private enum GitHubEditorError: LocalizedError {
    case invalidURL, requestFailed, unreadable
    case api(String)
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "The GitHub file address is invalid."
        case .requestFailed: return "GitHub could not complete the request."
        case .unreadable: return "This file is not readable UTF-8 text."
        case .api(let message): return message
        }
    }
}
