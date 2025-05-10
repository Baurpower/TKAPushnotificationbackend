import Fluent
import Vapor
import APNS

// MARK: - Push Payload

struct SimplePushPayload: APNSwiftNotification {
    let aps: APNSwiftPayload
    var apnsID: UUID? = nil
    var expiration: Date? = nil
    var priority: Int? = nil
    var topic: String? = nil
    var collapseIdentifier: String? = nil
}

// MARK: - Registration Input Structure

struct RegisterTokenInput: Content {
    let token: String
    let latitude: Double?
    let longitude: Double?
}

// MARK: - Routes

func routes(_ app: Application) throws {
    
    // Register device token (used by iOS app)
    app.post("register") { req -> EventLoopFuture<HTTPStatus> in
        do {
            let input = try req.content.decode(RegisterTokenInput.self)
            let cleanToken = input.token.trimmingCharacters(in: .whitespacesAndNewlines)
            req.logger.info("📲 Incoming token: \(cleanToken)")

            return DeviceRegistration.query(on: req.db)
                .filter(\.$deviceToken == cleanToken)
                .first()
                .flatMap { existing in
                    if let existing = existing {
                        existing.lastOpenedAt = Date()
                        req.logger.info("🔄 Token exists, updating timestamp")
                        return existing.save(on: req.db).transform(to: .ok)
                    } else {
                        req.logger.info("🆕 New token, saving to DB")
                        let new = DeviceRegistration(deviceToken: cleanToken, lastOpenedAt: Date())
                        return new.save(on: req.db).transform(to: .created)
                    }
                }
        } catch {
            req.logger.error("❌ Failed to decode token: \(error)")
            return req.eventLoop.makeSucceededFuture(.badRequest)
        }
    }



    
    // Get all registered devices (for dev)
    app.get("registrations") { req -> EventLoopFuture<[DeviceRegistration]> in
        DeviceRegistration.query(on: req.db).all()
    }
    
    // Broadcast to ALL devices
    app.post("notify-all") { req -> EventLoopFuture<String> in
        guard let apnsConfig = req.application.storage[APNSConfigurationKey.self] else {
            return req.eventLoop.makeFailedFuture(Abort(.internalServerError, reason: "Missing APNs config"))
        }

        return DeviceRegistration.query(on: req.db).all().flatMapEachCompact(on: req.eventLoop) { device in
            guard !device.deviceToken.isEmpty else {
                return req.eventLoop.makeSucceededFuture(nil)
            }

            let alert = APNSwiftAlert(
                title: "📢 New SnapOrtho Beta Update!",
                body: "Thanks for testing! Let us know your thoughts 🙏"
            )

            let payload = SimplePushPayload(
                aps: APNSwiftPayload(
                    alert: alert,
                    badge: 1,
                    sound: .normal("default")
                )
            )
        

            return APNSwiftConnection.connect(configuration: apnsConfig, on: req.eventLoop).flatMap { client in
                client.send(payload, to: device.deviceToken)
                    .map { "✅ Sent to \(device.deviceToken)" }
                    .flatMapError { error in
                        req.logger.error("❌ Failed to send to \(device.deviceToken): \(error)")
                        return req.eventLoop.makeSucceededFuture("❌ Failed to send to \(device.deviceToken)")
                    }
            }
        }
        .map { $0.joined(separator: "\n") }
    }
    // ✅ Add this **inside** routes(_:)
     app.delete("delete-fake-token") { req -> EventLoopFuture<HTTPStatus> in
         DeviceRegistration.query(on: req.db)
             .filter(\.$deviceToken == "your_device_token_here")
             .delete()
             .transform(to: .ok)
     }
 }


func checkAndSendInactiveUserNotifications(app: Application) async throws {
    app.logger.info("🔍 Checking for inactive users (placeholder logic)")

    // Example logic: fetch devices not seen in 3+ days
    let threeDaysAgo = Date().addingTimeInterval(-3 * 24 * 60 * 60)

    let inactiveDevices = try await DeviceRegistration.query(on: app.db)
        .filter(\.$lastOpenedAt < threeDaysAgo)
        .all()

    guard let apnsConfig = app.storage[APNSConfigurationKey.self] else {
        throw Abort(.internalServerError, reason: "Missing APNs config")
    }

    for device in inactiveDevices {
        guard !device.deviceToken.isEmpty else { continue }

        let alert = APNSwiftAlert(
            title: "👋 We miss you!",
            body: "Haven’t seen you in a while. Come check out what’s new!"
        )

        let payload = SimplePushPayload(
            aps: APNSwiftPayload(
                alert: alert,
                badge: 1,
                sound: .normal("default")
            )
        )

        do {
            let client = try await APNSwiftConnection.connect(configuration: apnsConfig, on: app.eventLoopGroup.next()).get()
            try await client.send(payload, to: device.deviceToken)
            app.logger.info("✅ Sent re-engagement push to \(device.deviceToken)")
        } catch {
            app.logger.error("❌ Failed to send to \(device.deviceToken): \(error)")
        }
    }
}
