// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MicKeeper",
    platforms: [.macOS(.v13)],
    targets: [
        // Lógica pura (sem CoreAudio/AppKit): política, config e textos. Testável em qualquer SO.
        .target(name: "MicKeeperCore"),
        .executableTarget(name: "MicKeeper", dependencies: ["MicKeeperCore"]),
        .testTarget(name: "MicKeeperCoreTests", dependencies: ["MicKeeperCore"]),
    ]
)
