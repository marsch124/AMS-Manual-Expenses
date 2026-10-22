// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ExpenseCore",
    platforms: [.iOS(.v17), .macOS(.v13)],
    products: [.library(name: "ExpenseCore", targets: ["ExpenseCore"])],
    targets: [
        .target(name: "ExpenseCore"),
        .testTarget(name: "ExpenseCoreTests", dependencies: ["ExpenseCore"]),
    ]
)
