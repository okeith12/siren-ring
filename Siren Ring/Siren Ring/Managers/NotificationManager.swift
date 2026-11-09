import Foundation
import UserNotifications
import UIKit
import RingCore

/// Manages APNS registration and notification permissions for emergency alerts
class NotificationManager: ObservableObject {
    static let shared = NotificationManager()

    @Published var permissionStatus: UNAuthorizationStatus = .notDetermined
    @Published var deviceToken: String?
    static let tokenKey = "apns_device_token"

    /// init reads where notification permission already stands.
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

    /// registerDeviceToken keeps this phone's push token; a changed token is remembered only once
    /// the server has it, so a failed update is tried again on the next launch.
    func registerDeviceToken(_ token: String) {
        deviceToken = token
        let previous = UserDefaults.standard.string(forKey: Self.tokenKey)
        if previous == nil { UserDefaults.standard.set(token, forKey: Self.tokenKey) }
        if previous != nil && previous != token { updateTokenOnServer(token) }
    }

    /// updateTokenOnServer tells the server this phone's push token changed, so alarms still
    /// reach it; with no ring yet there is nothing to update.
    private func updateTokenOnServer(_ token: String) {
        let sirenId = BluetoothManager.shared.deviceUUID
        guard RingInfo.isSirenId(sirenId),
              let body = ServerWire.body(TokenUpdate(deviceId: sirenId, apnsToken: token, userId: sirenId))
        else { return }
        SirenServer().send("/api/update-token", body) { status, _ in
            if status == 200 { UserDefaults.standard.set(token, forKey: Self.tokenKey) }
        }
    }
}
