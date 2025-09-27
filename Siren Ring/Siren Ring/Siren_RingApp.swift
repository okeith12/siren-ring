//
//  Siren_RingApp.swift
//  Siren Ring
//
//  Created by Okeith on 8/24/25.
//

import SwiftUI
import UserNotifications

/// Main application entry point for SIREN Ring emergency system
@main
struct Siren_RingApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    /// Application scene configuration
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    NotificationManager.shared.requestPermissions()
                }
        }
    }
}

/// App delegate to handle APNS token registration
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        // Set notification delegate
        UNUserNotificationCenter.current().delegate = self

        // Register for remote notifications on every app launch
        application.registerForRemoteNotifications()
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("APNS Device Token: \(token)")

        // Send token to server
        NotificationManager.shared.registerDeviceToken(token)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error)")
    }

    // MARK: - UNUserNotificationCenterDelegate

    /// Handle notifications when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("Received notification while app in foreground: \(notification.request.content.title)")

        // Show banner, sound, and badge even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }

    /// Handle notification taps
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("User tapped notification: \(response.notification.request.content.body)")

        // Extract map URL from notification body and open it
        let notificationBody = response.notification.request.content.body
        if let mapURL = extractMapURL(from: notificationBody) {
            DispatchQueue.main.async {
                if let url = URL(string: mapURL) {
                    UIApplication.shared.open(url)
                }
            }
        }

        completionHandler()
    }

    /// Extract Apple Maps URL from notification text
    private func extractMapURL(from text: String) -> String? {
        // Look for https://maps.apple.com URL pattern
        let pattern = "https://maps\\.apple\\.com/\\?[^\\s]+"
        if let regex = try? NSRegularExpression(pattern: pattern) {
            let range = NSRange(location: 0, length: text.utf16.count)
            if let match = regex.firstMatch(in: text, range: range) {
                return String(text[Range(match.range, in: text)!])
            }
        }
        return nil
    }
}
