//
//  CBPeripheral+MKBXDAdd.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import Foundation
@preconcurrency import CoreBluetooth

// MARK: - 关联对象 key
private var bxp_capabilitiesKey: UInt8 = 0
private var bxp_activeSlotKey: UInt8 = 0
private var bxp_advertisingIntervalKey: UInt8 = 0
private var bxp_radioTxPowerKey: UInt8 = 0
private var bxp_advertisedTxPowerKey: UInt8 = 0
private var bxp_lockStateKey: UInt8 = 0
private var bxp_unlockKey: UInt8 = 0
private var bxp_publicECDHKeyKey: UInt8 = 0
private var bxp_eidIdentityKeyKey: UInt8 = 0
private var bxp_advSlotDataKey: UInt8 = 0
private var bxp_factoryResetKey: UInt8 = 0
private var bxp_remainConnectableKey: UInt8 = 0

private var bxp_deviceTypeKey: UInt8 = 0
private var bxp_slotTypeKey: UInt8 = 0
private var bxp_disconnectListenKey: UInt8 = 0
private var bxp_batteryKey: UInt8 = 0
private var bxp_threeSensorKey: UInt8 = 0
private var bxp_temperatureHumidityKey: UInt8 = 0
private var bxp_recordTHKey: UInt8 = 0
private var bxp_customWriteKey: UInt8 = 0
private var bxp_customNotifyKey: UInt8 = 0
private var bxp_lightSensorKey: UInt8 = 0
private var bxp_lightStatusKey: UInt8 = 0
private var bxp_clTHDataKey: UInt8 = 0

private var bxp_vendorKey: UInt8 = 0
private var bxp_modeIDKey: UInt8 = 0
private var bxp_productionDateKey: UInt8 = 0
private var bxp_hardwareKey: UInt8 = 0
private var bxp_firmwareKey: UInt8 = 0
private var bxp_softwareKey: UInt8 = 0

private var bxp_otaControlKey: UInt8 = 0
private var bxp_otaDataKey: UInt8 = 0

private var bxp_customNotifySuccessKey: UInt8 = 0
private var bxp_disconnectListenSuccessKey: UInt8 = 0

// MARK: - CBPeripheral + BXP 特征管理
extension CBPeripheral {

    // MARK: - eddyStone 配置服务下的特征（只读）
    /// capabilities
    public var bxp_capabilities: CBCharacteristic? {
        objc_getAssociatedObject(self, &bxp_capabilitiesKey) as? CBCharacteristic
    }

    /// activeSlot
    public var bxp_activeSlot: CBCharacteristic? {
        objc_getAssociatedObject(self, &bxp_activeSlotKey) as? CBCharacteristic
    }

    /// advertisingInterval
    public var bxp_advertisingInterval: CBCharacteristic? {
        objc_getAssociatedObject(self, &bxp_advertisingIntervalKey) as? CBCharacteristic
    }

    /// radioTxPower
    public var bxp_radioTxPower: CBCharacteristic? {
        objc_getAssociatedObject(self, &bxp_radioTxPowerKey) as? CBCharacteristic
    }

    /// advertisedTxPower
    public var bxp_advertisedTxPower: CBCharacteristic? {
        objc_getAssociatedObject(self, &bxp_advertisedTxPowerKey) as? CBCharacteristic
    }

    /// lockState
    public var bxp_lockState: CBCharacteristic? {
        objc_getAssociatedObject(self, &bxp_lockStateKey) as? CBCharacteristic
    }

    /// unlock
    public var bxp_unlock: CBCharacteristic? {
        objc_getAssociatedObject(self, &bxp_unlockKey) as? CBCharacteristic
    }

    /// publicECDHKey
    public var bxp_publicECDHKey: CBCharacteristic? {
        objc_getAssociatedObject(self, &bxp_publicECDHKeyKey) as? CBCharacteristic
    }

    /// eidIdentityKey
    public var bxp_eidIdentityKey: CBCharacteristic? {
        objc_getAssociatedObject(self, &bxp_eidIdentityKeyKey) as? CBCharacteristic
    }

