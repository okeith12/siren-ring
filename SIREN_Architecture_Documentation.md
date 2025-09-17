# SIREN Emergency Alert System - Architecture Documentation

## Table of Contents
1. [System Overview](#system-overview)
2. [Component Architecture](#component-architecture)
3. [Sequence Diagrams](#sequence-diagrams)
4. [Data Flow Diagrams](#data-flow-diagrams)
5. [Database Schema](#database-schema)
6. [API Specifications](#api-specifications)
7. [Technical Implementation Details](#technical-implementation-details)

---

## 1. System Overview

### High-Level Architecture
```
┌─────────────────┐    BLE     ┌─────────────────┐    HTTP/HTTPS    ┌─────────────────┐
│    ESP32 C++    │ ◄────────► │   iOS Swift     │ ◄──────────────► │   Go Server     │
│   SIREN Ring    │            │      App        │                  │   (sirenserv)   │
└─────────────────┘            └─────────────────┘                  └─────────────────┘
         │                              │                                      │
         │                              │                                      │
    ┌────▼────┐                    ┌────▼────┐                            ┌────▼────┐
    │ Touch   │                    │ Local   │                            │ SQLite  │
    │ Sensor  │                    │ Storage │                            │Database │
    │ Buzzer  │                    │(UserDef)│                            │ (GORM) │
    └─────────┘                    └─────────┘                            └─────────┘
                                                                               │
                                                                          ┌────▼────┐
                                                                          │  APNs   │
                                                                          │ Client  │
                                                                          └────┬────┘
                                                                               │
                                                                          ┌────▼────┐
                                                                          │Emergency│
                                                                          │Contacts │
                                                                          │iOS Apps │
                                                                          └─────────┘
```

### Technology Stack
- **ESP32**: Arduino Framework (C++), FreeRTOS, BLE Stack
- **iOS App**: SwiftUI, Core Bluetooth, UserNotifications, Foundation
- **Go Server**: Gin/HTTP, GORM, SQLite, APNs2, TLS

---

## 2. Component Architecture

### 2.1 ESP32 C++ Application (SIREN Ring)

#### Class Diagram
```
┌─────────────────────────────────────────┐
│                Siren                    │
├─────────────────────────────────────────┤
│ - deviceUUID: String                    │
│ - isRegistered: bool                    │
│ - emergencyActive: bool                 │
│ - lastTouchTime: unsigned long          │
│ - touchState: TouchState               │
├─────────────────────────────────────────┤
│ + setup(): void                         │
│ + loop(): void                          │
│ + checkTouch(): void                    │
│ + handleTouch(): void                   │
│ + triggerEmergency(): void              │
│ + playAlarm(): void                     │
│ + stopAlarm(): void                     │
└─────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────┐
│             ConfigManager               │
├─────────────────────────────────────────┤
│ - preferences: Preferences              │
├─────────────────────────────────────────┤
│ + loadConfig(): void                    │
│ + saveConfig(): void                    │
│ + getUUID(): String                     │
│ + isRegistered(): bool                  │
│ + setRegistered(bool): void             │
└─────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────┐
│             BLEServer                   │
├─────────────────────────────────────────┤
│ - pServer: BLEServer*                   │
│ - pService: BLEService*                 │
│ - pEmergencyChar: BLECharacteristic*    │
│ - pDeviceInfoChar: BLECharacteristic*   │
├─────────────────────────────────────────┤
│ + initBLE(): void                       │
│ + updateEmergencyStatus(): void         │
│ + updateDeviceInfo(): void              │
│ + startAdvertising(): void              │
└─────────────────────────────────────────┘
```

#### Hardware Abstraction Layer
```cpp
// Function pointers for hardware abstraction
typedef void (*TouchCallback)();
typedef void (*BuzzerCallback)(int frequency, int duration);

struct HardwareConfig {
    int touchPin = TOUCH_SENSOR_PIN;
    int buzzer1Pin = BUZZER_1_PIN;
    int buzzer2Pin = BUZZER_2_PIN;
    TouchCallback onTouch = handleTouch;
    BuzzerCallback playTone = playBuzzerTone;
};
```

#### BLE Protocol Specification
```cpp
// Service UUID: 12345678-1234-1234-1234-123456789abc
#define SERVICE_UUID "12345678-1234-1234-1234-123456789abc"

// Emergency Status Characteristic
// UUID: 12345678-1234-1234-1234-123456789abd
// Type: uint8_t (0 = OFF, 1 = ON)
// Properties: READ, NOTIFY

// Device Info Characteristic
// UUID: 12345678-1234-1234-1234-123456789abe
// Type: String ("{uuid},{registered}")
// Properties: READ, NOTIFY
```

### 2.2 iOS Swift Application

#### Manager Architecture
```
┌─────────────────────────────────────────┐
│           BluetoothManager              │
│              (Singleton)                │
├─────────────────────────────────────────┤
│ @Published var isConnected: Bool        │
│ @Published var emergencyActive: Bool    │
│ @Published var deviceUUID: String       │
│ @Published var showRegistrationButton   │
├─────────────────────────────────────────┤
│ + startScanning(): void                 │
│ + connectToDevice(): void               │
│ + registerDevice(): void                │
│ + disconnect(): void                    │
└─────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────┐
│            EmergencyManager             │
│              (Singleton)                │
├─────────────────────────────────────────┤
│ @Published var emergencyContacts: [EC]  │
├─────────────────────────────────────────┤
│ + sendEmergencyAlert(): void            │
│ + addEmergencyContact(EC): void         │
│ + removeEmergencyContact(Int): void     │
│ + loadEmergencyContacts(): void         │
└─────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────┐
│             ContactManager              │
│              (Singleton)                │
├─────────────────────────────────────────┤
│ @Published var currentCode: String      │
│ @Published var isCodeActive: Bool       │
├─────────────────────────────────────────┤
│ + generateAuthCode(): String            │
│ + lookupContactByCode(): void           │
│ + cancelAuthCode(): void                │
└─────────────────────────────────────────┘
```

#### SwiftUI View Hierarchy
```
ContentView (NavigationView)
├── SIREN Ring Status Display
├── Emergency Status Indicator
├── Connection Controls
│   ├── Register Button (conditional)
│   └── Scan Button (conditional)
├── Emergency Contacts Section
│   ├── Add Button → AddContactView (Sheet)
│   └── Contact List → ContactDetailView (Sheet)
└── Toolbar
    └── Share Button → ShareContactView (Sheet)

AddContactView (NavigationView)
├── Contact Method Picker (Phone/App Code)
├── Name Input Field
├── Phone Number Input (conditional)
├── Auth Code Input (conditional)
└── Add Contact Button

ShareContactView (NavigationView)
├── Auth Code Display
├── QR Code Display
├── Instructions Text
└── Copy/Share Controls

ContactDetailView (NavigationView)
├── Contact Icon & Name
├── Contact Details (Phone, Device ID)
├── Connection Status
└── Toolbar
    ├── Delete Button
    └── Done Button
```

### 2.3 Go Server Application (sirenserv)

#### Handler Architecture
```
┌─────────────────────────────────────────┐
│                Router                   │
├─────────────────────────────────────────┤
│ - db: *Database                         │
│ - apns: *APNSClient                     │
├─────────────────────────────────────────┤
│ + handleEmergency()                     │
│ + handleTokenRegistration()             │
│ + handleAuthCode()                      │
│ + handleContacts()                      │
│ + handleHealth()                        │
└─────────────────────────────────────────┘
                    │
        ┌───────────┼───────────┐
        ▼           ▼           ▼
┌─────────────┐ ┌─────────────┐ ┌─────────────┐
│  Database   │ │ APNSClient  │ │   Models    │
│  (GORM)     │ │             │ │             │
├─────────────┤ ├─────────────┤ ├─────────────┤
│+RegisterDev │ │+SendNotif   │ │ Device      │
│+GetDevice   │ │+Initialize  │ │ AuthCode    │
│+CreateAuth  │ │             │ │ Emergency   │
│+GetAuth     │ │             │ │ Contact     │
│+AddContact  │ │             │ │ Request     │
└─────────────┘ └─────────────┘ └─────────────┘
```

#### Database Layer (GORM)
```go
type Database struct {
    db *gorm.DB
}

// Core operations
func (d *Database) RegisterDevice(deviceID, userID, deviceName string) error
func (d *Database) GetDevice(deviceID string) (*models.Device, error)
func (d *Database) CreateAuthCode(code *models.AuthCode) error
func (d *Database) GetAuthCode(code string) (*models.AuthCode, error)
func (d *Database) AddEmergencyContact(contact *models.EmergencyContact) error
func (d *Database) GetEmergencyContacts(userID string) ([]models.EmergencyContact, error)
func (d *Database) CleanupExpiredAuthCodes() error
```

---

## 3. Sequence Diagrams

### 3.1 Device Registration Flow
```
ESP32          iOS App        Go Server       Database
  │              │              │              │
  │──BLE Adv──►  │              │              │
  │              │              │              │
  │  ◄──Connect──│              │              │
  │              │              │              │
  │──UUID,false──►              │              │
  │              │              │              │
  │              │──Register──► │              │
  │              │   Request    │              │
  │              │              │──Save──────► │
  │              │              │              │
  │              │ ◄──Success───│ ◄──Result────│
  │              │              │              │
  │ ◄──Confirm───│              │              │
  │              │              │              │
  │──true────►   │              │              │
     (NVM)
```

### 3.2 Emergency Alert Flow
```
ESP32          iOS App        Go Server       APNs         Contacts
  │              │              │              │              │
  │──Touch──►    │              │              │              │
  │              │              │              │              │
  │──BLE Alert──►│              │              │              │
  │              │              │              │              │
  │              │──Emergency──►│              │              │
  │              │   Request    │              │              │
  │              │              │──Lookup────► │              │
  │              │              │   Devices    │              │
  │              │              │              │              │
  │              │              │──Push Req──► │              │
  │              │              │              │              │
  │              │              │              │──Notify────► │
  │              │              │              │              │
  │              │ ◄──Response──│ ◄──Status────│              │
  │              │              │              │              │
  │ ◄──Confirm───│              │              │              │
```

### 3.3 Contact Management Flow (Auth Code)
```
User A         iOS App A      Go Server      iOS App B      User B
  │              │              │              │              │
  │──Generate──► │              │              │              │
  │   Code       │              │              │              │
  │              │──Create────► │              │              │
  │              │   Auth Code  │              │              │
  │              │              │──Save───►DB  │              │
  │              │              │              │              │
  │              │ ◄──Code──────│              │              │
  │              │   Response   │              │              │
  │ ◄──Display───│              │              │              │
  │   "123456"   │              │              │              │
  │              │              │              │              │
  │──Share Code────────────────────────────────────────────► │
  │              │              │              │              │
  │              │              │              │ ◄──Enter─────│
  │              │              │              │   "123456"   │
  │              │              │              │              │
  │              │              │ ◄──Lookup────│              │
  │              │              │   Auth Code  │              │
  │              │              │              │              │
  │              │              │──Return────► │              │
  │              │              │   Device Info│              │
  │              │              │              │              │
  │              │              │              │──Add to──────│
  │              │              │              │   Contacts   │
```

### 3.4 BLE Communication Flow
```
ESP32                          iOS App
  │                              │
  │──Advertisement──────────────►│
  │   (Service UUID)             │
  │                              │
  │ ◄──Connection Request────────│
  │                              │
  │──Service Discovery Response──►
  │   (Characteristics)          │
  │                              │
  │ ◄──Subscribe to Notifications│
  │                              │
  │──Initial Device Info────────►│
  │   "{uuid},{registered}"      │
  │                              │
  │ ◄──Registration Request──────│ (if needed)
  │                              │
  │──Updated Device Info────────►│
  │   "{uuid},true"              │
  │                              │
  │──Emergency Notification─────►│ (on touch)
  │   "1"                        │
  │                              │
  │──Emergency Clear────────────►│ (after timeout)
  │   "0"                        │
```

---

## 4. Data Flow Diagrams

### 4.1 Emergency Alert Data Flow
```
Touch Sensor ──► ESP32 State Machine ──► BLE Notification ──► iOS Emergency Manager
                                                                      │
                                                                      ▼
Emergency Contacts ◄── HTTP Request ◄── Go Server Router ◄── JSON Payload
        │                                    │
        │                                    ▼
        │                            Database Lookup
        │                            (Device Records)
        │                                    │
        ▼                                    ▼
    iOS Devices ◄── APNs Push Notification ◄── APNs Client
```

### 4.2 Contact Management Data Flow
```
Auth Code Generation:
User Request ──► ContactManager ──► HTTP POST ──► Go Handler ──► Database ──► Response

Contact Lookup:
Auth Code ──► HTTP GET ──► Go Handler ──► Database Query ──► Device Info ──► Response

Contact Addition:
Device Info ──► EmergencyContact ──► Local Storage (UserDefaults) ──► Emergency System
```

---

## 5. Database Schema

### 5.1 SQLite Schema (GORM Auto-Generated)
```sql
-- devices table
CREATE TABLE devices (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    device_id TEXT UNIQUE NOT NULL,        -- 13-char SIREN Ring UUID
    user_id TEXT NOT NULL,                 -- User identifier
    device_name TEXT NOT NULL,             -- "SIREN Ring"
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- auth_codes table
CREATE TABLE auth_codes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    code TEXT UNIQUE NOT NULL,             -- 6-digit auth code
    device_id INTEGER NOT NULL,            -- FK to devices.id
    device_name TEXT NOT NULL,             -- Display name
    user_id TEXT NOT NULL,                 -- Code generator
    expires_at DATETIME NOT NULL,          -- Expiration time
    is_active BOOLEAN DEFAULT TRUE,        -- Active status
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (device_id) REFERENCES devices(id)
);

-- emergency_contacts table
CREATE TABLE emergency_contacts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,                    -- Contact name
    phone_number TEXT,                     -- SMS fallback
    device_id INTEGER,                     -- FK to devices.id (for app contacts)
    auth_code_id INTEGER,                  -- FK to auth_codes.id (sharing flow)
    user_id TEXT NOT NULL,                 -- Contact owner
    has_app BOOLEAN DEFAULT FALSE,         -- SIREN app installed
    is_connected BOOLEAN DEFAULT FALSE,    -- Connection status
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (device_id) REFERENCES devices(id),
    FOREIGN KEY (auth_code_id) REFERENCES auth_codes(id)
);

-- emergency_alerts table (audit log)
CREATE TABLE emergency_alerts (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    device_id INTEGER NOT NULL,           -- FK to devices.id
    alert_type TEXT NOT NULL,             -- "siren_ring_activation"
    message TEXT NOT NULL,                -- Alert message
    priority TEXT NOT NULL,               -- "critical"
    contacts_notified INTEGER DEFAULT 0,  -- Success count
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (device_id) REFERENCES devices(id)
);
```

### 5.2 Relationship Diagram
```
┌─────────────┐      1:N      ┌─────────────┐      1:N      ┌─────────────┐
│   Device    │◄─────────────►│  AuthCode   │◄─────────────►│ Emergency   │
│             │               │             │          0:1  │  Contact    │
│ id (PK)     │               │ id (PK)     │               │             │
│ device_id   │               │ code        │               │ id (PK)     │
│ user_id     │               │ device_id   │               │ name        │
│ device_name │               │ expires_at  │               │ phone_num   │
└─────────────┘               │ is_active   │               │ device_id   │
       │                      └─────────────┘               │ auth_code_id│
       │                                                    │ user_id     │
       │ 1:N                                                └─────────────┘
       ▼
┌─────────────┐
│ Emergency   │
│   Alert     │
│             │
│ id (PK)     │
│ device_id   │
│ alert_type  │
│ message     │
│ created_at  │
└─────────────┘
```

---

## 6. API Specifications

### 6.1 Device Registration
```
POST /api/register-token
Content-Type: application/json

Request:
{
    "device_id": "6cc8408663584",     // 13-char SIREN Ring UUID
    "user_id": "user123",             // User identifier
    "device_name": "SIREN Ring"       // Display name
}

Response:
{
    "success": true,
    "message": "Device token registered successfully"
}
```

### 6.2 Emergency Alert
```
POST /api/emergency
Content-Type: application/json

Request:
{
    "emergency_type": "siren_ring_activation",
    "timestamp": "2025-09-17T01:03:50Z",
    "user_id": "6cc8408663584",       // SIREN Ring UUID (sender)
    "device_ids": [                  // Emergency contacts' device IDs
        "abc123test456",
        "def456test789"
    ],
    "phone_numbers": [               // SMS fallback numbers
        "+1234567890"
    ],
    "message": "EMERGENCY ALERT - SIREN Ring activated. Please check on me immediately.",
    "priority": "critical"
}

Response:
{
    "success": true,
    "message": "Sent emergency notifications to 2/2 devices"
}
```

### 6.3 Auth Code Generation
```
POST /api/auth-code
Content-Type: application/json

Request:
{
    "device_id": "6cc8408663584",     // SIREN Ring UUID
    "device_name": "SIREN Ring",     // Display name
    "user_id": "user123",             // Code generator
    "expires_in": 10                  // Minutes (default: 10)
}

Response:
{
    "success": true,
    "message": "Authentication code created successfully",
    "data": {
        "code": "123456",             // 6-digit code
        "expires_at": "2025-09-17T01:13:50Z"
    }
}
```

### 6.4 Auth Code Lookup
```
GET /api/auth-code?code=123456

Response:
{
    "success": true,
    "message": "Contact information retrieved successfully",
    "data": {
        "device_id": "6cc8408663584",   // SIREN Ring UUID
        "device_name": "SIREN Ring"     // Display name
    }
}
```

### 6.5 Add Emergency Contact
```
POST /api/contacts
Content-Type: application/json

Request (via auth code):
{
    "name": "John Doe",
    "phone_number": "+1234567890",    // Optional SMS fallback
    "auth_code": "123456",            // Sharing flow
    "user_id": "user123"
}

Request (direct device):
{
    "name": "Jane Doe",
    "device_id": "abc123test456",     // Direct device registration
    "user_id": "user123"
}

Response:
{
    "success": true,
    "message": "Emergency contact added successfully",
    "data": {
        "id": 1,
        "name": "John Doe",
        "phone_number": "+1234567890",
        "device_id": 1,
        "has_app": true,
        "is_connected": true
    }
}
```

### 6.6 Health Check
```
GET /health

Response:
{
    "success": true,
    "message": "SIREN server is healthy"
}
```

---

## 7. Technical Implementation Details

### 7.1 ESP32 Hardware Configuration
```cpp
// GPIO Pin Assignments
#define TOUCH_SENSOR_PIN    21    // Touch sensor input
#define BUZZER_1_PIN        18    // Primary buzzer output
#define BUZZER_2_PIN        19    // Secondary buzzer output

// Touch Sensor Configuration
#define TOUCH_THRESHOLD     30    // Touch detection threshold
#define DEBOUNCE_DELAY      25    // Debounce time (ms)
#define TOUCH_DURATION      2000  // Long press duration (ms)

// Audio Configuration
#define ALARM_FREQUENCY     4000  // 4kHz alarm tone
#define ALARM_DURATION      5000  // 5 second alarm
#define PWM_RESOLUTION      8     // 8-bit PWM resolution
#define PWM_FREQUENCY       5000  // 5kHz PWM frequency
```

### 7.2 Touch Sensor State Machine
```cpp
enum TouchState {
    IDLE,           // No touch detected
    TOUCHED,        // Initial touch registered
    HELD,           // Touch held for duration
    EMERGENCY       // Emergency triggered
};

void checkTouch() {
    int touchValue = touchRead(TOUCH_SENSOR_PIN);
    unsigned long currentTime = millis();

    switch (touchState) {
        case IDLE:
            if (touchValue < TOUCH_THRESHOLD) {
                touchState = TOUCHED;
                lastTouchTime = currentTime;
            }
            break;

        case TOUCHED:
            if (touchValue >= TOUCH_THRESHOLD) {
                // Touch released too early
                touchState = IDLE;
            } else if (currentTime - lastTouchTime >= TOUCH_DURATION) {
                // Touch held long enough - trigger emergency
                touchState = EMERGENCY;
                triggerEmergency();
            }
            break;

        case EMERGENCY:
            // Emergency active - waiting for timeout or manual reset
            if (currentTime - lastTouchTime >= ALARM_DURATION) {
                touchState = IDLE;
                stopAlarm();
            }
            break;
    }
}
```

### 7.3 Device UUID Generation Algorithm
```cpp
String generateDeviceUUID() {
    uint8_t mac[6];
    esp_read_mac(mac, ESP_MAC_WIFI_STA);

    // Generate 13-character UUID from MAC address
    char uuid[14];
    snprintf(uuid, sizeof(uuid), "%02x%02x%02x%02x%02x%02x%01x",
             mac[0], mac[1], mac[2], mac[3], mac[4], mac[5],
             (mac[0] ^ mac[1] ^ mac[2]) & 0xF);  // Checksum digit

    return String(uuid);
}
```

### 7.4 BLE Service Implementation
```cpp
class SirenBLECallbacks: public BLEServerCallbacks {
    void onConnect(BLEServer* pServer) {
        Serial.println("Client connected");
        updateDeviceInfo();  // Send current status
    }

    void onDisconnect(BLEServer* pServer) {
        Serial.println("Client disconnected");
        startAdvertising();  // Resume advertising
    }
};

void initBLE() {
    BLEDevice::init("SIREN Ring");
    pServer = BLEDevice::createServer();
    pServer->setCallbacks(new SirenBLECallbacks());

    // Create service
    pService = pServer->createService(SERVICE_UUID);

    // Emergency characteristic (READ, NOTIFY)
    pEmergencyChar = pService->createCharacteristic(
        EMERGENCY_CHAR_UUID,
        BLECharacteristic::PROPERTY_READ |
        BLECharacteristic::PROPERTY_NOTIFY
    );

    // Device info characteristic (READ, NOTIFY)
    pDeviceInfoChar = pService->createCharacteristic(
        DEVICE_INFO_CHAR_UUID,
        BLECharacteristic::PROPERTY_READ |
        BLECharacteristic::PROPERTY_NOTIFY
    );

    pService->start();
    startAdvertising();
}
```

### 7.5 iOS Core Bluetooth Implementation
```swift
func centralManager(_ central: CBCentralManager,
                   didDiscover peripheral: CBPeripheral,
                   advertisementData: [String : Any],
                   rssi RSSI: NSNumber) {

    // Look for SIREN Ring devices
    if let name = peripheral.name, name.contains("SIREN") {
        discoveredPeripheral = peripheral
        centralManager.stopScan()
        centralManager.connect(peripheral, options: nil)
    }
}

func peripheral(_ peripheral: CBPeripheral,
               didUpdateValueFor characteristic: CBCharacteristic,
               error: Error?) {

    guard let data = characteristic.value else { return }

    if characteristic.uuid == CBUUID(string: EMERGENCY_CHAR_UUID) {
        // Emergency status update
        let emergencyStatus = data.first ?? 0
        DispatchQueue.main.async {
            self.emergencyActive = emergencyStatus == 1
            if self.emergencyActive {
                EmergencyManager.shared.sendEmergencyAlert()
            }
        }
    } else if characteristic.uuid == CBUUID(string: DEVICE_INFO_CHAR_UUID) {
        // Device info update
        if let deviceInfo = String(data: data, encoding: .utf8) {
            let components = deviceInfo.split(separator: ",")
            if components.count == 2 {
                DispatchQueue.main.async {
                    self.deviceUUID = String(components[0])
                    self.showRegistrationButton = components[1] == "false"
                }
            }
        }
    }
}
```

### 7.6 Go Server Configuration
```go
type Config struct {
    Port        string `env:"PORT" envDefault:"8080"`
    HTTPSPort   string `env:"HTTPS_PORT" envDefault:"8443"`
    DatabaseURL string `env:"DATABASE_URL" envDefault:"./siren.db"`
    APNSMode    string `env:"APNS_MODE" envDefault:"mock"`
    APNSKeyPath string `env:"APNS_KEY_PATH" envDefault:""`
    APNSKeyID   string `env:"APNS_KEY_ID" envDefault:""`
    APNSTeamID  string `env:"APNS_TEAM_ID" envDefault:""`
    BundleID    string `env:"BUNDLE_ID" envDefault:"SirenRing"`
}

func main() {
    // Initialize database with auto-migrations
    db, err := database.NewDatabase(config.DatabaseURL)
    if err != nil {
        log.Fatal("Failed to initialize database:", err)
    }
    defer db.Close()

    // Initialize APNs client
    apnsClient, err := apns.NewAPNSClient(config.APNSMode, config)
    if err != nil {
        log.Fatal("Failed to initialize APNS client:", err)
    }

    // Setup routes
    router := handlers.NewRouter(db, apnsClient)
    router.SetupRoutes()

    // Start servers
    go startHTTPSServer(config.HTTPSPort)
    startHTTPServer(config.Port)
}
```

### 7.7 APNS Integration
```go
type APNSClient struct {
    client   *apns2.Client
    bundleID string
    mock     bool
}

func (a *APNSClient) SendNotification(deviceToken, message string, critical bool) error {
    if a.mock {
        log.Printf("MOCK: Sending notification to %s: %s",
                  deviceToken[:min(10, len(deviceToken))]+"...", message)
        return nil
    }

    notification := &apns2.Notification{
        DeviceToken: deviceToken,
        Topic:       a.bundleID,
        Payload: map[string]interface{}{
            "aps": map[string]interface{}{
                "alert": map[string]interface{}{
                    "title": "EMERGENCY ALERT",
                    "body":  message,
                },
                "sound": map[string]interface{}{
                    "critical": critical ? 1 : 0,
                    "name":     "default",
                    "volume":   1.0,
                },
                "badge": 1,
            },
        },
    }

    if critical {
        notification.Priority = apns2.PriorityHigh
    }

    res, err := a.client.Push(notification)
    if err != nil {
        return fmt.Errorf("failed to send push notification: %v", err)
    }

    if !res.Sent() {
        return fmt.Errorf("notification not sent: %v", res.Reason)
    }

    return nil
}
```

---

## 8. Security & Performance Considerations

### 8.1 Security Features
- **Hardware-derived UUIDs**: Device UUIDs generated from MAC addresses prevent spoofing
- **Time-limited auth codes**: 10-minute expiration prevents code reuse attacks
- **HTTPS/TLS encryption**: All server communication encrypted in production
- **Input validation**: All API endpoints validate and sanitize input data
- **Database constraints**: Foreign key relationships prevent orphaned records

### 8.2 Performance Optimizations
- **BLE connection management**: Automatic reconnection and advertising resumption
- **Database indexing**: Primary and foreign key indexes for fast lookups
- **Background cleanup**: Periodic removal of expired auth codes
- **Local caching**: iOS app caches emergency contacts locally
- **APNs batching**: Server can batch multiple notifications efficiently

### 8.3 Scalability Design
- **Stateless server design**: No session state stored on server
- **Database connection pooling**: GORM manages connection lifecycle
- **Horizontal scaling ready**: Server instances can run independently
- **CDN-ready static assets**: Architecture supports edge deployment
- **Monitoring hooks**: Health endpoints for load balancer integration

---

## 9. Error Handling & Recovery

### 9.1 ESP32 Fault Recovery
- **Watchdog timer**: Hardware watchdog prevents infinite loops
- **BLE reconnection**: Automatic advertising restart on disconnect
- **Configuration recovery**: NVM corruption detection and reset
- **Hardware abstraction**: Function pointers enable easy testing/mocking

### 9.2 iOS App Resilience
- **Core Bluetooth state management**: Handles Bluetooth on/off scenarios
- **Network retry logic**: HTTP requests automatically retry with backoff
- **Local data persistence**: Emergency contacts survive app restarts
- **Background processing**: Critical notifications processed in background

### 9.3 Server Fault Tolerance
- **Database transaction management**: GORM handles rollbacks automatically
- **APNs failure handling**: Graceful degradation when push service unavailable
- **Request timeout handling**: Prevents resource exhaustion
- **Structured logging**: Comprehensive error tracking and debugging

---

This documentation provides a complete technical specification for implementing the SIREN emergency alert system. Each component is fully documented with implementation details, data formats, communication protocols, and architectural patterns required for professional development.