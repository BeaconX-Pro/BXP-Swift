//
//  MKBXPScanPageAdopter.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import UIKit
@preconcurrency import CoreBluetooth
import MKBaseSwiftModule
import MKSwiftCustomUI
import MKSwiftBeaconXCustomUI

// MARK: - MKBXPScanPageAdopter

public enum MKBXPScanPageAdopter {

    // MARK: - 解析 Beacon 为 CellModel

    public static func parseBeaconDatas(_ beacon: MKBXPBaseBeacon) -> Any? {
        if let tempModel = beacon as? MKBXPiBeacon {
            let cellModel = MKSwiftBXScanBeaconCellModel()
            cellModel.rssi = "\(tempModel.rssi.intValue)"
            cellModel.rssi1M = "\(tempModel.rssi1M.intValue)"
            cellModel.txPower = "\(tempModel.txPower.intValue)"
            cellModel.interval = tempModel.interval
            cellModel.major = tempModel.major
            cellModel.minor = tempModel.minor
            cellModel.uuid = tempModel.uuid.lowercased()
            return cellModel
        }
        if let tempModel = beacon as? MKBXPTHSensorBeacon {
            let cellModel = MKSwiftBXScanHTCellModel()
            cellModel.rssi0M = "\(tempModel.rssi0M.intValue)"
            cellModel.txPower = "\(tempModel.txPower.intValue)"
            cellModel.interval = tempModel.interval
            cellModel.temperature = tempModel.temperature
            cellModel.humidity = tempModel.humidity
            return cellModel
        }
        if let tempModel = beacon as? MKBXPThreeASensorBeacon {
            let cellModel = MKSwiftBXScanThreeASensorCellModel()
            cellModel.rssi0M = "\(tempModel.rssi0M.intValue)"
            cellModel.txPower = "\(tempModel.txPower.intValue)"
            cellModel.interval = tempModel.interval
            cellModel.samplingRate = tempModel.samplingRate
            cellModel.accelerationOfGravity = tempModel.accelerationOfGravity
            cellModel.sensitivity = tempModel.sensitivity
            cellModel.xData = tempModel.xData
            cellModel.yData = tempModel.yData
            cellModel.zData = tempModel.zData
            cellModel.needParse = !tempModel.macAddress.isEmpty
            return cellModel
        }
        if let tempModel = beacon as? MKBXPTLMBeacon {
            let cellModel = MKSwiftBXScanTLMCellModel()
            cellModel.version = "\(tempModel.version)"
            cellModel.mvPerbit = "\(tempModel.mvPerbit)"
            cellModel.temperature = "\(tempModel.temperature)"
            cellModel.advertiseCount = "\(tempModel.advertiseCount)"
            cellModel.deciSecondsSinceBoot = "\(tempModel.deciSecondsSinceBoot)"
            return cellModel
        }
        if let tempModel = beacon as? MKBXPUIDBeacon {
            let cellModel = MKSwiftBXScanUIDCellModel()
            cellModel.txPower = "\(tempModel.txPower.intValue)"
            cellModel.namespaceId = tempModel.namespaceId
            cellModel.instanceId = tempModel.instanceId
            return cellModel
        }
        if let tempModel = beacon as? MKBXPURLBeacon {
            let cellModel = MKSwiftBXScanURLCellModel()
            cellModel.txPower = "\(tempModel.txPower.intValue)"
            cellModel.shortUrl = tempModel.shortUrl
            return cellModel
        }
        return nil
    }

    // MARK: - 解析 BaseBeacon 为 InfoCellModel

    public static func parseBaseBeaconToInfoModel(_ beacon: MKBXPBaseBeacon) -> MKBXPScanInfoCellModel {
        let deviceModel = MKBXPScanInfoCellModel()
        guard let peripheral = beacon.peripheral else { return deviceModel }

        deviceModel.identifier = peripheral.identifier.uuidString
        deviceModel.rssi = "\(beacon.rssi.intValue)"
        deviceModel.deviceName = beacon.deviceName.isEmpty ? "" : beacon.deviceName
        deviceModel.displayTime = "N/A"
        deviceModel.lastScanDate = Date().timeIntervalSince1970 * 1000
        deviceModel.connectable = beacon.connectEnable
        deviceModel.peripheral = peripheral
        deviceModel.otaMode = (beacon.frameType == .ota)

        if beacon.frameType == .deviceInfo {
            if let tempInfoModel = beacon as? MKBXPDeviceInfoBeacon {
                deviceModel.rangingData = "\(tempInfoModel.rangingData.intValue)"
                deviceModel.txPower = "\(tempInfoModel.txPower.intValue)"
                deviceModel.interval = tempInfoModel.interval
                deviceModel.battery = tempInfoModel.battery
                deviceModel.lockState = tempInfoModel.lockState
                deviceModel.macAddress = tempInfoModel.macAddress
                deviceModel.softVersion = tempInfoModel.softVersion
                deviceModel.lightSensor = tempInfoModel.lightSensor
                deviceModel.lightSensorStatus = tempInfoModel.lightSensorStatus
                deviceModel.tamperAlert = tempInfoModel.tamperAlert
                deviceModel.tamperSensor = tempInfoModel.tamperSensor
            }
            return deviceModel
        }

        guard let obj = parseBeaconDatas(beacon) as? MKSwiftBXScanBaseModel else {
            return deviceModel
        }
        let frameIndex = MKSwiftBXScanPageAdopter.fetchFrameIndex(obj)
        obj.advertiseData = beacon.advertiseData
        obj.index = 0
        obj.frameIndex = frameIndex
        deviceModel.advertiseList.append(obj)

        if beacon.frameType == .threeASensor {
            if let tempBeacon = beacon as? MKBXPThreeASensorBeacon,
               !tempBeacon.battery.isEmpty, !tempBeacon.macAddress.isEmpty {
                deviceModel.macAddress = tempBeacon.macAddress
                deviceModel.battery = tempBeacon.battery
                deviceModel.rangingData = "\(tempBeacon.rssi0M.intValue)"
            }
        } else if beacon.frameType == .thSensor {
            if let tempBeacon = beacon as? MKBXPTHSensorBeacon,
               !tempBeacon.battery.isEmpty, !tempBeacon.macAddress.isEmpty {
                deviceModel.macAddress = tempBeacon.macAddress
                deviceModel.battery = tempBeacon.battery
                deviceModel.rangingData = "\(tempBeacon.rssi0M.intValue)"
            }
        }

        return deviceModel
    }

