import CoreBluetooth

/// The central's side: finding, connecting and losing a ring.
extension RingLink: CBCentralManagerDelegate {
    /// centralManagerDidUpdateState goes back for a ring iOS restored, or reports ready.
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        guard central.state == .poweredOn else { return }
        if let ring, ring.state == .connected {
            centralManager(central, didConnect: ring)
        } else if ring != nil {
            reconnect()
        } else {
            events?.ready()
        }
    }

    /// willRestoreState takes back the ring iOS kept while the app was not running.
    func centralManager(_ central: CBCentralManager, willRestoreState dict: [String: Any]) {
        let kept = dict[CBCentralManagerRestoredStatePeripheralsKey] as? [CBPeripheral]
        ring = kept?.first
        ring?.delegate = self
    }

    /// didDiscover connects to the first ring not turned away this session.
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        guard !refused.contains(peripheral.identifier) else { return }
        central.stopScan()
        ring = peripheral
        peripheral.delegate = self
        central.connect(peripheral)
    }

    /// didConnect reports the link, then asks for the service; nothing is subscribed yet.
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        userLeft = false
        events?.linked()
        peripheral.discoverServices([Self.service])
    }

    /// didDisconnectPeripheral reports the loss and whether the user asked for it.
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral,
                        error: Error?) {
        forgetLink()
        events?.lost(userLeft: userLeft)
    }

    /// didFailToConnect is a loss the user did not ask for, so the gate decides what follows.
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        forgetLink()
        events?.lost(userLeft: false)
    }
}

/// The ring's side: its service, its two characteristics and what they send.
extension RingLink: CBPeripheralDelegate {
    /// didDiscoverServices asks only for the two SIREN characteristics.
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let service = peripheral.services?.first(where: { $0.uuid == Self.service }) else { return }
        peripheral.discoverCharacteristics([Self.emergency, Self.deviceInfo], for: service)
    }

    /// didDiscoverCharacteristicsFor keeps both and reads who the ring is; alerts wait for proof.
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService,
                    error: Error?) {
        for characteristic in service.characteristics ?? [] {
            if characteristic.uuid == Self.emergency { alerts = characteristic }
            if characteristic.uuid == Self.deviceInfo { info = characteristic }
        }
        if let info { peripheral.readValue(for: info) }
    }

    /// didUpdateValueFor hands each value over unvetted; RingGate decides what it means.
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic,
                    error: Error?) {
        if characteristic.uuid == Self.deviceInfo { events?.heardInfo(characteristic.value) }
        if characteristic.uuid == Self.emergency { events?.heardAlert(characteristic.value) }
    }
}
