//
//  DeviceRegistration.swift
//  PushNotificationBackend
//
//  Created by Alex Baur on 3/12/25.
//


import Fluent
import Vapor

final class DeviceRegistration: Model, Content {
    // Name of the table in your database.
    static let schema = "device_registrations"

    // Unique identifier for this model.
    @ID(key: .id)
    var id: UUID?

    // The user identifier.
    @Field(key: "user_id")
    var userId: String

    // The device token for push notifications.
    @Field(key: "device_token")
    var deviceToken: String

    // Optionally, add fields for latitude and longitude.
    @OptionalField(key: "latitude")
    var latitude: Double?

    @OptionalField(key: "longitude")
    var longitude: Double?

    init() { }

    init(id: UUID? = nil, userId: String, deviceToken: String, latitude: Double? = nil, longitude: Double? = nil) {
        self.id = id
        self.userId = userId
        self.deviceToken = deviceToken
        self.latitude = latitude
        self.longitude = longitude
    }
}