    // MARK: - 更新 InfoCellModel

    public static func updateInfoCellModel(_ exsitModel: MKBXPScanInfoCellModel,
                                            beaconData beacon: MKBXPBaseBeacon) {
        exsitModel.connectable = beacon.connectEnable
        exsitModel.peripheral = beacon.peripheral
        exsitModel.rssi = "\(beacon.rssi.intValue)"
        exsitModel.otaMode = (beacon.frameType == .ota)

        if !beacon.deviceName.isEmpty {
            exsitModel.deviceName = beacon.deviceName
        }

        if exsitModel.lastScanDate > 0 {
            let space = Date().timeIntervalSince1970 * 1000 - exsitModel.lastScanDate
            if space > 10 {
                exsitModel.displayTime = "<->\(Int(space))ms"
                exsitModel.lastScanDate = Date().timeIntervalSince1970 * 1000
            }
        }

        if beacon.frameType == .deviceInfo {
            if let tempInfoModel = beacon as? MKBXPDeviceInfoBeacon {
                exsitModel.rangingData = "\(tempInfoModel.rangingData.intValue)"
                exsitModel.txPower = "\(tempInfoModel.txPower.intValue)"
                exsitModel.interval = tempInfoModel.interval
                exsitModel.battery = tempInfoModel.battery
                exsitModel.lockState = tempInfoModel.lockState
                exsitModel.macAddress = tempInfoModel.macAddress
                exsitModel.softVersion = tempInfoModel.softVersion
                exsitModel.lightSensor = tempInfoModel.lightSensor
                exsitModel.lightSensorStatus = tempInfoModel.lightSensorStatus
                exsitModel.tamperAlert = tempInfoModel.tamperAlert
            }
            return
        }

        if beacon.frameType == .threeASensor && exsitModel.macAddress.isEmpty {
            if let tempBeacon = beacon as? MKBXPThreeASensorBeacon,
               !tempBeacon.battery.isEmpty, !tempBeacon.macAddress.isEmpty {
                exsitModel.macAddress = tempBeacon.macAddress
                exsitModel.battery = tempBeacon.battery
                exsitModel.rangingData = "\(tempBeacon.rssi0M.intValue)"
            }
        } else if beacon.frameType == .thSensor && exsitModel.macAddress.isEmpty {
            if let tempBeacon = beacon as? MKBXPTHSensorBeacon,
               !tempBeacon.battery.isEmpty, !tempBeacon.macAddress.isEmpty {
                exsitModel.macAddress = tempBeacon.macAddress
                exsitModel.battery = tempBeacon.battery
                exsitModel.rangingData = "\(tempBeacon.rssi0M.intValue)"
            }
        }

        guard let tempModel = parseBeaconDatas(beacon) as? MKSwiftBXScanBaseModel else { return }
        let frameIndex = MKSwiftBXScanPageAdopter.fetchFrameIndex(tempModel)
        tempModel.advertiseData = beacon.advertiseData
        tempModel.frameIndex = frameIndex

        for (index, model) in exsitModel.advertiseList.enumerated() {
            guard let modelObj = model as? MKSwiftBXScanBaseModel else { continue }

            if modelObj.advertiseData == tempModel.advertiseData {
                return
            }

            if type(of: tempModel) == type(of: modelObj),
               (modelObj is MKSwiftBXScanTLMCellModel
                || modelObj is MKSwiftBXScanHTCellModel
                || modelObj is MKSwiftBXScanThreeASensorCellModel) {
                tempModel.index = index
                exsitModel.advertiseList[index] = tempModel
                return
            }
        }

        exsitModel.advertiseList.append(tempModel)
        tempModel.index = exsitModel.advertiseList.count - 1

        var sortedArray = exsitModel.advertiseList.compactMap { $0 as? MKSwiftBXScanBaseModel }
        sortedArray.sort { $0.frameIndex < $1.frameIndex }
        exsitModel.advertiseList.removeAll()
        for (i, model) in sortedArray.enumerated() {
            model.index = i
            exsitModel.advertiseList.append(model)
        }
    }
}
