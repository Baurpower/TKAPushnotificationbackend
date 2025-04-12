//
//  PushNotificationsRoutes.swift
//  PushNotificationBackend
//
//  Created by Alex Baur on 4/12/25.
//

import Vapor
import APNS

// Define a simple payload structure for your push notification.
struct SimplePushPayload: Codable {
    let aps: APSPayload
}

struct APSPayload: Codable {
    let alert: String
    let badge: Int?
    let sound: String?
}

// A route handler to send a push notification.
func sendPushNotificationHandler(_ req: Request) async throws -> HTTPStatus {
    // Retrieve the APNs configuration from app storage.
    guard let apnsConfig = req.application.storage[APNSConfigurationKey.self] else {
        throw Abort(.internalServerError, reason: "APNs configuration is missing")
    }
    
    // Create an APNs client using your configuration.
    let apnsClient = try await APNSwiftConnection.connect(configuration: apnsConfig, on: req.eventLoop).get()
    
    // Build your payload.
    let payload = SimplePushPayload(aps: APSPayload(alert: "Hello from Vapor!", badge: 1, sound: "default"))
    
    // Send the push notification.
    try await apnsClient.send(payload, to: deviceToken)
    
    // Return an HTTP status to indicate success.
    return .ok
}
