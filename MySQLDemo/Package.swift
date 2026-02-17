// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "MySQLDemo",
    platforms: [.macOS(.v12)],
    dependencies: [
        .package(url: "https://github.com/vapor/vapor.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/mysql-kit.git", from: "4.0.0"),
        .package(url: "https://github.com/vapor/leaf.git", from: "4.0.0")
    ],
    targets: [
        .executableTarget(
            name: "MySQLDemo",
            dependencies: [
                .product(name: "Vapor", package: "vapor"),
                .product(name: "MySQLKit", package: "mysql-kit"),
                .product(name: "Leaf", package: "leaf")
            ],
            path: "Sources/MySQLDemo"
        )
    ]
)
