# iOS Starter

A small native SwiftUI iOS app with a GitHub Actions workflow that builds an **unsigned IPA** on a GitHub-hosted macOS runner.

## Build from an iPhone

1. Open the **Actions** tab in this repository.
2. Select **Build iOS IPA**.
3. Tap **Run workflow** and confirm.
4. When the run finishes, open it and find **Artifacts**.
5. Download **IOSStarter-Unsigned-IPA**. On iPhone, the downloaded artifact may arrive as a ZIP; extract it in Files to get `IOSStarter-Unsigned.ipa`.
6. Open ESign and use its import/sign/install flow to sign the IPA with your own certificate and provisioning profile.

The workflow builds with Xcode on GitHub's macOS runner. Xcode itself does not run on the iPhone.

## Customize

- Edit `Sources/ContentView.swift` to change the app screen.
- Edit `Sources/IOSStarterApp.swift` for app-level behavior.
- Edit `project.yml` to change app settings.

## Signing note

The starter uses bundle identifier `com.example.iosstarter`. Your provisioning profile must authorize this exact App ID (or a matching wildcard profile). If it does not, change `PRODUCT_BUNDLE_IDENTIFIER` in `project.yml` to an App ID your profile supports before building.

This repository contains no signing certificate, private key, or provisioning profile. Never commit those secrets here.

The workflow creates an **unsigned** IPA; it does not sign or install the app automatically.
