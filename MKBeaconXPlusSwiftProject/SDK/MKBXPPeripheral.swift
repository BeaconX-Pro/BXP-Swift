//
//  MKBXPPeripheral.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import Foundation
@preconcurrency import CoreBluetooth
import MKSwiftBleModule

/// BXP 外设封装，实现 MKSwiftBlePeripheralProtocol
public final class MKBXPPeripheral: NSObject, MKSwiftBlePeripheralProtocol, @unchecked Sendable {

    private var _peripheral: CBPeripheral
    private let dfu: Bool

    public var peripheral: CBPeripheral { _peripheral }

    public init(peripheral: CBPeripheral, dfuMode: Bool) {
        self._peripheral = peripheral
        self.dfu = dfuMode
        super.init()
    }

    public func discoverServices() {
        let services: [CBUUID] = [
            CBUUID(string: MKBXPService.configServiceUUID),   // bxp 通用配置服务
            CBUUID(string: MKBXPService.customServiceUUID),  // custom 配置服务
            CBUUID(string: MKBXPService.deviceServiceUUID),  // 设备信息服务
            CBUUID(string: MKBXPService.otaServerUUIDString)  // OTA 服务
        ]
        _peripheral.discoverServices(services)
    }

    public func discoverCharacteristics() {
        guard let services = _peripheral.services else { return }
        for service in services {
            if service.uuid == CBUUID(string: MKBXPService.configServiceUUID) {
                let list: [CBUUID] = [
                    CBUUID(string: MKBXPService.capabilitiesUUID),
                    CBUUID(string: MKBXPService.activeSlotUUID),
                    CBUUID(string: MKBXPService.advertisingIntervalUUID),
                    CBUUID(string: MKBXPService.radioTxPowerUUID),
                    CBUUID(string: MKBXPService.advertisedTxPowerUUID),
                    CBUUID(string: MKBXPService.lockStateUUID),
                    CBUUID(string: MKBXPService.unlockUUID),
                    CBUUID(string: MKBXPService.publicECDHKeyUUID),
                    CBUUID(string: MKBXPService.eidIdentityKeyUUID),
                    CBUUID(string: MKBXPService.advSlotDataUUID),
                    CBUUID(string: MKBXPService.factoryResetUUID),
                    CBUUID(string: MKBXPService.remainConnectableUUID)
                ]
                _peripheral.discoverCharacteristics(list, for: service)
            } else if service.uuid == CBUUID(string: MKBXPService.customServiceUUID) {
                let characteristics: [CBUUID] = [
                    CBUUID(string: MKBXPService.writeUUID),
                    CBUUID(string: MKBXPService.notifyUUID),
                    CBUUID(string: MKBXPService.deviceTypeUUID),
                    CBUUID(string: MKBXPService.slotTypeUUID),
                    CBUUID(string: MKBXPService.batteryUUID),
                    CBUUID(string: MKBXPService.disconnectListenUUID),
                    CBUUID(string: MKBXPService.threeSensorUUID),
                    CBUUID(string: MKBXPService.temperatureHumidityUUID),
                    CBUUID(string: MKBXPService.recordTHUUID),
                    CBUUID(string: MKBXPService.lightSensorUUID),
                    CBUUID(string: MKBXPService.lightStatusUUID),
                    CBUUID(string: MKBXPService.bxpCLTHDataUUID)
                ]
                _peripheral.discoverCharacteristics(characteristics, for: service)
            } else if service.uuid == CBUUID(string: MKBXPService.deviceServiceUUID) {
                let characteristics: [CBUUID] = [
                    CBUUID(string: MKBXPService.modeIDUUID),
                    CBUUID(string: MKBXPService.firmwareUUID),
                    CBUUID(string: MKBXPService.productionDateUUID),
                    CBUUID(string: MKBXPService.hardwareUUID),
                    CBUUID(string: MKBXPService.softwareUUID),
                    CBUUID(string: MKBXPService.vendorUUID)
                ]
                _peripheral.discoverCharacteristics(characteristics, for: service)
            } else if service.uuid == CBUUID(string: MKBXPService.otaServerUUIDString) {
                let characteristics: [CBUUID] = [
                    CBUUID(string: MKBXPService.otaControlUUIDString),
                    CBUUID(string: MKBXPService.otaDataUUIDString)
                ]
                _peripheral.discoverCharacteristics(characteristics, for: service)
            }
        }
    }

    public func updateCharacter(with service: CBService) {
        _peripheral.bxp_updateCharacterWithService(service)
    }

    public func updateCurrentNotifySuccess(_ characteristic: CBCharacteristic) {
        _peripheral.bxp_updateCurrentNotifySuccess(characteristic)
    }

    public var connectSuccess: Bool {
        _peripheral.bxp_connectSuccess(dfu)
    }

    public func setNil() {
        _peripheral.bxp_setNil()
    }
}
