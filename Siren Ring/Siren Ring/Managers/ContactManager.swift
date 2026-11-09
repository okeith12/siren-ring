import Foundation
import RingCore
import UserNotifications

/// Handles authentication and registration of emergency contacts via 6-digit codes
class ContactManager: ObservableObject {
    static let shared = ContactManager()

    @Published var currentCode: String = ""
    @Published var isCodeActive: Bool = false
    @Published var expirationDate: Date?

    private var timer: Timer?
    private let codeExpirationMinutes = 10
    /// init is private: one code at a time, shared by every screen.
    private init() {}
    
    /// Generates a new 6-digit authentication code and starts expiration timer
    /// - Returns: The generated 6-digit code
    func generateAuthCode() -> String {
        currentCode = "------"
        isCodeActive = true
        expirationDate = Date().addingTimeInterval(TimeInterval(codeExpirationMinutes * 60))

        startExpirationTimer()
        askForCode()

        return currentCode
    }
    
    /// Starts timer to expire the current code
    private func startExpirationTimer() {
        timer?.invalidate()
        
        timer = Timer.scheduledTimer(withTimeInterval: TimeInterval(codeExpirationMinutes * 60), repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.expireCurrentCode()
            }
        }
    }
    
    /// Expires the current authentication code
    private func expireCurrentCode() {
        currentCode = ""
        isCodeActive = false
        expirationDate = nil
        timer?.invalidate()
        timer = nil
    }
    
    /// Manually cancels the current authentication code
    func cancelAuthCode() {
        expireCurrentCode()
    }
    
    /// askForCode gets a share code for this ring from the server; with no ring, or an answer
    /// that does not hold up, there is no code.
    private func askForCode() {
        let sirenId = BluetoothManager.shared.deviceUUID
        let request = CodeRequest(deviceId: sirenId, deviceName: "SIREN Ring", userId: sirenId,
                                  expiresIn: codeExpirationMinutes)
        guard RingInfo.isSirenId(sirenId), let body = ServerWire.body(request) else {
            return isCodeActive = false
        }
        SirenServer().send("/api/auth-code", body) { [weak self] status, data in
            guard let self else { return }
            guard status == 200, let code = ServerAnswer.code(data) else { return isCodeActive = false }
            currentCode = code
        }
    }

    /// lookup finds the contact a share code belongs to. A code that is not six digits never
    /// leaves the phone, and done gets nil for any answer that does not hold up.
    static func lookup(_ code: String, server: ServerLink = SirenServer(),
                       done: @escaping (ContactCard?) -> Void) {
        guard ServerAnswer.isCode(code) else { return done(nil) }
        server.send("/api/auth-code?code=\(code)", nil) { status, data in
            done(status == 200 ? ServerAnswer.contact(data) : nil)
        }
    }
}
