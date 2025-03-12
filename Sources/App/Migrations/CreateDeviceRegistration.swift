import Fluent

struct CreateDeviceRegistration: Migration {
    func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("device_registrations")
            .id()
            .field("user_id", .string, .required)
            .field("device_token", .string, .required)
            .field("latitude", .double)
            .field("longitude", .double)
            .create()
    }

    func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("device_registrations").delete()
    }
}
