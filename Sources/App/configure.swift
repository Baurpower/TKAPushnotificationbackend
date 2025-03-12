import NIOSSL
import Fluent
import FluentPostgresDriver
import Vapor

public func configure(_ app: Application) throws {
    // Configure your PostgreSQL database:
    if let databaseURL = Environment.get("DATABASE_URL"), var postgresConfig = PostgresConfiguration(url: databaseURL) {
        // For Heroku or other environments that require TLS:
        postgresConfig.tlsConfiguration = .makeClientConfiguration()
        app.databases.use(.postgres(configuration: postgresConfig), as: .psql)
    } else {
        // Local database configuration
        app.databases.use(.postgres(
            hostname: Environment.get("DATABASE_HOST") ?? "localhost",
            port: Environment.get("DATABASE_PORT").flatMap(Int.init(_:)) ?? PostgresConfiguration.ianaPortNumber,
            username: Environment.get("DATABASE_USERNAME") ?? "myorthocompanion",
            password: Environment.get("DATABASE_PASSWORD") ?? "Becca123$",
            database: Environment.get("DATABASE_NAME") ?? "MyorthocompanionTKAdatabase"
        ), as: .psql)
    }
    print("DATABASE_HOST:", Environment.get("DATABASE_HOST") ?? "not set")
    print("DATABASE_PORT:", Environment.get("DATABASE_PORT") ?? "not set")
    print("DATABASE_USERNAME:", Environment.get("DATABASE_USERNAME") ?? "not set")
    print("DATABASE_PASSWORD:", Environment.get("DATABASE_PASSWORD") ?? "not set")
    print("DATABASE_NAME:", Environment.get("DATABASE_NAME") ?? "not set")

    // Register migrations (we'll add a sample migration below)
    app.migrations.add(CreateDeviceRegistration())

    // Other configurations...
    try routes(app)
}
