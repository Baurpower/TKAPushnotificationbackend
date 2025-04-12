import Fluent
import Vapor

final class DeviceRegistration: Model, Content {
    static let schema = "device_registrations"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "device_token")
    var deviceToken: String
    
    @OptionalField(key: "user_id")
    var userId: UUID?
    
    // NEW FIELD: Track the last time the app was opened.
    @OptionalField(key: "last_opened_at")
    var lastOpenedAt: Date?
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() { }

    init(id: UUID? = nil, deviceToken: String, userId: UUID? = nil, lastOpenedAt: Date? = nil) {
        self.id = id
        self.deviceToken = deviceToken
        self.userId = userId
        self.lastOpenedAt = lastOpenedAt
    }
}
