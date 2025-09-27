import Foundation
import CoreBluetooth
import UserNotifications

/// Manages Bluetooth connectivity with SIREN Ring device and handles emergency alerts
class BluetoothManager: NSObject, ObservableObject {
    static let shared = BluetoothManager()

    @Published var isConnected = false
    @Published var connectionStatus = "Disconnected"
    @Published var emergencyActive = false
    @Published var lastAlert = "No alerts"
    @Published var deviceUUID: String = ""
    @Published var showRegistrationButton = false
    @Published var mySirenRing: String = "" // Paired device identifier
    @Published var userName: String = ""
    @Published var customDeviceName: String = ""

    private var centralManager: CBCentralManager!
    private var sirenPeripheral: CBPeripheral?
    private var emergencyCharacteristic: CBCharacteristic?
    private var deviceInfoCharacteristic: CBCharacteristic?

    // Service and Characteristic UUIDs (matching ESP32)
    private let serviceUUID = CBUUID(string: "12345678-1234-1234-1234-123456789abc")
    private let emergencyCharUUID = CBUUID(string: "87654321-4321-4321-4321-cba987654321")
    private let deviceInfoCharUUID = CBUUID(string: "11111111-2222-3333-4444-555555555555")
    
    private override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        loadPairedDevice()
    }

    /// Save paired device UUID to UserDefaults
    private func savePairedDevice(_ deviceUUID: String) {
        UserDefaults.standard.set(deviceUUID, forKey: "paired_siren_ring")
        mySirenRing = deviceUUID
        print("💾 Saved paired SIREN Ring: \(deviceUUID)")
    }

    /// Load paired device UUID from UserDefaults
    private func loadPairedDevice() {
        if let pairedDevice = UserDefaults.standard.string(forKey: "paired_siren_ring") {
            mySirenRing = pairedDevice
            print("📱 Loaded paired SIREN Ring: \(pairedDevice)")
        }
    }

    /// Clear paired device (unpair)
    private func clearPairedDevice() {
        UserDefaults.standard.removeObject(forKey: "paired_siren_ring")
        mySirenRing = ""
        print("🗑️ Cleared paired SIREN Ring")
    }
    
    /// Starts scanning for SIREN Ring devices
    func startScanning() {
        if centralManager.state == .poweredOn {
            // If we have a paired device, try to connect directly to it
            if !mySirenRing.isEmpty {
                connectionStatus = "Connecting to My SIREN Ring..."
                print("🔍 Looking for paired device: \(mySirenRing)")
            } else {
                connectionStatus = "Scanning for SIREN Rings..."
                print("🔍 Scanning for available SIREN Rings...")
            }
            centralManager.scanForPeripherals(withServices: nil, options: nil)
        }
    }
    
    /// Stops scanning for devices
    func stopScanning() {
        centralManager.stopScan()
        connectionStatus = "Scan stopped"
    }
    
    /// Disconnects from current SIREN Ring device
    func disconnect() {
        if let peripheral = sirenPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }

    /// Manually registers the connected device with the server
    func registerDevice() {
        guard !deviceUUID.isEmpty else {
            print("❌ No device UUID available for registration")
            return
        }

        connectionStatus = "Registering device..."
        registerDeviceWithServer(uuid: deviceUUID)
    }

    /// Deregisters the ESP32 device by sending BLE false signal
    func deregisterDevice() {
        guard !deviceUUID.isEmpty else {
            print("❌ No device UUID available for deregistration")
            return
        }

        connectionStatus = "Deregistering device..."

        // Send false signal to ESP32 to mark as not registered
        sendRegistrationConfirmation(success: false)

        // Update UI
        DispatchQueue.main.async {
            self.showRegistrationButton = true
            self.connectionStatus = "Device connected - Not registered"
        }
    }
    
    /// Handles emergency alert codes from SIREN Ring device
    /// - Parameter code: Emergency code (1 = activate, 0 = deactivate)
    private func handleEmergencyAlert(code: UInt8) {
        let timestamp = DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium)
        
        if code == 1 {
            // EMERGENCY ON
            emergencyActive = true
            lastAlert = "EMERGENCY ACTIVE - \(timestamp)"
            triggerEmergencyResponse()
        } else if code == 0 {
            // EMERGENCY OFF
            emergencyActive = false
            lastAlert = "Emergency stopped - \(timestamp)"
            cancelEmergencyResponse()
        }
    }
    
    /// Triggers emergency response including notifications and alerts
    private func triggerEmergencyResponse() {
        // Send local notification
        sendEmergencyNotification()
        
        // TODO: Location and SMS functionality commented out for now
        // LocationManager.shared.getCurrentLocation { location in
        //     DispatchQueue.main.async {
        //         EmergencyManager.shared.sendEmergencyAlert(location: location)
        //     }
        // }
        
        // For now, just trigger without location
        EmergencyManager.shared.sendEmergencyAlert()
    }
    
    /// Cancels emergency response and pending notifications
    private func cancelEmergencyResponse() {
        // Cancel any pending emergency actions
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    /// Sends local emergency notification to device
    private func sendEmergencyNotification() {
        let content = UNMutableNotificationContent()
        content.title = "SIREN RING EMERGENCY"
        content.body = "Emergency alert triggered! Notifying emergency contacts."
        content.sound = .defaultCritical
        
        let request = UNNotificationRequest(identifier: "siren-emergency", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
}

// MARK: - CBCentralManagerDelegate
extension BluetoothManager: CBCentralManagerDelegate {
    
    /// Handles Bluetooth state changes
    /// - Parameter central: CBCentralManager instance
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            connectionStatus = "Bluetooth ready"
        case .poweredOff:
            connectionStatus = "Bluetooth off"
        case .unauthorized:
            connectionStatus = "Bluetooth unauthorized"
        default:
            connectionStatus = "Bluetooth unavailable"
        }
    }
    
    /// Handles discovery of peripherals during scanning
    /// - Parameters:
    ///   - central: CBCentralManager instance
    ///   - peripheral: Discovered peripheral
    ///   - advertisementData: Advertisement data from peripheral
    ///   - RSSI: Signal strength indicator
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if peripheral.name == "SIREN-Ring" {
            print("🔍 Discovered SIREN Ring: \(peripheral.identifier)")

            // If we have a paired device, only connect to that specific one
            if !mySirenRing.isEmpty {
                // We'll check the actual device UUID after connecting to see if it matches
                connectionStatus = "Checking My SIREN Ring..."
                centralManager.stopScan()
                sirenPeripheral = peripheral
                peripheral.delegate = self
                centralManager.connect(peripheral, options: nil)
            } else {
                // No paired device - connect to any available unregistered ring
                connectionStatus = "Found SIREN Ring"
                centralManager.stopScan()
                sirenPeripheral = peripheral
                peripheral.delegate = self
                centralManager.connect(peripheral, options: nil)
            }
        }
    }
    
    /// Handles successful connection to peripheral
    /// - Parameters:
    ///   - central: CBCentralManager instance
    ///   - peripheral: Connected peripheral
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectionStatus = "Connected"
        isConnected = true
        peripheral.discoverServices([serviceUUID])
    }
    
    /// Handles peripheral disconnection
    /// - Parameters:
    ///   - central: CBCentralManager instance
    ///   - peripheral: Disconnected peripheral
    ///   - error: Optional disconnection error
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectionStatus = "Disconnected"
        isConnected = false
        sirenPeripheral = nil
        emergencyCharacteristic = nil
        deviceInfoCharacteristic = nil
        // Keep deviceUUID, isDeviceRegistered, and needsRegistration - these persist!
    }
}

