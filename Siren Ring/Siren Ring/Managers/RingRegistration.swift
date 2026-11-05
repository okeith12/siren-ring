import Foundation

/// RingRegistration registers a ring and its owner with the SIREN server.
struct RingRegistration: RingRegistering {
    static let url = URL(string: "http://192.168.1.6:8080/api/register-device")

    /// register posts the ring, its owner and this phone's push token; done gets true only for a 200.
    func register(sirenId: String, user: String, name: String, done: @escaping (Bool) -> Void) {
        let body: [String: String] = [
            "device_id": sirenId,
            "user_id": user.isEmpty ? "Default User" : user,
            "device_name": name.isEmpty ? "SIREN Ring" : name,
            "apns_token": NotificationManager.shared.deviceToken ?? "",
        ]
        guard let url = Self.url, let json = try? JSONSerialization.data(withJSONObject: body) else {
            return done(false)
        }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = json
        URLSession.shared.dataTask(with: request) { _, response, _ in
            let ok = (response as? HTTPURLResponse)?.statusCode == 200
            DispatchQueue.main.async { done(ok) }
        }.resume()
    }
}
