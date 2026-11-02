# iOS Starter

A native SwiftUI iPhone app workspace with a cloud Xcode build workflow.

## Features

- Home dashboard and reusable SwiftUI component examples.
- **My Projects:** create, search, edit, track, and delete project records. Project records are stored locally on the iPhone.
- Dark mode and notification preference toggles.
- Custom orange app icon generated from `Assets/AppIcon.svg` during the build.
- GitHub Actions macOS workflow to build an unsigned iOS IPA.

## Build from an iPhone

1. Open the **Actions** tab.
2. Select **Build iOS IPA**.
3. Tap **Run workflow**.
4. When the run succeeds, download the `IOSStarter-Unsigned-IPA` artifact.
5. Extract the downloaded ZIP in Files and import the IPA into ESign.

The workflow uses Xcode on a GitHub-hosted macOS runner. Xcode itself does not run on iPhone.

## My Projects scope

My Projects is a local project organizer. It saves names, project types, bundle identifiers, statuses, and notes on the device. Creating a project entry does **not** automatically create a GitHub repository, a separate Xcode target, or a new IPA build. Those integrations can be added separately.

## Signing

The app uses bundle identifier `com.example.iosstarter`. Your ESign provisioning profile must authorize this App ID or a matching wildcard. The workflow produces an unsigned IPA; ESign performs signing on your device.

Never commit certificates, private keys, or provisioning profiles to this repository.
