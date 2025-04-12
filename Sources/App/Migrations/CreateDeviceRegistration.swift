import Fluent

struct CreateDeviceRegistration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("device_registrations")
            .id()
            .field("device_token", .string, .required)
            .field("user_id", .uuid)
            .field("last_opened_at", .datetime)
            .field("created_at", .datetime)
            .field("updated_at", .datetime)
            .create()
    }
    
    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("device_registrations").delete()
    }
}
