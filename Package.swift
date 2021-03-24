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
		.library(
			name: "FirebirdNIO2",
			targets: ["FirebirdNIO2"]),
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
				.product(name: "Firebird", package: "firebird-lib"),
			]),
		.target(
			name: "FirebirdNIO2",
			dependencies: [
				.product(name: "AsyncKit", package: "async-kit"),
				.product(name: "Firebird", package: "firebird-lib"),
			]),
        .testTarget(
            name: "FirebirdNIOTests",
            dependencies: ["FirebirdNIO", "FirebirdNIO2"]),
    ]
)
