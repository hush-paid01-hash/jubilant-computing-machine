// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "RunnerSmokeTest",
    products: [
        .library(name: "RunnerSmokeTest", targets: ["RunnerSmokeTest"])
    ],
    targets: [
        .target(name: "RunnerSmokeTest"),
        .testTarget(name: "RunnerSmokeTestTests", dependencies: ["RunnerSmokeTest"])
    ]
)
