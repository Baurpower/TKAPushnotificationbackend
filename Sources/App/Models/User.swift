import Fluent
import Vapor

final class User: Model, Content {
    // Name of the table in your database
    static let schema = "users"

    // Unique identifier for the user.
    @ID(key: .id)
    var id: UUID?

    // A sample field (username)
    @Field(key: "username")
    var username: String

    // Initialize with data.
    init() { }

    init(id: UUID? = nil, username: String) {
        self.id = id
        self.username = username
    }
}
