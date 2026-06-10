// swift-tools-version: 6.3

import PackageDescription

let package = Package(
    name: "MailPlus",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "MailPlus",
            path: "MailPlus",
            swiftSettings: [.swiftLanguageMode(.v5)]
        ),
        .testTarget(
            name: "MailPlusTests",
            dependencies: ["MailPlus"],
            path: "MailPlusTests"
        ),
    ]
)