    /// advSlotData
    public var bxp_advSlotData: CBCharacteristic? {
        objc_getAssociatedObject(self, &bxp_advSlotDataKey) as? CBCharacteristic
    }

    /// factoryReset
    public var bxp_factoryReset: CBCharacteristic? {
        objc_getAssociatedObject(self, &bxp_factoryResetKey) as? CBCharacteristic
    }

    /// remainConnectable
    public var bxp_remainConnectable: CBCharacteristic? {
        objc_getAssociatedObject(self, &bxp_remainConnectableKey) as? CBCharacteristic
    }

    // MARK: - iBeacon 设置服务下的特征（只读）
    /// deviceType
    public var bxp_deviceType: CBCharacteristic? {
        objc_getAssociatedObject(self, &bxp_deviceTypeKey) as? CBCharacteristic
    }

    /// slotType
    public var bxp_slotType: CBCharacteristic? {
        objc_getAssociatedObject(self, &bxp_slotTypeKey) as? CBCharacteristic
    }

    /// disconnectListen
    public var bxp_disconnectListen: CBCharacteristic? {
        objc_getAssociatedObject(self, &bxp_disconnectListenKey) as? CBCharacteristic
    }

    /// battery
    public var bxp_battery: CBCharacteristic? {
        objc_getAssociatedObject(self, &bxp_batteryKey) as? CBCharacteristic
    }

    /// threeSensor
    public var bxp_threeSensor: CBCharacteristic? {
        objc_getAssociatedObject(self, &bxp_threeSensorKey) as? CBCharacteristic
    }

    /// temperatureHumidity
    public var bxp_temperatureHumidity: CBCharacteristic? {
        objc_getAssociatedObject(self, &bxp_temperatureHumidityKey) as? CBCharacteristic
    }

    /// recordTH
    public var bxp_recordTH: CBCharacteristic? {
        objc_getAssociatedObject(self, &bxp_recordTHKey) as? CBCharacteristic
    }

    /// customWrite
    public var bxp_customWrite: CBCharacteristic? {
        objc_getAssociatedObject(self, &bxp_customWriteKey) as? CBCharacteristic
    }

    /// customNotify
    public var bxp_customNotify: CBCharacteristic? {
        objc_getAssociatedObject(self, &bxp_customNotifyKey) as? CBCharacteristic
    }

    /// lightSensor
    public var bxp_lightSensor: CBCharacteristic? {
        objc_getAssociatedObject(self, &bxp_lightSensorKey) as? CBCharacteristic
    }

    /// lightStatus
    public var bxp_lightStatus: CBCharacteristic? {
        objc_getAssociatedObject(self, &bxp_lightStatusKey) as? CBCharacteristic
    }

    /// clTHData
    public var bxp_clTHData: CBCharacteristic? {
        objc_getAssociatedObject(self, &bxp_clTHDataKey) as? CBCharacteristic
    }

    // MARK: - 系统信息下的特征（只读）
    /// 厂商信息
    public var bxp_vendor: CBCharacteristic? {
        objc_getAssociatedObject(self, &bxp_vendorKey) as? CBCharacteristic
    }

    /// 产品型号
    public var bxp_modeID: CBCharacteristic? {
        objc_getAssociatedObject(self, &bxp_modeIDKey) as? CBCharacteristic
    }

    /// 生产日期
    public var bxp_productionDate: CBCharacteristic? {
        objc_getAssociatedObject(self, &bxp_productionDateKey) as? CBCharacteristic
    }

    /// 硬件版本
    public var bxp_hardware: CBCharacteristic? {
        objc_getAssociatedObject(self, &bxp_hardwareKey) as? CBCharacteristic
    }

    /// 固件版本
    public var bxp_firmware: CBCharacteristic? {
        objc_getAssociatedObject(self, &bxp_firmwareKey) as? CBCharacteristic
    }

    /// 软件版本
    public var bxp_software: CBCharacteristic? {
        objc_getAssociatedObject(self, &bxp_softwareKey) as? CBCharacteristic
    }

