// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "firebird-nio",
	platforms: [
		.macOS(.v10_15),
	],
    products: [
        .library(
            name: "FirebirdNIO",
            targets: ["FirebirdNIO"]),
    ],
    dependencies: [
		.package(url: "https://github.com/Jawtoch/firebird-lib.git", from: "0.0.0"),
		.package(url: "https://github.com/vapor/async-kit.git", from: "1.0.0"),
	],
    targets: [
        .target(
            name: "FirebirdNIO",
            dependencies: [
				.product(name: "AsyncKit", package: "async-kit"),
				.product(name: "CFirebird", package: "firebird-lib"),
			],
			linkerSettings: [
				.unsafeFlags(["-F", "/Library/Frameworks"]),
				.linkedFramework("Firebird"),
			]),
        .testTarget(
            name: "firebird-nioTests",
            dependencies: ["FirebirdNIO"]),
    ]
)
