//
//  NotificationScheduler.swift
//  PushNotificationBackend
//
//  Created by Alex Baur on 4/12/25.
//
import Vapor
import Fluent
import APNS

// This function queries the database for devices inactive for more than 3 days and sends a push notification.
func checkAndSendInactiveUserNotifications(app: Application) async throws {
    // Calculate the cutoff timestamp (3 days ago).
    let threeDaysAgo = Date().addingTimeInterval(-3 * 24 * 60 * 60)
    
    // Query for devices that have never been opened OR haven't been opened in the last 3 days.
    let inactiveDevices = try await DeviceRegistration.query(on: app.db)
        .group(.or) { group in
            group.filter(\.$lastOpenedAt == nil)
            group.filter(\.$lastOpenedAt < threeDaysAgo)
        }
        .all()
    
    // Ensure that the APNs configuration is available.
    guard let apnsConfig = app.storage[APNSConfigurationKey.self] else {
        app.logger.error("APNs configuration is missing.")
        return
    }
    
    // Establish an APNs connection.
    let apnsClient = try await APNSwiftConnection.connect(configuration: apnsConfig, on: app.eventLoopGroup.next()).get()
    
    // Prepare the common notification payload.
    let alert = APNSwiftAlert(
        title: "We miss you!",
        subtitle: nil,
        body: "Don't forget to journal about your knee :)"
    )
    let apnsPayload = APNSwiftPayload(
        alert: alert,
        badge: nil,      // Set to nil if you don't want to change badge number
        sound: .normal("default")
    )
    let payload = SimplePushPayload(aps: apnsPayload)
    
    // Loop through each inactive device and send a notification.
    for device in inactiveDevices {
        do {
            try await apnsClient.send(payload, to: device.deviceToken)
            app.logger.info("Notification sent to device token: \(device.deviceToken)")
        } catch {
            app.logger.error("Failed to send notification to \(device.deviceToken): \(error)")
        }
    }
}

