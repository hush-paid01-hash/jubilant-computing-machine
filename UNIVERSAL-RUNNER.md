# Universal Project Runner

The runner executes on GitHub's macOS 15 cloud runner. It does not compile on the iPhone itself.

## Start a run from iPhone

1. Open https://github.com/hush-paid01-hash/jubilant-computing-machine/actions/workflows/build-project.yml in Safari.
2. Sign in to the GitHub account that owns this repository.
3. If GitHub shows an **Enable workflow** button, tap it once.
4. Tap **Run workflow** and keep branch set to `main`.
5. Enter a public repository as `owner/repository`, choose its branch or tag, and leave Scheme blank for automatic detection when possible.
6. Choose **Auto** for automatic detection, **iOS** for an Xcode iOS app, or **Swift package** for a Swift Package Manager project.
7. Tap the green **Run workflow** button in the dropdown.
8. Open the new run. When it finishes, open **Artifacts** to download the unsigned IPA or Swift package build output.

## Supported inputs

- Public GitHub repositories only. Private repositories are not supported by this workflow.
- iOS app builds require an Xcode `.xcodeproj` or `.xcworkspace` with a shared build scheme.
- Swift package builds require `Package.swift` and run `swift test` followed by a Release build.
- Imported files stored only inside the iOS Starter app are not uploaded to this workflow yet.
- The iOS IPA is unsigned. ESign or another compatible signing method is needed before installation.

## If Run workflow is missing

Confirm the workflow file exists on the repository's default branch under `.github/workflows/build-project.yml`, then refresh the Actions page. GitHub may show **Enable workflow** before showing **Run workflow**. If Actions are disabled by repository settings, enable Actions in the repository's Actions settings.
