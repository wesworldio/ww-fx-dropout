// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "WesWorldFX",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "WesWorldFX", targets: ["WesWorldFX"])
    ],
    targets: [
        .executableTarget(
            name: "WesWorldFX",
            path: "WesWorldFX/Sources",
            resources: [
                .process("../Resources"),
                .process("../Metal/Shaders.metal")
            ]
        )
    ]
)
