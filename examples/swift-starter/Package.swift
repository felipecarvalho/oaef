// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SwiftStarter",
    products: [
        .library(name: "SwiftStarter", targets: ["SwiftStarter"]),
    ],
    targets: [
        .target(name: "SwiftStarter"),
        .testTarget(name: "SwiftStarterTests", dependencies: ["SwiftStarter"]),
    ]
)
