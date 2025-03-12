import Fluent
import Vapor

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
}

