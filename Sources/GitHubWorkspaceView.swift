import SwiftUI
import Security

// GitHub OAuth Device Flow scaffold. Add the OAuth App Client ID in this screen
// after creating the OAuth App and enabling Device Flow. No client secret belongs
// in an iOS app. Access tokens are stored in the iOS Keychain.
struct GitHubWorkspaceView: View {
    @StateObject private var model = GitHubWorkspaceModel()
    @AppStorage("githubOAuthClientID") private var clientID = ""
    @State private var showingSetup = false

    var body: some View {
        NavigationStack {
            Group {
                if model.isSignedIn {
                    repositoryList
                } else {
                    signInView
                }
            }
            .navigationTitle("GitHub")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if model.isSignedIn {
                        Button("Sign out", role: .destructive) { model.signOut() }
                    } else {
                        Button { showingSetup = true } label: { Image(systemName: "gearshape") }
                            .accessibilityLabel("GitHub setup")
                    }
                }
            }
            .sheet(isPresented: $showingSetup) {
                NavigationStack {
                    Form {
                        Section("OAuth configuration") {
                            TextField("GitHub OAuth App Client ID", text: $clientID)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                            Text("Create a GitHub OAuth App, enable Device Flow, then enter its Client ID here. Do not add a client secret or personal access token to the app.")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                        Section("Security") {
                            Label("OAuth access token is stored in iOS Keychain", systemImage: "lock.shield")
                            Label("Repository access is requested only after GitHub authorization", systemImage: "checkmark.shield")
                        }
                    }
                    .navigationTitle("GitHub Setup")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showingSetup = false }
                        }
                    }
                }
            }
            .task { await model.restoreSession() }
        }
    }

    private var signInView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Image(systemName: "chevron.left.forwardslash.chevron.right")
                    .font(.system(size: 42, weight: .bold)).foregroundStyle(.orange)
                    .frame(maxWidth: .infinity, alignment: .center).padding(.top, 24)
                Text("Your repositories, in your workspace")
                    .font(.title.bold())
                Text("Connect GitHub to browse your repositories and, in the next stage, edit files and manage commits without leaving this app.")
                    .foregroundStyle(.secondary)
                if model.deviceCode != nil {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Enter this one-time code on GitHub").font(.headline)
                        Text(model.userCode)
                            .font(.system(size: 30, weight: .bold, design: .monospaced))
                            .frame(maxWidth: .infinity).padding()
                            .background(Color(uiColor: .secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .textSelection(.enabled)
                        Link("Open GitHub device authorization", destination: URL(string: model.verificationURI)!)
                            .font(.headline)
                        Text("Keep this screen open while you approve the request. The code expires.")
                            .font(.footnote).foregroundStyle(.secondary)
                        Button("Cancel authorization", role: .destructive) { model.cancelAuthorization() }
                    }
                    .padding().background(Color(uiColor: .secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                } else {
                    Button {
                        Task { await model.beginAuthorization(clientID: clientID) }
                    } label: {
                        Label("Continue with GitHub", systemImage: "person.crop.circle.badge.checkmark")
                            .font(.headline).frame(maxWidth: .infinity).padding()
                            .background(Color.orange).foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(clientID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || model.isLoading)
                    Button("Configure OAuth Client ID") { showingSetup = true }
                        .frame(maxWidth: .infinity)
                    Text("GitHub sign-in is prepared but needs your OAuth App Client ID before it can connect.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                if model.isLoading { ProgressView("Connecting securely…") }
                if let message = model.message {
                    Text(message).font(.footnote).foregroundStyle(.secondary)
                }
            }
            .padding(20)
        }
    }

    private var repositoryList: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    AsyncAvatarView(url: model.avatarURL)
                    VStack(alignment: .leading, spacing: 3) {
                        Text(model.username).font(.headline)
                        Text("Connected to GitHub").font(.caption).foregroundStyle(.secondary)
                    }
                    Spacer()
                    Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
                }
                .padding(.vertical, 5)
            }
            Section("Repositories") {
                if model.repositories.isEmpty && model.isLoading {
                    ProgressView("Loading repositories…")
                } else if model.repositories.isEmpty {
                    Text("No repositories loaded. Pull to refresh or check your connection.").foregroundStyle(.secondary)
                } else {
                    ForEach(model.repositories) { repo in
                        NavigationLink {
                            GitHubRepositoryBrowserView(repository: repo.fullName)
                        } label: {
                        VStack(alignment: .leading, spacing: 5) {
                            HStack {
                                Text(repo.fullName).font(.headline)
                                Spacer()
                                Image(systemName: repo.isPrivate ? "lock.fill" : "globe")
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            if let description = repo.description, !description.isEmpty {
                                Text(description).font(.caption).foregroundStyle(.secondary).lineLimit(2)
                            }
                            HStack(spacing: 14) {
                                Label("\(repo.stars)", systemImage: "star")
                                Label(repo.language ?? "Unknown", systemImage: "chevron.left.forwardslash.chevron.right")
                                Text("Updated \(repo.updatedAt.formatted(date: .abbreviated, time: .omitted))")
                            }
                            .font(.caption2).foregroundStyle(.secondary)
                            Link("Open on GitHub", destination: repo.htmlUrl)
                                .font(.caption.weight(.semibold))
                        }
                        .padding(.vertical, 5)
                        }
                    }
                }
            }
            Section {
                Button { Task { await model.loadRepositories() } } label: {
                    Label("Refresh repositories", systemImage: "arrow.clockwise")
                }
                if let message = model.message {
                    Text(message).font(.footnote).foregroundStyle(.secondary)
                }
            }
        }
        .refreshable { await model.loadRepositories() }
    }
}

