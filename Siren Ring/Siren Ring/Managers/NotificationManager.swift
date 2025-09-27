import Foundation
import UserNotifications
import UIKit

/// Manages APNS registration and notification permissions for emergency alerts
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var permissionStatus: UNAuthorizationStatus = .notDetermined
    @Published var deviceToken: String?

    private let serverURL = "http://192.168.1.6:8080" // TODO: Replace with your server URL

    private init() {
        checkPermissionStatus()
    }

    /// Requests notification permissions from user (one-time request)
    func requestPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(
            options: [.alert, .sound, .badge, .criticalAlert]
        ) { [weak self] granted, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Notification permission error: \(error)")
                    return
                }

                print("Notification permissions granted: \(granted)")
                self?.checkPermissionStatus()

                if granted {
                    // Register for remote notifications
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
            }
        }
    }

    /// Checks current notification permission status
    func checkPermissionStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.permissionStatus = settings.authorizationStatus
                print("Notification permission status: \(settings.authorizationStatus.rawValue)")
            }
        }
    }

    /// Stores APNS Device Token locally (server registration happens during device registration)
    func registerDeviceToken(_ token: String) {
        // Store token locally
        self.deviceToken = token
        let previousToken = UserDefaults.standard.string(forKey: "apns_device_token")
        UserDefaults.standard.set(token, forKey: "apns_device_token")

        // Check if token changed - if so, update all relationships on server
        if previousToken != token && previousToken != nil {
            updateTokenOnServer(token)
        }
    }


    /// Updates token on server for all emergency relationships
    private func updateTokenOnServer(_ token: String) {
        guard let url = URL(string: "\(serverURL)/api/update-token") else {
            print("Invalid server URL")
            return
        }

        let payload: [String: Any] = [
            "device_id": BluetoothManager.shared.deviceUUID,
            "apns_token": token,
            "user_id": BluetoothManager.shared.deviceUUID
        ]

        sendTokenRequest(to: url, payload: payload, description: "token update")
    }

    /// Common method to send token requests
    private func sendTokenRequest(to url: URL, payload: [String: Any], description: String) {
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            print("Failed to encode \(description): \(error)")
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("APNS \(description) failed: \(error)")
                    return
                }

                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        print("APNS \(description) successful")

                        // Parse response to see how many relationships were updated
                        if let data = data,
                           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let responseData = json["data"] as? [String: Any],
                           let relationshipsUpdated = responseData["relationships_updated"] as? Int {
                            print("Updated APNS token for \(relationshipsUpdated) emergency relationships")
                        }
                    } else {
                        print("Server error for APNS \(description): \(httpResponse.statusCode)")
                    }
                }
            }
        }.resume()
    }

    /// Sends emergency contact's APNS token to server when they accept invitation
    func registerEmergencyContactToken(contactName: String, phoneNumber: String?, authCode: String) {
        guard let token = deviceToken,
              let url = URL(string: "\(serverURL)/api/contacts") else {
            print("Missing device token or invalid server URL")
            return
        }

        let payload: [String: Any] = [
            "name": contactName,
            "phone_number": phoneNumber ?? "",
            "auth_code": authCode,
            "apns_token": token, 
            "has_app": !BluetoothManager.shared.deviceUUID.isEmpty
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: payload)
        } catch {
            print("Failed to encode emergency contact registration: \(error)")
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Emergency contact registration failed: \(error)")
                    return
                }

                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 200 {
                        print("Emergency contact registered with APNS token")
                    } else {
                        print("Server error registering emergency contact: \(httpResponse.statusCode)")
                    }
                }
            }
        }.resume()
    }

    /// Gets stored device token
    func getStoredDeviceToken() -> String? {
        return UserDefaults.standard.string(forKey: "apns_device_token")
    }
}