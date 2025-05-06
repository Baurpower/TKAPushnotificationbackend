import NIOSSL
import Fluent
import FluentPostgresDriver
import Vapor
import APNS
import JWTKit

public func configure(_ app: Application) throws {
    app.http.server.configuration.hostname = "0.0.0.0"
    app.http.server.configuration.port = 8080

    // MARK: - TLS Configuration with RDS Certificate
    let certPath = "/home/ubuntu/TKAPushnotificationbackend/global-bundle.pem"
    let tlsConfig = try! NIOSSLSocketTLSConfiguration.forClient(
        certificateVerification: .fullVerification,
        trustRoots: .file(certPath)
    )

    // MARK: - Database Configuration (RDS Only)
    app.databases.use(.postgres(
        configuration: PostgresConfiguration(
            hostname: "myorthocompanionknee-db.ct8ays8wi7r9.us-east-2.rds.amazonaws.com",
            port: 5432,
            username: "postgres",
            password: "Myortho2025$",
            database: "myorthocompanionknee",
            tlsConfiguration: tlsConfig
        )
    ), as: .psql)

    print("✅ Connected to database with TLS verification")

    // MARK: - Migrations
    app.migrations.add(CreateDeviceRegistration())
    try app.autoMigrate().wait()

    // MARK: - APNs Configuration
    do {
        let keyPath = Environment.get("APNS_KEY_PATH") ?? "/Users/alexbaur/Xcode/MyOrtho Companion TKA Database/AuthKey_D68DGZ8TBA.p8"
        let keyContents = try String(contentsOfFile: keyPath, encoding: .utf8)

        let keyId = Environment.get("APNS_KEY_ID") ?? "D68DGZ8TBA"
        let teamId = Environment.get("APNS_TEAM_ID") ?? "MLMGMULY2P"
        let topic = Environment.get("APNS_TOPIC") ?? "com.alexbaur.MyOrtho-Companion--Knee-Replacement"

        let apnsConfig = try APNSwiftConfiguration(
            authenticationMethod: .jwt(
                key: .private(pem: keyContents),
                keyIdentifier: JWKIdentifier(string: keyId),
                teamIdentifier: teamId
            ),
            topic: topic,
            environment: .production
        )

        app.storage[APNSConfigurationKey.self] = apnsConfig
        app.logger.info("APNs configuration loaded successfully.")
    } catch {
        app.logger.error("Failed to configure APNs: \(error.localizedDescription)")
    }

    try routes(app)
    scheduleInactiveUserNotifications(app: app)
}

struct APNSConfigurationKey: StorageKey {
    typealias Value = APNSwiftConfiguration
}

func scheduleInactiveUserNotifications(app: Application) {
    app.eventLoopGroup.next().scheduleRepeatedTask(initialDelay: .seconds(10), delay: .hours(24)) { task in
        Task {
            do {
                try await checkAndSendInactiveUserNotifications(app: app)
            } catch {
                app.logger.error("Error during inactive notification check: \(error)")
            }
        }
    }
    app.logger.info("Scheduled inactive user notification check.")
}
