// swift-tools-version: 6.2
import PackageDescription

// Pure Swift, Foundation only. No Apple frameworks, so it builds and tests on
// Windows and Linux as well as on iOS and watchOS.
let package = Package(
    name: "GoodMorningCore",
    platforms: [.iOS(.v26), .watchOS(.v26), .macOS(.v14)],
    products: [
        .library(name: "GoodMorningCore", targets: ["GoodMorningCore"])
    ],
    targets: [
        .target(name: "GoodMorningCore"),
        .testTarget(name: "GoodMorningCoreTests", dependencies: ["GoodMorningCore"]),
    ]
)
