// swift-tools-version:6.2
// The app's ring logic with no Bluetooth and no UI, so it is tested on the Mac with
// swift test -Xswiftc -warnings-as-errors; the flag lives on the command because Xcode builds
// a package with warnings suppressed and refuses both at once.
import PackageDescription

let package = Package(
    name: "RingCore",
    platforms: [.iOS(.v18), .macOS(.v14)],
    products: [
        .library(name: "Faults", targets: ["Faults"]),
        .library(name: "RingCore", targets: ["RingCore"]),
    ],
    targets: [
        .target(name: "Faults"),
        .target(name: "RingCore", dependencies: ["Faults"]),
        .testTarget(name: "FaultsTests", dependencies: ["Faults"]),
        .testTarget(name: "RingCoreTests", dependencies: ["RingCore"]),
    ]
)
