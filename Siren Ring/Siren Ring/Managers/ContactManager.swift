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
        // Generate random 6-digit code
        let code = String(format: "%06d", Int.random(in: 100000...999999))
        
        currentCode = code
        isCodeActive = true
        expirationDate = Date().addingTimeInterval(TimeInterval(codeExpirationMinutes * 60))
        
        // Start expiration timer
        startExpirationTimer()
        
        // Send code to server for mapping
        uploadCodeToServer(code: code)
        
        return code
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
    
    /// Uploads authentication code and device token to server
    /// - Parameter code: 6-digit authentication code
    private func uploadCodeToServer(code: String) {
        guard let deviceToken = getDeviceToken() else {
            print("No device token available")
            return
        }
        
        // TODO: Replace with your actual Go server URL
        let serverURL = "https://localhost:8443/api/auth-code"
        
        guard let url = URL(string: serverURL) else {
            print("Invalid server URL")
            return
        }
        
        let payload: [String: Any] = [
            "code": code,
            "device_token": deviceToken,
            "expires_at": ISO8601DateFormatter().string(from: expirationDate ?? Date()),
            "device_name": UIDevice.current.name
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
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        print("Auth code uploaded successfully")
                    } else {
                        print("Server error uploading auth code: \(httpResponse.statusCode)")
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
    
    /// Looks up contact info by authentication code
    /// - Parameters:
    ///   - code: 6-digit authentication code
    ///   - completion: Callback with contact name and device token
    static func lookupContactByCode(_ code: String, completion: @escaping (String?, String?) -> Void) {
        // TODO: Replace with your actual Go server URL  
        let serverURL = "https://localhost:8443/api/auth-code/\(code)"
        
        guard let url = URL(string: serverURL) else {
            completion(nil, nil)
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Failed to lookup auth code: \(error)")
                    completion(nil, nil)
                    return
                }
                
                guard let data = data,
                      let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                      let success = json["success"] as? Bool,
                      success,
                      let responseData = json["data"] as? [String: Any],
                      let deviceToken = responseData["device_token"] as? String,
                      let deviceName = responseData["device_name"] as? String else {
                    completion(nil, nil)
                    return
                }
                
                completion(deviceName, deviceToken)
            }
        }.resume()
    }
}