private struct AsyncAvatarView: View {
    let url: URL?
    var body: some View {
        Group {
            if let url {
                AsyncImage(url: url) { image in image.resizable().scaledToFill() } placeholder: {
                    Image(systemName: "person.crop.circle.fill").resizable().foregroundStyle(.secondary)
                }
            } else {
                Image(systemName: "person.crop.circle.fill").resizable().foregroundStyle(.secondary)
            }
        }
        .frame(width: 42, height: 42).clipShape(Circle())
    }
}

@MainActor
private final class GitHubWorkspaceModel: ObservableObject {
    @Published var isSignedIn = false
    @Published var isLoading = false
    @Published var message: String?
    @Published var username = ""
    @Published var avatarURL: URL?
    @Published var repositories: [GitHubRepository] = []
    @Published var deviceCode: String?
    @Published var userCode = ""
    @Published var verificationURI = "https://github.com/login/device"

    private let keychain = GitHubTokenStore()
    private var authorizationTask: Task<Void, Never>?

    func restoreSession() async {
        guard let token = keychain.read() else { return }
        do {
            let user: GitHubUser = try await GitHubAPI.get("/user", token: token)
            username = user.login
            avatarURL = URL(string: user.avatarUrl)
            isSignedIn = true
            await loadRepositories()
        } catch {
            keychain.delete()
            message = "Your saved GitHub session expired. Please sign in again."
        }
    }

