import Fluent
import Vapor
import APNS

// MARK: - Push Notification Payloads

/// A simple payload structure conforming to `APNSwiftNotification`.
/// It must have an `aps` property of type `APNSwiftPayload` and implement
/// the optional APNs properties (apnsID, expiration, etc.).
struct SimplePushPayload: APNSwiftNotification {
    // The standard APNs payload from APNSwift, which includes alert, badge, etc.
    let aps: APNSwiftPayload
    
    // Optional properties you can customize as needed.
    var apnsID: UUID? = nil
    var expiration: Date? = nil
    var priority: Int? = nil
    var topic: String? = nil
    var collapseIdentifier: String? = nil
}

// MARK: - Route Handler for Sending Push Notifications

func sendPushNotificationHandler(_ req: Request) async throws -> HTTPStatus {
    // Retrieve the APNs configuration stored in your app's storage.
    guard let apnsConfig = req.application.storage[APNSConfigurationKey.self] else {
        throw Abort(.internalServerError, reason: "APNs configuration is missing")
    }
    
    // Create an APNs client using the configuration.
    let apnsClient = try await APNSwiftConnection.connect(configuration: apnsConfig, on: req.eventLoop).get()
    
    // Replace this with a valid device token from your iOS app.
    let deviceToken = "493ad5a91ee24b109b6b96a178623d1144eac778c6e7e3eec5cbb07da4e3ef6c"
    
    // Build an alert to display to the user.
    let alert = APNSwiftAlert(
        title: nil,
        subtitle: nil,
        body: "Hello from Vapor!"
    )
    
    // Build the APNSwiftPayload (includes alert, badge, sound, etc.).
    // APNSwiftSoundType is an enum. For a normal sound, use .normal("default").
    let apnsPayload = APNSwiftPayload(
        alert: alert,
        badge: 1,
        sound: .normal("default")
    )
    
    // Create our overall push notification payload.
    let payload = SimplePushPayload(aps: apnsPayload)
    
    // Send the push notification to the specified device token.
    try await apnsClient.send(payload, to: deviceToken)
    
    // Return a success status code.
    return .ok
}

// MARK: - Application Routes

func routes(_ app: Application) throws {
    // Create a new device registration
    app.post("register") { req -> EventLoopFuture<DeviceRegistration> in
        let deviceReg = try req.content.decode(DeviceRegistration.self)
        return deviceReg.create(on: req.db).map { deviceReg }
    }

    // Fetch all device registrations
    app.get("registrations") { req -> EventLoopFuture<[DeviceRegistration]> in
        DeviceRegistration.query(on: req.db).all()
    }
    
    // Route to test push notifications.
    app.get("testPush", use: sendPushNotificationHandler)
}
