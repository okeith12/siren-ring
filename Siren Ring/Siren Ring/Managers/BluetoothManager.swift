import Foundation
import CoreBluetooth
import UserNotifications

class BluetoothManager: NSObject, ObservableObject {
    
    @Published var isConnected = false
    @Published var connectionStatus = "Disconnected"
    @Published var emergencyActive = false
    @Published var lastAlert = "No alerts"
    
    private var centralManager: CBCentralManager!
    private var sirenPeripheral: CBPeripheral?
    private var sirenCharacteristic: CBCharacteristic?
    
    // Service and Characteristic UUIDs (matching esp32)
    private let serviceUUID = CBUUID(string: "12345678-1234-1234-1234-123456789abc")
    private let characteristicUUID = CBUUID(string: "87654321-4321-4321-4321-cba987654321")
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func startScanning() {
        if centralManager.state == .poweredOn {
            connectionStatus = "Scanning..."
            centralManager.scanForPeripherals(withServices: [serviceUUID], options: nil)
        }
    }
    
    func stopScanning() {
        centralManager.stopScan()
        connectionStatus = "Scan stopped"
    }
    
    func disconnect() {
        if let peripheral = sirenPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
    
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
    
    private func cancelEmergencyResponse() {
        // Cancel any pending emergency actions
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
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
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if peripheral.name == "SIREN-Ring" {
            connectionStatus = "Found SIREN Ring"
            centralManager.stopScan()
            sirenPeripheral = peripheral
            peripheral.delegate = self
            centralManager.connect(peripheral, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectionStatus = "Connected"
        isConnected = true
        peripheral.discoverServices([serviceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        connectionStatus = "Disconnected"
        isConnected = false
        sirenPeripheral = nil
        sirenCharacteristic = nil
    }
}

// MARK: - CBPeripheralDelegate
extension BluetoothManager: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            if service.uuid == serviceUUID {
                peripheral.discoverCharacteristics([characteristicUUID], for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            if characteristic.uuid == characteristicUUID {
                sirenCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
                connectionStatus = "Ready for emergency alerts"
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid == characteristicUUID {
            guard let data = characteristic.value else { return }
            
            if let emergencyCode = data.first {
                handleEmergencyAlert(code: emergencyCode)
            }
        }
    }
}
