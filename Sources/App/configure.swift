import NIOSSL
import Fluent
import FluentPostgresDriver
import Vapor
import APNS
import JWTKit

public func configure(_ app: Application) throws {
    app.http.server.configuration.hostname = "0.0.0.0"
    app.http.server.configuration.port = 8080

    // MARK: - Database Configuration
    guard let host = Environment.get("DATABASE_HOST"),
          let portString = Environment.get("DATABASE_PORT"), let port = Int(portString),
          let username = Environment.get("DATABASE_USERNAME"),
          let password = Environment.get("DATABASE_PASSWORD"),
          let dbname = Environment.get("DATABASE_NAME") else {
        fatalError("❌ Missing one or more required database environment variables.")
    }

    let postgresConfig = PostgresConfiguration(
        hostname: host,
        port: port,
        username: username,
        password: password,
        database: dbname,
        tlsConfiguration: .makeClientConfiguration()
    )

    app.databases.use(.postgres(configuration: postgresConfig), as: .psql)

    app.logger.info("✅ Connected to database: \(dbname) at \(host):\(port)")

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
        app.logger.info("✅ APNs configuration loaded successfully.")
    } catch {
        app.logger.error("❌ Failed to configure APNs: \(error.localizedDescription)")
    }

    // MARK: - Routes & Scheduled Tasks
    try routes(app)
    scheduleInactiveUserNotifications(app: app)
}

// MARK: - Storage Key for APNs
struct APNSConfigurationKey: StorageKey {
    typealias Value = APNSwiftConfiguration
}

// MARK: - Scheduled Notification Task
func scheduleInactiveUserNotifications(app: Application) {
    app.eventLoopGroup.next().scheduleRepeatedTask(initialDelay: .seconds(10), delay: .hours(24)) { task in
        Task {
            do {
                try await checkAndSendInactiveUserNotifications(app: app)
            } catch {
                app.logger.error("❌ Error during inactive notification check: \(error)")
            }
        }
    }
    app.logger.info("📆 Scheduled inactive user notification check.")
}
