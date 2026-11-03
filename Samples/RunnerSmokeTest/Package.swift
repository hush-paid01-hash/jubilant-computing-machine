// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RunnerSmokeTest",
    products: [
        .executable(name: "RunnerSmokeTest", targets: ["RunnerSmokeTest"]),
        .library(name: "RunnerSmokeTestLibrary", targets: ["RunnerSmokeTestLibrary"])
    ],
    targets: [
        .executableTarget(name: "RunnerSmokeTest", path: "Sources/RunnerSmokeTest"),
        .target(name: "RunnerSmokeTestLibrary", path: "Sources/RunnerSmokeTestLibrary"),
        .testTarget(name: "RunnerSmokeTestTests", dependencies: ["RunnerSmokeTestLibrary"])
    ]
)
