import Foundation
import UserNotifications
import UIKit

/// Handles authentication and registration of emergency contacts via 6-digit codes
class ContactManager: ObservableObject {
    static let shared = ContactManager()

    @Published var currentCode: String = ""
    @Published var isCodeActive: Bool = false
    @Published var expirationDate: Date?

    private var timer: Timer?
    private let codeExpirationMinutes = 10
    private init() {}
    
    /// Generates a new 6-digit authentication code and starts expiration timer
    /// - Returns: The generated 6-digit code
    func generateAuthCode() -> String {
        currentCode = "------"
        isCodeActive = true
        expirationDate = Date().addingTimeInterval(TimeInterval(codeExpirationMinutes * 60))

        startExpirationTimer()
        uploadCodeToServer()

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
        
        // Remove code from server
        removeCodeFromServer()
    }
    
    /// Manually cancels the current authentication code
    func cancelAuthCode() {
        expireCurrentCode()
    }
    
    /// Gets current device token for push notifications
    /// - Returns: Device token string or nil
    private func getDeviceToken() -> String? {
        // In a real app, you'd get this from APNs registration
        // For now, generate a unique identifier for this device
        return UIDevice.current.identifierForVendor?.uuidString
    }
    
    private func uploadCodeToServer() {
        let sirenUUID = BluetoothManager.shared.deviceUUID
        guard !sirenUUID.isEmpty else {
            return
        }
        
        // TODO: Replace with your actual Go server URL
        let serverURL = "http://192.168.1.6:8080/api/auth-code"
        
        guard let url = URL(string: serverURL) else {
            print("Invalid server URL")
            return
        }
        
        let payload: [String: Any] = [
            "device_id": sirenUUID,
            "device_name": "SIREN Ring",
            "user_id": "user123",
            "expires_in": codeExpirationMinutes
        ]
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            print("Failed to encode auth code data: \(error)")
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Failed to upload auth code: \(error)")
                    self.isCodeActive = false
                    return
                }

                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        // Parse server response to get generated code
                        if let data = data,
                           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let success = json["success"] as? Bool,
                           success,
                           let responseData = json["data"] as? [String: Any],
                           let generatedCode = responseData["code"] as? String {
                            self.currentCode = generatedCode
                            print("Auth code generated successfully: \(generatedCode)")
                        } else {
                            print("Failed to parse server response")
                            self.isCodeActive = false
                        }
                    } else {
                        print("Server error uploading auth code: \(httpResponse.statusCode)")
                        self.isCodeActive = false
                    }
                }
            }
        }.resume()
    }
    
    /// Removes expired code from server
    private func removeCodeFromServer() {
        // TODO: Implement DELETE request to server
        print("Auth code expired - removed from server")
    }
    
    struct ContactInfo {
        let name: String
        let deviceID: String
        let hasApp: Bool
    }

    /// Looks up contact info by authentication code
    /// - Parameters:
    ///   - code: 6-digit authentication code
    ///   - completion: Callback with contact info
    static func lookupContactByCode(_ code: String, completion: @escaping (ContactInfo?) -> Void) {
        let serverURL = "http://192.168.1.6:8080/api/auth-code?code=\(code)"

        guard let url = URL(string: serverURL) else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Failed to lookup auth code: \(error)")
                    completion(nil)
                    return
                }

                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let success = json["success"] as? Bool,
                      success,
                      let responseData = json["data"] as? [String: Any],
                      let name = responseData["name"] as? String,
                      let deviceID = responseData["device_id"] as? String,
                      let hasApp = responseData["has_app"] as? Bool else {
                    completion(nil)
                    return
                }

                let contactInfo = ContactInfo(name: name, deviceID: deviceID, hasApp: hasApp)
                completion(contactInfo)
            }
        }.resume()
    }
}