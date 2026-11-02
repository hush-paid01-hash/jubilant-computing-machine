import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 18) {
                Image(systemName: "swift")
                    .font(.system(size: 56))
                    .foregroundStyle(.orange)
                Text("Your iOS app starts here")
                    .font(.title2.bold())
                Text("Edit Sources/ContentView.swift to begin building your own app.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                Label("Built with SwiftUI", systemImage: "hammer.fill")
                    .font(.footnote)
                    .padding(.top, 8)
            }
            .padding()
            .navigationTitle("iOS Starter")
        }
    }
}
