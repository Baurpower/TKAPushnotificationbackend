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
    if let databaseURL = Environment.get("DATABASE_URL"), var postgresConfig = PostgresConfiguration(url: databaseURL) {
        // For Heroku or other environments that require TLS:
        postgresConfig.tlsConfiguration = .makeClientConfiguration()
        app.databases.use(.postgres(configuration: postgresConfig), as: .psql)
    } else {
        // Local database configuration
        app.databases.use(.postgres(
            hostname: "localhost",
            port: 5432,
            username: "myorthocompanion",
            password: "Becca123$",
            database: "MyorthocompanionTKAdatabase"
        ), as: .psql)
    }
    
    print("DATABASE_HOST:", Environment.get("DATABASE_HOST") ?? "not set")
    print("DATABASE_PORT:", Environment.get("DATABASE_PORT") ?? "not set")
    print("DATABASE_USERNAME:", Environment.get("DATABASE_USERNAME") ?? "not set")
    print("DATABASE_PASSWORD:", Environment.get("DATABASE_PASSWORD") ?? "not set")
    print("DATABASE_NAME:", Environment.get("DATABASE_NAME") ?? "not set")
    
    // MARK: - Migrations
    app.migrations.add(CreateDeviceRegistration())
    
    // Run the migrations automatically.
    try app.autoMigrate().wait()
    
    // MARK: - APNs Configuration
    do {
        // Use environment variables for secret configuration
        // or replace these with hard-coded values for local testing.
        let keyPath = Environment.get("APNS_KEY_PATH") ?? "/Users/alexbaur/Xcode/MyOrtho Companion TKA Database/AuthKey_D68DGZ8TBA.p8"
        let keyContents = try String(contentsOfFile: keyPath, encoding: .utf8)
        
        let keyId = Environment.get("APNS_KEY_ID") ?? "D68DGZ8TBA"
        let teamId = Environment.get("APNS_TEAM_ID") ?? "MLMGMULY2P"
        let topic = Environment.get("APNS_TOPIC") ?? "com.alexbaur.MyOrtho-Companion--Knee-Replacement"
        
        // Create APNs configuration using the JWT authentication method.
        let apnsConfig = try APNSwiftConfiguration(
            authenticationMethod: .jwt(
                key: .private(pem: keyContents),
                keyIdentifier: JWKIdentifier(string: keyId),
                teamIdentifier: teamId
            ),
            topic: topic,
            environment: .production // Switch to .production when you're ready for production.
        )
        
        // Store the APNs configuration for use throughout your app.
        app.storage[APNSConfigurationKey.self] = apnsConfig
        app.logger.info("APNs configuration loaded successfully.")
    } catch {
        app.logger.error("Failed to configure APNs: \(error.localizedDescription)")
    }
    
    // MARK: - Other Configurations & Routes
    try routes(app)
    
    // Schedule the inactive user notifications task.
    scheduleInactiveUserNotifications(app: app)
}

// Define a StorageKey for holding the APNs configuration in the application's storage.
struct APNSConfigurationKey: StorageKey {
    typealias Value = APNSwiftConfiguration
}

// Schedules a task to periodically check for inactive users.
func scheduleInactiveUserNotifications(app: Application) {
    // Schedule a task to run every 24 hours, with an initial delay of 10 seconds.
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