// MARK: - CBPeripheralDelegate
extension BluetoothManager: CBPeripheralDelegate {
    
    /// Handles service discovery on connected peripheral
    /// - Parameters:
    ///   - peripheral: CBPeripheral instance
    ///   - error: Optional discovery error
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            if service.uuid == serviceUUID {
                peripheral.discoverCharacteristics([emergencyCharUUID, deviceInfoCharUUID], for: service)
            }
        }
    }
    
    /// Handles characteristic discovery for a service
    /// - Parameters:
    ///   - peripheral: CBPeripheral instance
    ///   - service: CBService that discovered characteristics
    ///   - error: Optional discovery error
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }

        for characteristic in characteristics {
            if characteristic.uuid == emergencyCharUUID {
                emergencyCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
                connectionStatus = "Connected - listening for emergencies"
            } else if characteristic.uuid == deviceInfoCharUUID {
                deviceInfoCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
                // Read the device UUID immediately
                peripheral.readValue(for: characteristic)
            }
        }
    }
    
    /// Handles characteristic value updates from peripheral
    /// - Parameters:
    ///   - peripheral: CBPeripheral instance
    ///   - characteristic: CBCharacteristic that updated
    ///   - error: Optional update error
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid == emergencyCharUUID {
            // Handle emergency alerts
            guard let data = characteristic.value else { return }
            if let emergencyCode = data.first {
                handleEmergencyAlert(code: emergencyCode)
            }
        } else if characteristic.uuid == deviceInfoCharUUID {
            // Handle device info (UUID + registration status)
            guard let data = characteristic.value,
                  let dataString = String(data: data, encoding: .utf8) else {
                print("❌ No data received from device info characteristic")
                return
            }

            print("📱 Raw data received from ESP32: '\(dataString)'")

            let parts = dataString.components(separatedBy: ",")
            print("📱 Data parts: \(parts)")

            guard parts.count == 2,
                  let isRegistered = Bool(parts[1]) else {
                print("❌ Invalid data format. Expected 'uuid,true/false' but got: '\(dataString)'")
                return
            }

            let uuid = parts[0]

            DispatchQueue.main.async {
                self.deviceUUID = uuid
                print("📱 Parsed device info: UUID=\(uuid), isRegistered=\(isRegistered)")

                // Check if this is our paired device or if we need to pair
                if !self.mySirenRing.isEmpty && self.mySirenRing != uuid {
                    // This is not our paired device - disconnect
                    self.connectionStatus = "Wrong SIREN Ring - Disconnecting"
                    self.disconnect()
                    return
                }

                if !isRegistered {
                    self.connectionStatus = "Device connected - Not registered"
                    self.showRegistrationButton = true
                } else {
                    // Device is registered - save as paired device if not already saved
                    if self.mySirenRing.isEmpty {
                        self.savePairedDevice(uuid)
                    }
                    self.connectionStatus = "My SIREN Ring ready"
                    self.showRegistrationButton = false
                }
            }
        }
    }


    /// Registers the ESP32 device with the Go server
    /// - Parameter uuid: The device UUID from ESP32
    private func registerDeviceWithServer(uuid: String) {
        let serverURL = "http://192.168.1.6:8080/api/register-device"

        guard let url = URL(string: serverURL) else {
            print("Invalid server URL")
            return
        }

        let deviceData = [
            "device_id": uuid,
            "user_id": userName.isEmpty ? "Default User" : userName,
            "device_name": customDeviceName.isEmpty ? "SIREN Ring" : customDeviceName,
            "apns_token": NotificationManager.shared.deviceToken ?? ""
        ]

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: deviceData)
        } catch {
            print("Failed to encode device data: \(error)")
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                print("Device registration failed: \(error)")
                return
            }

            if let httpResponse = response as? HTTPURLResponse {
                DispatchQueue.main.async {
                    if httpResponse.statusCode == 200 {
                        print("✅ Device registered with server")
                        // Save this device as our paired SIREN Ring
                        self.savePairedDevice(uuid)
                        self.connectionStatus = "My SIREN Ring ready"
                        self.showRegistrationButton = false

                        // Send registration success back to ESP32
                        self.sendRegistrationConfirmation(success: true)
                    } else {
                        print("❌ Device registration failed with status: \(httpResponse.statusCode)")
                        self.connectionStatus = "Registration failed"

                        // Send registration failure back to ESP32
                        self.sendRegistrationConfirmation(success: false)
                    }
                }
            }
        }.resume()
    }

    /// Sends registration confirmation back to ESP32
    /// - Parameter success: Whether registration was successful
    private func sendRegistrationConfirmation(success: Bool) {
        guard let peripheral = sirenPeripheral,
              let characteristic = deviceInfoCharacteristic else { return }

        let confirmationData = success ? "true" : "false"
        peripheral.writeValue(confirmationData.data(using: .utf8)!,
                            for: characteristic,
                            type: .withResponse)
    }
    }