    func beginAuthorization(clientID: String) async {
        guard !clientID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            message = "Add your GitHub OAuth App Client ID in setup first."
            return
        }
        isLoading = true
        message = nil
        do {
            let request = try GitHubAPI.formRequest(
                "https://github.com/login/device/code",
                values: ["client_id": clientID, "scope": "repo read:user"]
            )
            let response: DeviceCodeResponse = try await GitHubAPI.send(request)
            deviceCode = response.deviceCode
            userCode = response.userCode
            verificationURI = response.verificationUri
            authorizationTask = Task { await pollForAuthorization(clientID: clientID, response: response) }
        } catch {
            message = "Could not start GitHub authorization: \(error.localizedDescription)"
        }
        isLoading = false
    }

    private func pollForAuthorization(clientID: String, response: DeviceCodeResponse) async {
        var delay = max(response.interval, 5)
        let deadline = Date().addingTimeInterval(TimeInterval(response.expiresIn))
        while !Task.isCancelled && Date() < deadline {
            do {
                try await Task.sleep(nanoseconds: UInt64(delay) * 1_000_000_000)
                let request = try GitHubAPI.formRequest(
                    "https://github.com/login/oauth/access_token",
                    values: ["client_id": clientID, "device_code": response.deviceCode, "grant_type": "urn:ietf:params:oauth:grant-type:device_code"]
                )
                let result: DeviceTokenResponse = try await GitHubAPI.send(request)
                if let token = result.accessToken {
                    keychain.save(token)
                    let user: GitHubUser = try await GitHubAPI.get("/user", token: token)
                    username = user.login
                    avatarURL = URL(string: user.avatarUrl)
                    isSignedIn = true
                    deviceCode = nil
                    message = "GitHub connected successfully."
                    await loadRepositories()
                    return
                }
                switch result.error {
                case "authorization_pending": continue
                case "slow_down": delay += 5
                case "access_denied":
                    message = "GitHub authorization was denied."
                    deviceCode = nil
                    return
                case "expired_token":
                    message = "The one-time code expired. Start again to get a new code."
                    deviceCode = nil
                    return
                default:
                    message = result.errorDescription ?? "GitHub authorization could not be completed."
                    deviceCode = nil
                    return
                }
            } catch is CancellationError {
                return
            } catch {
                message = "GitHub sign-in failed: \(error.localizedDescription)"
                deviceCode = nil
                return
            }
        }
        if !Task.isCancelled {
            message = "The one-time code expired. Start again to get a new code."
            deviceCode = nil
        }
    }

    func cancelAuthorization() {
        authorizationTask?.cancel()
        authorizationTask = nil
        deviceCode = nil
        message = "Authorization cancelled."
    }

    func loadRepositories() async {
        guard let token = keychain.read() else { return }
        isLoading = true
        defer { isLoading = false }
        do {
            repositories = try await GitHubAPI.get("/user/repos?sort=updated&per_page=100&affiliation=owner,collaborator,organization_member", token: token)
            message = "Loaded \(repositories.count) repositories."
        } catch {
            message = "Could not load repositories: \(error.localizedDescription)"
        }
    }

    func signOut() {
        authorizationTask?.cancel()
        keychain.delete()
        isSignedIn = false
        username = ""
        avatarURL = nil
        repositories = []
        message = "Signed out of GitHub."
    }
}

private enum GitHubAPI {
    static func formRequest(_ address: String, values: [String: String]) throws -> URLRequest {
        guard let url = URL(string: address) else { throw GitHubAPIError.invalidURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        var components = URLComponents()
        components.queryItems = values.map { URLQueryItem(name: $0.key, value: $0.value) }
        request.httpBody = components.percentEncodedQuery?.data(using: .utf8)
        return request
    }

    static func get<T: Decodable>(_ path: String, token: String) async throws -> T {
        guard let url = URL(string: "https://api.github.com" + path) else { throw GitHubAPIError.invalidURL }
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        request.setValue("2022-11-28", forHTTPHeaderField: "X-GitHub-Api-Version")
        return try await send(request)
    }

    static func send<T: Decodable>(_ request: URLRequest) async throws -> T {
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            throw GitHubAPIError.serverResponse
        }
        return try JSONDecoder.github.decode(T.self, from: data)
    }
}

private extension JSONDecoder {
    static var github: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

private struct DeviceCodeResponse: Decodable {
    let deviceCode: String
    let userCode: String
    let verificationUri: String
    let expiresIn: Int
    let interval: Int
}

private struct DeviceTokenResponse: Decodable {
    let accessToken: String?
    let error: String?
    let errorDescription: String?
}

private struct GitHubUser: Decodable {
    let login: String
    let avatarUrl: String
}

private struct GitHubRepository: Decodable, Identifiable {
    let id: Int
    let name: String
    let fullName: String
    let isPrivate: Bool
    let htmlUrl: URL
    let description: String?
    let stargazersCount: Int
    let language: String?
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id, name, fullName, isPrivate = "private", htmlUrl, description, stargazersCount, language, updatedAt
    }

    var stars: Int { stargazersCount }
    var descriptionText: String { description ?? "" }
}

private struct GitHubTokenStore {
    private let service = "com.example.iosstarter.github"
    private let account = "oauth-access-token"

    func save(_ token: String) {
        delete()
        let data = Data(token.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        SecItemAdd(query as CFDictionary, nil)
    }

    func read() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func delete() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]
        SecItemDelete(query as CFDictionary)
    }
}

private enum GitHubAPIError: LocalizedError {
    case invalidURL
    case serverResponse

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "The GitHub endpoint is invalid."
        case .serverResponse: return "GitHub returned an unsuccessful response. Check OAuth setup and repository permissions."
        }
    }
}
