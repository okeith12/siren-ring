# SIREN Ring Emergency System

A SwiftUI-based iOS application that connects to a SIREN Ring device via Bluetooth to provide emergency alerting capabilities through push notifications and SMS.

## Overview

SIREN Ring is an emergency alert system that consists of:
- A wearable SIREN Ring device that communicates via Bluetooth
- An iOS companion app for managing connections and emergency contacts
- Push notification and SMS alert delivery to emergency contacts

## Features

### 🔗 Bluetooth Connectivity
- Automatic discovery and connection to SIREN Ring devices
- Real-time connection status monitoring
- Manual scan and disconnect capabilities

### 🚨 Emergency Alerts
- Instant emergency activation detection from the ring device
- Local device notifications with critical sound
- Automatic alert distribution to all registered emergency contacts

### 👥 Contact Management
- Add emergency contacts with phone numbers
- Support for both app-enabled contacts (push notifications) and SMS-only contacts
- Swipe-to-delete functionality for contact management
- Visual indicators for contacts with app installed

### 📱 Push Notifications
- Priority delivery to contacts with the SIREN Ring app installed
- SMS fallback for contacts without the app
- Critical alert sound and badge notifications

## Project Structure

```
Siren Ring/
├── Models/
│   └── EmergencyContact.swift      # Contact data model with push notification support
├── Views/
│   ├── ContentView.swift           # Main application interface
│   └── Contact.swift               # Add contact form view
├── Managers/
│   ├── BluetoothManager.swift      # Bluetooth connectivity and device communication
│   └── EmergencyManager.swift      # Emergency alert distribution system
└── Siren_RingApp.swift            # Application entry point
```

## Technical Details

### Bluetooth Communication
- **Service UUID**: `12345678-1234-1234-1234-123456789abc`
- **Characteristic UUID**: `87654321-4321-4321-4321-cba987654321`
- **Device Name**: `SIREN-Ring`
- **Emergency Codes**: `1` (activate), `0` (deactivate)

### Data Persistence
- Emergency contacts stored in `UserDefaults` using JSON encoding
- Automatic contact loading on app launch
- Real-time contact synchronization

### Notification System
- Local notifications for device alerts
- Push notification delivery to contacts with app ID
- SMS fallback via `MessageUI` framework
- Critical sound alerts for emergency situations

## Usage

### Initial Setup
1. Launch the SIREN Ring app
2. Grant notification permissions when prompted
3. Add emergency contacts using the "Add" button
4. For contacts with the app, provide their App ID for push notifications

### Connecting Your Ring
1. Ensure Bluetooth is enabled on your device
2. Press "Scan" to search for your SIREN Ring
3. The app will automatically connect when the ring is found
4. Connection status will update to "Ready for emergency alerts"

### Emergency Activation
1. When the SIREN Ring is activated, the app receives the emergency signal
2. A critical alert notification appears on your device
3. All emergency contacts are notified via:
   - Push notifications (for contacts with the app)
   - SMS messages (for contacts without the app)

## Requirements

- iOS 14.0+
- Bluetooth Low Energy capable device
- Notification permissions
- Optional: SMS permissions for fallback messaging

## Emergency Contact Model

The `EmergencyContact` model supports two types of contacts:

### SMS-Only Contacts
```swift
EmergencyContact(name: "John Doe", phoneNumber: "+1234567890")
```

### App-Enabled Contacts
```swift
EmergencyContact(name: "Jane Doe", phoneNumber: "+1234567890", appID: "unique-app-id")
```

## Development Notes

### Future Enhancements
- Location services integration for GPS coordinates in alerts
- Advanced contact management with custom alert preferences
- Integration with external push notification services (APNs, Firebase)
- Emergency contact relationship management
- Alert history and logging

### Architecture Patterns
- **MVVM**: Using `@StateObject` and `@ObservableObject` for state management
- **Singleton Pattern**: `EmergencyManager.shared` for centralized contact management
- **Delegate Pattern**: Bluetooth delegate callbacks for device communication
- **Publisher/Subscriber**: `@Published` properties for real-time UI updates

## Privacy & Security

- All emergency contacts are stored locally on the device
- No data is transmitted to external servers without explicit action
- Bluetooth communication uses secure pairing protocols
- Emergency alerts are sent only to pre-approved contacts

## Support

For issues, feature requests, or technical questions, please refer to the project's issue tracker or contact the development team.

---

**SIREN Ring** - Your personal emergency response system, always within reach.