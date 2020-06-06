// swift-tools-version:5.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "Patterns",
	products: [
		// Products define the executables and libraries produced by a package, and make them visible to other packages.
		.library(
			name: "Patterns",
			targets: ["Patterns"]),
		.executable(
			name: "unicode_properties",
			targets: ["unicode_properties", "Patterns"]),
	],
	dependencies: [.package(url: "https://github.com/apple/swift-argument-parser", from: "0.0.1")],
	targets: [
		// Targets are the basic building blocks of a package. A target can define a module or a test suite.
		// Targets can depend on other targets in this package, and on products in packages which this package depends on.
		.target(
			name: "Patterns",
			dependencies: [],
			swiftSettings: [
				.define("DEBUG", .when(configuration: .debug)),
				//.define("SwiftEngine"),
			]),
		.testTarget(
			name: "PatternsTests",
			dependencies: ["Patterns"],
			swiftSettings: [
				.unsafeFlags(["-Xfrontend", "-warn-long-expression-type-checking=1000",
				              "-Xfrontend", "-warn-long-function-bodies=1000"]),
			]),
		.testTarget(
			name: "PerformanceTests",
			dependencies: ["Patterns"],
			swiftSettings: [
				.define("DEBUG", .when(configuration: .debug)),
			]),
		.target(
			name: "unicode_properties",
			dependencies: ["Patterns", "ArgumentParser"]),
	])
