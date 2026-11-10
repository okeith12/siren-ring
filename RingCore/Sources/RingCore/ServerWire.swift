import Foundation

/// The bodies the app sends the SIREN server. Field names become the server's snake_case keys
/// (deviceId is device_id), so these structs are the app's half of the contract.

/// Registration ties a ring to its owner and this phone's push token.
public struct Registration: Encodable, Sendable {
    let deviceId: String, userId: String, deviceName: String, apnsToken: String

    /// init takes a vetted Siren id; the token is empty where iOS gives none, as in the Simulator.
    public init(deviceId: String, userId: String, deviceName: String, apnsToken: String) {
        (self.deviceId, self.userId, self.deviceName, self.apnsToken) = (deviceId, userId, deviceName, apnsToken)
    }
}

/// Alerted is one contact an emergency goes to, found by their ring.
public struct Alerted: Encodable, Sendable {
    let name: String, phone: String, deviceId: String

    /// init names the contact; deviceId is empty for a contact reached only by phone.
    public init(name: String, phone: String, deviceId: String) {
        (self.name, self.phone, self.deviceId) = (name, phone, deviceId)
    }
}

/// Emergency is the alarm itself, sent to everyone in contacts.
public struct Emergency: Encodable, Sendable {
    let emergencyType = "siren_ring_activation", priority = "critical"
    let userId: String, message: String, timestamp: String, contacts: [Alerted]

    /// init takes the owner's Siren id, the message with its map link, and an ISO 8601 time.
    public init(userId: String, message: String, timestamp: String, contacts: [Alerted]) {
        (self.userId, self.message, self.timestamp, self.contacts) = (userId, message, timestamp, contacts)
    }
}

/// CodeRequest asks the server for a share code that finds this ring for expiresIn minutes.
public struct CodeRequest: Encodable, Sendable {
    let deviceId: String, deviceName: String, userId: String, expiresIn: Int

    /// init takes the ring to be found and how long its code lives.
    public init(deviceId: String, deviceName: String, userId: String, expiresIn: Int) {
        (self.deviceId, self.deviceName, self.userId, self.expiresIn) = (deviceId, deviceName, userId, expiresIn)
    }
}

/// TokenUpdate tells the server this phone's push token changed.
public struct TokenUpdate: Encodable, Sendable {
    let deviceId: String, apnsToken: String, userId: String

    /// init takes the ring the token belongs to and the new token.
    public init(deviceId: String, apnsToken: String, userId: String) {
        (self.deviceId, self.apnsToken, self.userId) = (deviceId, apnsToken, userId)
    }
}

/// ServerWire turns a request into the JSON the server reads.
public enum ServerWire {
    /// body is the request as JSON, or nil if it would not encode, so nothing half-built is sent.
    public static func body(_ request: some Encodable) -> Data? {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        return try? encoder.encode(request)
    }
}
