import Foundation

/// ServerLink sends one request to the SIREN server, behind a protocol so tests stand in for
/// the network.
protocol ServerLink {
    /// send POSTs body to path, or GETs path when body is nil. done runs on the main queue with
    /// the status, 0 when the server never answered, and the answer, still untrusted.
    func send(_ path: String, _ body: Data?, done: @escaping (Int, Data?) -> Void)
}

/// SirenServer is ServerLink over URLSession: it moves bytes and judges nothing, because every
/// answer is vetted by ServerAnswer, which is tested without a network.
struct SirenServer: ServerLink {
    static let timeout: TimeInterval = 10

    /// send gives up after timeout, so a dead server reads as an answer of 0, not a hang.
    func send(_ path: String, _ body: Data?, done: @escaping (Int, Data?) -> Void) {
        guard let url = URL(string: RingParts.server + path) else {
            return DispatchQueue.main.async { done(0, nil) }
        }
        var request = URLRequest(url: url, timeoutInterval: Self.timeout)
        if let body {
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = body
        }
        URLSession.shared.dataTask(with: request) { data, response, _ in
            let status = (response as? HTTPURLResponse)?.statusCode ?? 0
            DispatchQueue.main.async { done(status, data) }
        }.resume()
    }
}