    // MARK: - OTA 特征
    public var bxp_otaData: CBCharacteristic? {
        objc_getAssociatedObject(self, &bxp_otaDataKey) as? CBCharacteristic
    }

    public var bxp_otaControl: CBCharacteristic? {
        objc_getAssociatedObject(self, &bxp_otaControlKey) as? CBCharacteristic
    }

    // MARK: - 业务方法

    /// 根据 service 更新对应特征引用，并对需要 notify 的特征开启 notify
    public func bxp_updateCharacterWithService(_ service: CBService) {
        if service.uuid == CBUUID(string: MKBXPService.configServiceUUID) {
            // eddyStone 通用配置服务
            bxp_updateEddystoneCharacteristic(service)
            return
        }
        if service.uuid == CBUUID(string: MKBXPService.customServiceUUID) {
            // 自定义配置服务
            bxp_updateCustomCharacteristic(service)
            return
        }
        if service.uuid == CBUUID(string: MKBXPService.deviceServiceUUID) {
            // 系统信息（软件版本、硬件版本等）
            bxp_updateDeviceInfoCharacteristic(service)
            return
        }
        if service.uuid == CBUUID(string: MKBXPService.otaServerUUIDString) {
            // OTA
            guard let characteristicList = service.characteristics else { return }
            for characteristic in characteristicList {
                if characteristic.uuid == CBUUID(string: MKBXPService.otaControlUUIDString) {
                    objc_setAssociatedObject(self, &bxp_otaControlKey, characteristic, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                } else if characteristic.uuid == CBUUID(string: MKBXPService.otaDataUUIDString) {
                    objc_setAssociatedObject(self, &bxp_otaDataKey, characteristic, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                }
            }
            return
        }
    }

    /// 标记 notify 启用成功
    public func bxp_updateCurrentNotifySuccess(_ characteristic: CBCharacteristic) {
        if characteristic.uuid == CBUUID(string: MKBXPService.notifyUUID) {
            objc_setAssociatedObject(self, &bxp_customNotifySuccessKey, NSNumber(value: true), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return
        }
        if characteristic.uuid == CBUUID(string: MKBXPService.disconnectListenUUID) {
            objc_setAssociatedObject(self, &bxp_disconnectListenSuccessKey, NSNumber(value: true), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            return
        }
    }

    /// 判断连接是否成功（dfu=true 仅校验 OTA 特征）
    public func bxp_connectSuccess(_ dfu: Bool) -> Bool {
        if dfu {
            guard bxp_otaData != nil, bxp_otaControl != nil else {
                return false
            }
            return true
        }

        let customNotifySuccess = (objc_getAssociatedObject(self, &bxp_customNotifySuccessKey) as? NSNumber)?.boolValue ?? false
        let disconnectListenSuccess = (objc_getAssociatedObject(self, &bxp_disconnectListenSuccessKey) as? NSNumber)?.boolValue ?? false

        if !customNotifySuccess || !disconnectListenSuccess {
            return false
        }
        if !bxp_serviceSuccess || !bxp_customServiceSuccess {
            return false
        }
        return true
    }

    /// 清空所有特征关联对象
    public func bxp_setNil() {
        objc_setAssociatedObject(self, &bxp_capabilitiesKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &bxp_activeSlotKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &bxp_advertisingIntervalKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &bxp_radioTxPowerKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &bxp_advertisedTxPowerKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &bxp_lockStateKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &bxp_unlockKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &bxp_publicECDHKeyKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &bxp_eidIdentityKeyKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &bxp_advSlotDataKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &bxp_factoryResetKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &bxp_remainConnectableKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        objc_setAssociatedObject(self, &bxp_deviceTypeKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &bxp_slotTypeKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &bxp_batteryKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        objc_setAssociatedObject(self, &bxp_disconnectListenKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &bxp_threeSensorKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &bxp_temperatureHumidityKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &bxp_recordTHKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &bxp_lightSensorKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &bxp_lightStatusKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &bxp_customNotifyKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &bxp_customWriteKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &bxp_clTHDataKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        objc_setAssociatedObject(self, &bxp_vendorKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &bxp_modeIDKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &bxp_hardwareKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &bxp_firmwareKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &bxp_softwareKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &bxp_productionDateKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        objc_setAssociatedObject(self, &bxp_otaControlKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &bxp_otaDataKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)

        objc_setAssociatedObject(self, &bxp_customNotifySuccessKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        objc_setAssociatedObject(self, &bxp_disconnectListenSuccessKey, nil, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
    }

    // MARK: - private method

    /// 更新 eddyStone 配置服务下的特征
    private func bxp_updateEddystoneCharacteristic(_ service: CBService) {
        guard let characteristicList = service.characteristics else { return }
        for characteristic in characteristicList {
            if characteristic.uuid == CBUUID(string: MKBXPService.capabilitiesUUID) {
                objc_setAssociatedObject(self, &bxp_capabilitiesKey, characteristic, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            } else if characteristic.uuid == CBUUID(string: MKBXPService.activeSlotUUID) {
                objc_setAssociatedObject(self, &bxp_activeSlotKey, characteristic, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            } else if characteristic.uuid == CBUUID(string: MKBXPService.advertisingIntervalUUID) {
                objc_setAssociatedObject(self, &bxp_advertisingIntervalKey, characteristic, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            } else if characteristic.uuid == CBUUID(string: MKBXPService.radioTxPowerUUID) {
                objc_setAssociatedObject(self, &bxp_radioTxPowerKey, characteristic, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            } else if characteristic.uuid == CBUUID(string: MKBXPService.advertisedTxPowerUUID) {
                objc_setAssociatedObject(self, &bxp_advertisedTxPowerKey, characteristic, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            } else if characteristic.uuid == CBUUID(string: MKBXPService.lockStateUUID) {
                objc_setAssociatedObject(self, &bxp_lockStateKey, characteristic, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            } else if characteristic.uuid == CBUUID(string: MKBXPService.unlockUUID) {
                objc_setAssociatedObject(self, &bxp_unlockKey, characteristic, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            } else if characteristic.uuid == CBUUID(string: MKBXPService.publicECDHKeyUUID) {
                objc_setAssociatedObject(self, &bxp_publicECDHKeyKey, characteristic, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            } else if characteristic.uuid == CBUUID(string: MKBXPService.eidIdentityKeyUUID) {
                objc_setAssociatedObject(self, &bxp_eidIdentityKeyKey, characteristic, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            } else if characteristic.uuid == CBUUID(string: MKBXPService.advSlotDataUUID) {
                objc_setAssociatedObject(self, &bxp_advSlotDataKey, characteristic, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            } else if characteristic.uuid == CBUUID(string: MKBXPService.factoryResetUUID) {
                objc_setAssociatedObject(self, &bxp_factoryResetKey, characteristic, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            } else if characteristic.uuid == CBUUID(string: MKBXPService.remainConnectableUUID) {
                objc_setAssociatedObject(self, &bxp_remainConnectableKey, characteristic, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }

    /// 更新自定义配置服务下的特征
    private func bxp_updateCustomCharacteristic(_ service: CBService) {
        guard let characteristicList = service.characteristics else { return }
        for characteristic in characteristicList {
            if characteristic.uuid == CBUUID(string: MKBXPService.writeUUID) {
                objc_setAssociatedObject(self, &bxp_customWriteKey, characteristic, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            } else if characteristic.uuid == CBUUID(string: MKBXPService.notifyUUID) {
                objc_setAssociatedObject(self, &bxp_customNotifyKey, characteristic, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                setNotifyValue(true, for: characteristic)
            } else if characteristic.uuid == CBUUID(string: MKBXPService.deviceTypeUUID) {
                objc_setAssociatedObject(self, &bxp_deviceTypeKey, characteristic, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            } else if characteristic.uuid == CBUUID(string: MKBXPService.slotTypeUUID) {
                objc_setAssociatedObject(self, &bxp_slotTypeKey, characteristic, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            } else if characteristic.uuid == CBUUID(string: MKBXPService.batteryUUID) {
                objc_setAssociatedObject(self, &bxp_batteryKey, characteristic, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            } else if characteristic.uuid == CBUUID(string: MKBXPService.disconnectListenUUID) {
                objc_setAssociatedObject(self, &bxp_disconnectListenKey, characteristic, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
                setNotifyValue(true, for: characteristic)
            } else if characteristic.uuid == CBUUID(string: MKBXPService.threeSensorUUID) {
                objc_setAssociatedObject(self, &bxp_threeSensorKey, characteristic, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            } else if characteristic.uuid == CBUUID(string: MKBXPService.temperatureHumidityUUID) {
                objc_setAssociatedObject(self, &bxp_temperatureHumidityKey, characteristic, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            } else if characteristic.uuid == CBUUID(string: MKBXPService.recordTHUUID) {
                objc_setAssociatedObject(self, &bxp_recordTHKey, characteristic, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            } else if characteristic.uuid == CBUUID(string: MKBXPService.lightSensorUUID) {
                objc_setAssociatedObject(self, &bxp_lightSensorKey, characteristic, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            } else if characteristic.uuid == CBUUID(string: MKBXPService.lightStatusUUID) {
                objc_setAssociatedObject(self, &bxp_lightStatusKey, characteristic, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            } else if characteristic.uuid == CBUUID(string: MKBXPService.bxpCLTHDataUUID) {
                objc_setAssociatedObject(self, &bxp_clTHDataKey, characteristic, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }

    /// 更新系统信息服务下的特征
    private func bxp_updateDeviceInfoCharacteristic(_ service: CBService) {
        guard let characteristicList = service.characteristics else { return }
        for characteristic in characteristicList {
            if characteristic.uuid == CBUUID(string: MKBXPService.modeIDUUID) {
                // 产品型号
                objc_setAssociatedObject(self, &bxp_modeIDKey, characteristic, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            } else if characteristic.uuid == CBUUID(string: MKBXPService.firmwareUUID) {
                // 固件版本
                objc_setAssociatedObject(self, &bxp_firmwareKey, characteristic, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            } else if characteristic.uuid == CBUUID(string: MKBXPService.productionDateUUID) {
                // 生产日期
                objc_setAssociatedObject(self, &bxp_productionDateKey, characteristic, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            } else if characteristic.uuid == CBUUID(string: MKBXPService.hardwareUUID) {
                // 硬件版本
                objc_setAssociatedObject(self, &bxp_hardwareKey, characteristic, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            } else if characteristic.uuid == CBUUID(string: MKBXPService.softwareUUID) {
                // 软件版本
                objc_setAssociatedObject(self, &bxp_softwareKey, characteristic, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            } else if characteristic.uuid == CBUUID(string: MKBXPService.vendorUUID) {
                // 厂商自定义
                objc_setAssociatedObject(self, &bxp_vendorKey, characteristic, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
            }
        }
    }

    /// 校验 eddyStone 配置服务特征是否齐全
    private var bxp_serviceSuccess: Bool {
        guard bxp_activeSlot != nil,
              bxp_advertisingInterval != nil,
              bxp_radioTxPower != nil,
              bxp_advertisedTxPower != nil,
              bxp_lockState != nil,
              bxp_unlock != nil,
              bxp_advSlotData != nil,
              bxp_factoryReset != nil else {
            return false
        }
        return true
    }

    /// 校验自定义配置服务特征是否齐全
    private var bxp_customServiceSuccess: Bool {
        guard bxp_customNotify != nil,
              bxp_customWrite != nil,
              bxp_deviceType != nil,
              bxp_slotType != nil,
              bxp_disconnectListen != nil,
              bxp_battery != nil else {
            return false
        }
        return true
    }

    /// 校验系统信息服务特征是否齐全
    private var bxp_deviceInfoServiceSuccess: Bool {
        guard bxp_vendor != nil,
              bxp_modeID != nil,
              bxp_hardware != nil,
              bxp_firmware != nil,
              bxp_software != nil,
              bxp_productionDate != nil else {
            return false
        }
        return true
    }
}
