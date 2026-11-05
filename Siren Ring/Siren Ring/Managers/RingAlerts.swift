import Foundation
import UserNotifications

/// RingAlerts is what happens once the proven ring speaks: the family is told through the
/// server, and the user sees it on this phone.
struct RingAlerts: RingAlerting {
    /// on alerts the family and shows a critical notification here.
    func on() {
        notify(id: "siren-emergency", title: "SIREN RING EMERGENCY",
               body: "Emergency alert triggered! Notifying emergency contacts.", sound: .defaultCritical)
        EmergencyManager.shared.sendEmergencyAlert()
    }

    /// off clears the emergency notification still waiting to show.
    func off() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["siren-emergency"])
    }

    /// paired tells the user a ring is now theirs, which matters most when the app is not open.
    func paired(_ sirenId: String) {
        notify(id: "siren-paired", title: "SIREN Ring connected",
               body: "Ring \(sirenId.prefix(6)) is now yours and listening for alerts.", sound: .default)
    }

    /// notify posts one local notification right away; one iOS refuses is recorded.
    private func notify(id: String, title: String, body: String, sound: UNNotificationSound) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = sound
        let request = UNNotificationRequest(identifier: id, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request) { error in
            guard error != nil else { return }
            DispatchQueue.main.async { BluetoothManager.shared.alertFailed() }
        }
    }
}
