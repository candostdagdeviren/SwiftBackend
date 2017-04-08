import PackageDescription

let package = Package(
    name: "SwiftBackend",
    targets: [
      Target(name: "SwiftBackendLib"),
      Target(name: "SwiftBackendApp", dependencies: ["SwiftBackendLib"])
    ],
    dependencies: [
        .Package(url: "https://github.com/IBM-Swift/Kitura.git", majorVersion: 1, minor: 4),
        .Package(url: "https://github.com/IBM-Swift/HeliumLogger.git", Version(1,6,1)),
        .Package(url: "https://github.com/IBM-Swift/Kitura-CouchDB.git", majorVersion: 1, minor: 4)
    ]
)
