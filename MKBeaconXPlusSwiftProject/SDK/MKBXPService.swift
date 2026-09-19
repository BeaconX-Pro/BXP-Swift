//
//  MKBXPService.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import Foundation

/// BXP 服务/特征 UUID 常量
public enum MKBXPService {

    // MARK: - eddyStone 配置服务
    public static let configServiceUUID = "a3c87500-8ed3-4bdf-8a39-a01bebede295"

    // MARK: - eddyStone 配置服务下面的特征
    public static let capabilitiesUUID = "a3c87501-8ed3-4bdf-8a39-a01bebede295"
    public static let activeSlotUUID = "a3c87502-8ed3-4bdf-8a39-a01bebede295"
    public static let advertisingIntervalUUID = "a3c87503-8ed3-4bdf-8a39-a01bebede295"
    public static let radioTxPowerUUID = "a3c87504-8ed3-4bdf-8a39-a01bebede295"
    public static let advertisedTxPowerUUID = "a3c87505-8ed3-4bdf-8a39-a01bebede295"
    public static let lockStateUUID = "a3c87506-8ed3-4bdf-8a39-a01bebede295"
    public static let unlockUUID = "a3c87507-8ed3-4bdf-8a39-a01bebede295"
    public static let publicECDHKeyUUID = "a3c87508-8ed3-4bdf-8a39-a01bebede295"
    public static let eidIdentityKeyUUID = "a3c87509-8ed3-4bdf-8a39-a01bebede295"
    public static let advSlotDataUUID = "a3c8750a-8ed3-4bdf-8a39-a01bebede295"
    public static let factoryResetUUID = "a3c8750b-8ed3-4bdf-8a39-a01bebede295"
    public static let remainConnectableUUID = "a3c8750c-8ed3-4bdf-8a39-a01bebede295"

    // MARK: - 厂商信息服务
    public static let deviceServiceUUID = "180a"

    // MARK: - 厂商信息服务下面的特征
    public static let modeIDUUID = "2a24"
    public static let productionDateUUID = "2a25"
    public static let firmwareUUID = "2a26"
    public static let hardwareUUID = "2a27"
    public static let softwareUUID = "2a28"
    public static let vendorUUID = "2a29"

    // MARK: - custom 配置服务
    public static let customServiceUUID = "e62a0001-1362-4f28-9327-f5b74e970801"

    // MARK: - custom 配置服务下面的特征
    public static let deviceTypeUUID = "e62a0004-1362-4f28-9327-f5b74e970801"
    public static let slotTypeUUID = "e62a0005-1362-4f28-9327-f5b74e970801"
    public static let batteryUUID = "e62a0006-1362-4f28-9327-f5b74e970801"
    public static let disconnectListenUUID = "e62a0007-1362-4f28-9327-f5b74e970801"
    public static let threeSensorUUID = "e62a0008-1362-4f28-9327-f5b74e970801"
    public static let temperatureHumidityUUID = "e62a0009-1362-4f28-9327-f5b74e970801"
    public static let recordTHUUID = "e62a000a-1362-4f28-9327-f5b74e970801"
    public static let writeUUID = "e62a0002-1362-4f28-9327-f5b74e970801"
    public static let notifyUUID = "e62a0003-1362-4f28-9327-f5b74e970801"
    public static let lightSensorUUID = "e62a000b-1362-4f28-9327-f5b74e970801"
    public static let lightStatusUUID = "e62a000c-1362-4f28-9327-f5b74e970801"

    public static let bxpCLTHDataUUID = "e62a000e-1362-4f28-9327-f5b74e970801"

    // MARK: - OTA 服务
    public static let otaServerUUIDString = "00001530-1212-EFDE-1523-785FEABCD123"
    public static let otaControlUUIDString = "00001531-1212-EFDE-1523-785FEABCD123"
    public static let otaDataUUIDString = "00001532-1212-EFDE-1523-785FEABCD123"
}
