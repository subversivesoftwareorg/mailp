// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "Triage",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/sparkle-project/Sparkle", from: "2.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "Triage",
            dependencies: ["Sparkle"],
            path: "Triage",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "TriageTests",
            dependencies: ["Triage"],
            path: "TriageTests"
        ),
    ]
)
