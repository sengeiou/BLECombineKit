//
//  ContentViewModel.swift
//  BLECombineExplorer
//
//  Created by Henry Javier Serrano Echeverria on 2/5/20.
//  Copyright © 2020 Henry Serrano. All rights reserved.
//

import SwiftUI
import CoreBluetooth
import Combine
import BLECombineKit

final class DevicesViewModel: ObservableObject {
    
    @Published var peripherals = [ScannedPeripheralItem]()
    @Published var blePeripheralMap: [UUID: BLEScanResult] = [:]
    
    private let centralManager: BLECentralManager
    private var scanForPeripheralsCancellable: AnyCancellable?
    private var peripheralMap: [UUID: ScannedPeripheralItem] = [:]
    private var localPeripherals = [ScannedPeripheralItem]()
    private var canUpdate = true
    
    init(centralManager: BLECentralManager) {
        self.centralManager = centralManager
    }
    
    func startScanning() {
        scanForPeripheralsCancellable?.cancel()
        scanForPeripheralsCancellable = centralManager.scanForPeripherals(withServices: nil, options: nil)
            .sink(receiveCompletion: { completion in
                print(completion)
            }, receiveValue: { [weak self] scanResult in
                guard let self = self, self.canUpdate else { return }
                
                let identifier = scanResult.peripheral.peripheral.identifier

                self.blePeripheralMap[identifier] = scanResult
                
                let scannedPeripheralItem = ScannedPeripheralItem(rssi: scanResult.rssi.doubleValue,
                                      name: scanResult.peripheral.peripheral.name ?? "Unknown",
                                      identifier: scanResult.peripheral.peripheral.identifier)
                
                if let savedPeripheral = self.peripheralMap[identifier] {
                    if savedPeripheral.rssi != scannedPeripheralItem.rssi {
                        self.peripheralMap.updateValue(scannedPeripheralItem, forKey: identifier)
                        self.peripherals = self.peripheralMap.values.map { $0 }.sorted{ $0.rssi > $1.rssi }
                    }
                } else {
                    self.peripheralMap[identifier] = scannedPeripheralItem
                    self.peripherals = self.peripheralMap.values.map { $0 }.sorted{ $0.rssi > $1.rssi }
                }
            })
    }
    
    func stopScan() {
        centralManager.stopScan()
        canUpdate = false
    }
    
    struct Constants {
        static let serviceUUID = CBUUID.init(string: "19B10000-E8F2-537E-4F6C-D104768A1214")
    }
    
}

struct ScannedPeripheralItem {
    let rssi: Double
    let name: String
    let identifier: UUID
}
