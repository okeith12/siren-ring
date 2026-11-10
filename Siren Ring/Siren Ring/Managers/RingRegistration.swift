import Foundation
import RingCore

/// RingRegistration registers a ring and its owner with the SIREN server.
struct RingRegistration: RingRegistering {
    let server: ServerLink

    /// init takes the link to the server; tests hand it a fake.
    init(server: ServerLink = SirenServer()) {
        self.server = server
    }

    /// register posts the ring, its owner and this phone's push token; done gets true only for a 200.
    func register(sirenId: String, user: String, name: String, done: @escaping (Bool) -> Void) {
        let registration = Registration(
            deviceId: sirenId, userId: user.isEmpty ? "Default User" : user,
            deviceName: name.isEmpty ? "SIREN Ring" : name,
            apnsToken: NotificationManager.shared.deviceToken ?? "")
        guard let body = ServerWire.body(registration) else { return done(false) }
        server.send("/api/register-device", body) { status, _ in done(status == 200) }
    }
}
