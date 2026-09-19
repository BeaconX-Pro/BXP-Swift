//
//  MKBXPTaskAdopter.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import Foundation
@preconcurrency import CoreBluetooth
import MKSwiftBleModule

/// BXP 任务数据解析工具(对应 OC MKBXPTaskAdopter)
public enum MKBXPTaskAdopter {

    // MARK: - 对外解析入口

    /// 解析读取到的特征数据(对应 OC parseReadDataWithCharacteristic:)
    public static func parseReadData(with characteristic: CBCharacteristic) -> [String: Any] {
        guard let readData = characteristic.value else {
            return [:]
        }
        let uuidString = characteristic.uuid.uuidString

        switch uuidString {
        case "2A24":
            // 产品型号信息
            return modeIDData(readData)
        case "2A25":
            // 生产日期
            return productionDate(readData)
        case "2A26":
            // 固件信息
            return firmwareData(readData)
        case "2A27":
            // 硬件信息
            return hardwareData(readData)
        case "2A28":
            // 软件版本
            return softwareData(readData)
        case "2A29":
            // 厂商信息
            return vendorData(readData)
        case "A3C87501-8ED3-4BDF-8A39-A01BEBEDE295":
            // capabilities - 无解析
            return [:]
        case "A3C87502-8ED3-4BDF-8A39-A01BEBEDE295":
            // 当前活跃通道
            return activeSlot(readData)
        case "A3C87503-8ED3-4BDF-8A39-A01BEBEDE295":
            // 当前活跃通道的广播间隔
            return slotAdvertisingInterval(readData)
        case "A3C87504-8ED3-4BDF-8A39-A01BEBEDE295":
            // 当前活跃通道的发射功率
            return radioTxPower(readData)
        case "A3C87505-8ED3-4BDF-8A39-A01BEBEDE295":
            // 当前活跃通道的广播功率
            return advTxPower(readData)
        case "A3C87506-8ED3-4BDF-8A39-A01BEBEDE295":
            // lock 状态
            return lockState(readData)
        case "A3C87507-8ED3-4BDF-8A39-A01BEBEDE295":
            // unlock
            return unlockData(readData)
        case "A3C87508-8ED3-4BDF-8A39-A01BEBEDE295":
            // publicECDHKey - 无解析
            return [:]
        case "A3C87509-8ED3-4BDF-8A39-A01BEBEDE295":
            // eidIdentityKey - 无解析
            return [:]
        case "A3C8750A-8ED3-4BDF-8A39-A01BEBEDE295":
            // 当前活跃通道的广播信息
            return advDataWithOriData(readData)
        case "A3C8750B-8ED3-4BDF-8A39-A01BEBEDE295":
            // factoryReset - 无解析
            return [:]
        case "E62A0003-1362-4F28-9327-F5B74E970801":
            // notify (custom)
            return customData(readData)
        case "E62A0006-1362-4F28-9327-F5B74E970801":
            // 电池服务
            return batteryData(readData)
        case "E62A0004-1362-4F28-9327-F5B74E970801":
            // 设备类型
            return parseDeviceType(readData)
        case "E62A0005-1362-4F28-9327-F5B74E970801":
            // 通道类型
            return parseSlotType(readData)
        case "E62A000C-1362-4F28-9327-F5B74E970801":
            // 光感状态
            let content = MKSwiftBleSDKAdopter.hexStringFromData(readData)
            return dataParserGetDataSuccess(["status": content],
                                            operationID: .readLightSensorStatus)
        case "A3C8750C-8ED3-4BDF-8A39-A01BEBEDE295":
            // 可连接状态
            return parseConnectStatus(readData)
        default:
            return [:]
        }
    }

    /// 解析写入特征的结果数据(对应 OC parseWriteDataWithCharacteristic:)
    public static func parseWriteData(with characteristic: CBCharacteristic) -> [String: Any] {
        let uuidString = characteristic.uuid.uuidString
        var operationID: MKBXPTaskOperationID = .default

        switch uuidString {
        case "A3C87502-8ED3-4BDF-8A39-A01BEBEDE295":
            operationID = .configActiveSlot
        case "A3C87503-8ED3-4BDF-8A39-A01BEBEDE295":
            operationID = .configAdvertisingInterval
        case "A3C87504-8ED3-4BDF-8A39-A01BEBEDE295":
            operationID = .configRadioTxPower
        case "A3C87505-8ED3-4BDF-8A39-A01BEBEDE295":
            operationID = .configAdvTxPower
        case "A3C87506-8ED3-4BDF-8A39-A01BEBEDE295":
            // 重置密码
            operationID = .configLockState
        case "A3C87507-8ED3-4BDF-8A39-A01BEBEDE295":
            // 设置 unlock 状态
            operationID = .configUnlock
        case "A3C87508-8ED3-4BDF-8A39-A01BEBEDE295":
            // publicECDHKey - 无
            break
        case "A3C87509-8ED3-4BDF-8A39-A01BEBEDE295":
            // eidIdentityKey - 无
            break
        case "A3C8750A-8ED3-4BDF-8A39-A01BEBEDE295":
            // 设置广播数据
            operationID = .configAdvSlotData
        case "A3C8750B-8ED3-4BDF-8A39-A01BEBEDE295":
            // 恢复出厂设置
            operationID = .configFactoryReset
        case "A3C8750C-8ED3-4BDF-8A39-A01BEBEDE295":
            // 可连接状态
            operationID = .configConnectEnable
        default:
            break
        }
        return dataParserGetDataSuccess(["success": true], operationID: operationID)
    }

    // MARK: - 厂商信息 / 系统信息

    private static func modeIDData(_ data: Data) -> [String: Any] {
        let tempString = String(data: data, encoding: .utf8) ?? ""
        return dataParserGetDataSuccess(["modeID": tempString], operationID: .readModeID)
    }

    private static func productionDate(_ data: Data) -> [String: Any] {
        let tempString = String(data: data, encoding: .utf8) ?? ""
        return dataParserGetDataSuccess(["productionDate": tempString], operationID: .readProductionDate)
    }

    private static func firmwareData(_ data: Data) -> [String: Any] {
        let tempString = String(data: data, encoding: .utf8) ?? ""
        return dataParserGetDataSuccess(["firmware": tempString], operationID: .readFirmware)
    }

    private static func hardwareData(_ data: Data) -> [String: Any] {
        let tempString = String(data: data, encoding: .utf8) ?? ""
        return dataParserGetDataSuccess(["hardware": tempString], operationID: .readHardware)
    }

    private static func softwareData(_ data: Data) -> [String: Any] {
        let tempString = String(data: data, encoding: .utf8) ?? ""
        return dataParserGetDataSuccess(["software": tempString], operationID: .readSoftware)
    }

    private static func vendorData(_ data: Data) -> [String: Any] {
        let tempString = String(data: data, encoding: .utf8) ?? ""
        return dataParserGetDataSuccess(["vendor": tempString], operationID: .readVendor)
    }

    // MARK: - Eddystone 配置服务解析

    private static func batteryData(_ data: Data) -> [String: Any] {
        let content = MKSwiftBleSDKAdopter.hexStringFromData(data)
        guard !content.isEmpty, content.count == 4 else {
            return [:]
        }
        let battery = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content,
                                                                   range: NSRange(location: 0, length: 4))
        return dataParserGetDataSuccess(["battery": battery], operationID: .readBattery)
    }

    private static func lockState(_ data: Data) -> [String: Any] {
        let content = MKSwiftBleSDKAdopter.hexStringFromData(data)
        guard !content.isEmpty, content.count == 2 else {
            return [:]
        }
        return dataParserGetDataSuccess(["lockState": content], operationID: .readLockState)
    }

    private static func unlockData(_ data: Data) -> [String: Any] {
        guard data.count == 16 else {
            return [:]
        }
        return dataParserGetDataSuccess(["RAND_DATA_ARRAY": data], operationID: .readUnlock)
    }

    private static func activeSlot(_ data: Data) -> [String: Any] {
        let content = MKSwiftBleSDKAdopter.hexStringFromData(data)
        guard !content.isEmpty, content.count == 2 else {
            return [:]
        }
        return dataParserGetDataSuccess(["activeSlot": content], operationID: .readActiveSlot)
    }

    private static func slotAdvertisingInterval(_ data: Data) -> [String: Any] {
        let content = MKSwiftBleSDKAdopter.hexStringFromData(data)
        guard !content.isEmpty, content.count == 4 else {
            return [:]
        }
        let advInterval = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content,
                                                                      range: NSRange(location: 0, length: 4))
        return dataParserGetDataSuccess(["advertisingInterval": advInterval],
                                        operationID: .readAdvertisingInterval)
    }

    private static func radioTxPower(_ data: Data) -> [String: Any] {
        let content = MKSwiftBleSDKAdopter.hexStringFromData(data)
        let power = MKBXPAdopter.fetchTxPower(content: content)
        return dataParserGetDataSuccess(["radioTxPower": power], operationID: .readRadioTxPower)
    }

    private static func advTxPower(_ contentData: Data) -> [String: Any] {
        guard !contentData.isEmpty else {
            return [:]
        }
        var txPowerChar: UInt8 = 0
        contentData.withUnsafeBytes { ptr in
            if let base = ptr.baseAddress {
                txPowerChar = base.assumingMemoryBound(to: UInt8.self).pointee
            }
        }
        var txNumber: Int = 0
        if (txPowerChar & 0x80) != 0 {
            txNumber = -0x100 + Int(txPowerChar)
        } else {
            txNumber = Int(txPowerChar)
        }
        let power = String(txNumber)
        return dataParserGetDataSuccess(["advTxPower": power], operationID: .readAdvTxPower)
    }

    private static func parseDeviceType(_ data: Data) -> [String: Any] {
        let content = MKSwiftBleSDKAdopter.hexStringFromData(data)
        return dataParserGetDataSuccess(["deviceType": content], operationID: .readDeviceType)
    }

    private static func parseSlotType(_ data: Data) -> [String: Any] {
        // 读取 eddyStone 设备通道数据类型
        let content = MKSwiftBleSDKAdopter.hexStringFromData(data)
        let typeList = [
            content.bleSubstring(from: 0, length: 2),
            content.bleSubstring(from: 2, length: 2),
            content.bleSubstring(from: 4, length: 2),
            content.bleSubstring(from: 6, length: 2),
            content.bleSubstring(from: 8, length: 2),
            content.bleSubstring(from: 10, length: 2)
        ]
        return dataParserGetDataSuccess(["slotTypeList": typeList], operationID: .readSlotType)
    }

    private static func parseConnectStatus(_ data: Data) -> [String: Any] {
        let content = MKSwiftBleSDKAdopter.hexStringFromData(data)
        return dataParserGetDataSuccess(["connectEnable": (content != "00")],
                                        operationID: .readConnectEnable)
    }

    // MARK: - advSlotData 解析

    /// 解析当前活跃通道的广播信息(对应 OC advDataWithOriData:)
    /// - Note: 依赖 MKBXPBaseBeacon.parseDataType(withSlotData:) 与
    ///         MKBXPTLMBeacon / MKBXPUIDBeacon / MKBXPURLBeacon 的 init(advertiseData:)
    ///         及其属性(version/mvPerbit/temperature/advertiseCount/deciSecondsSinceBoot、
    ///         txPower/namespaceId/instanceId/shortUrl)
    private static func advDataWithOriData(_ data: Data) -> [String: Any] {
        let frameType = MKBXPBaseBeacon.parseDataType(withSlotData: data)
        if frameType == .unknown {
            // 当前 slot 广播信息无法识别
            return [:]
        }
        switch frameType {
        case .tlm:
            let beacon = MKBXPTLMBeacon(advertiseData: data)
            let returnData: [String: Any] = [
                "frameType": "20",
                "version": String(beacon?.version.intValue ?? 0),
                "mvPerbit": String(beacon?.mvPerbit.intValue ?? 0),
                "temperature": String(beacon?.temperature.intValue ?? 0),
                "advertiseCount": String(beacon?.advertiseCount.intValue ?? 0),
                "deciSecondsSinceBoot": String(beacon?.deciSecondsSinceBoot.intValue ?? 0)
            ]
            return dataParserGetDataSuccess(returnData, operationID: .readAdvSlotData)
        case .uid:
            let beacon = MKBXPUIDBeacon(advertiseData: data)
            let returnData: [String: Any] = [
                "frameType": "00",
                "rssi@0M": String(beacon?.txPower.intValue ?? 0),
                "namespaceId": beacon?.namespaceId ?? "",
                "instanceId": beacon?.instanceId ?? ""
            ]
            return dataParserGetDataSuccess(returnData, operationID: .readAdvSlotData)
        case .url:
            let beacon = MKBXPURLBeacon(advertiseData: data)
            let returnData: [String: Any] = [
                "frameType": "10",
                "advData": data,
                "rssi@0M": String(beacon?.txPower.intValue ?? 0)
            ]
            return dataParserGetDataSuccess(returnData, operationID: .readAdvSlotData)
        case .deviceInfo:
            let nameString = String(data: data.subdata(in: 1..<data.count), encoding: .utf8) ?? ""
            let returnData: [String: Any] = [
                "frameType": "40",
                "peripheralName": nameString
            ]
            return dataParserGetDataSuccess(returnData, operationID: .readAdvSlotData)
        case .beacon:
            // iBeacon - 与 OC 一致采用内联解析
            let content = MKSwiftBleSDKAdopter.hexStringFromData(data.subdata(in: 1..<data.count))
            var array: [String] = [
                content.bleSubstring(from: 0, length: 8),
                content.bleSubstring(from: 8, length: 4),
                content.bleSubstring(from: 12, length: 4),
                content.bleSubstring(from: 16, length: 4),
                content.bleSubstring(from: 20, length: 12)
            ]
            array.insert("-", at: 1)
            array.insert("-", at: 3)
            array.insert("-", at: 5)
            array.insert("-", at: 7)
            let uuid = array.joined().uppercased()
            let major = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content,
                                                                     range: NSRange(location: 32, length: 4))
            let minor = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content,
                                                                     range: NSRange(location: 36, length: 4))
            let returnData: [String: Any] = [
                "frameType": "50",
                "major": major,
                "minor": minor,
                "uuid": uuid
            ]
            return dataParserGetDataSuccess(returnData, operationID: .readAdvSlotData)
        default:
            // 其它帧类型(threeASensor / thSensor / noData / ota) - 仅返回帧类型 hex
            let type = MKSwiftBleSDKAdopter.hexStringFromData(data.subdata(in: 0..<1))
            return dataParserGetDataSuccess(["frameType": type], operationID: .readAdvSlotData)
        }
    }

    // MARK: - customData 解析(eb 头)

    /// 解析 notify 特征返回的自定义数据(对应 OC customData:)
    private static func customData(_ data: Data) -> [String: Any] {
        let content = MKSwiftBleSDKAdopter.hexStringFromData(data)
        guard !content.isEmpty, content.count >= 8 else {
            return [:]
        }
        // 配置信息, eb 开头;ec 表示多包数据
        let ackHeader = content.bleSubstring(from: 0, length: 2)
        if ackHeader == "ec" {
            // 多包数据
            return parseMultiPacketData(content)
        }
        let len = MKSwiftBleSDKAdopter.getDecimalWithHex(content, range: NSRange(location: 6, length: 2))
        if content.count != 2 * len + 8 {
            return [:]
        }
        let function = content.bleSubstring(from: 2, length: 2)
        var operationID: MKBXPTaskOperationID = .default
        var returnDic: [String: Any] = [:]

        switch function {
        case "20":
            // mac 地址
            guard content.count == 20 else { break }
            let tempMac = content.bleSubstring(from: 8, length: 12).uppercased()
            let macAddress = "\(tempMac.bleSubstring(from: 0, length: 2)):" +
                             "\(tempMac.bleSubstring(from: 2, length: 2)):" +
                             "\(tempMac.bleSubstring(from: 4, length: 2)):" +
                             "\(tempMac.bleSubstring(from: 6, length: 2)):" +
                             "\(tempMac.bleSubstring(from: 8, length: 2)):" +
                             "\(tempMac.bleSubstring(from: 10, length: 2))"
            operationID = .readMacAddress
            returnDic = ["macAddress": macAddress]
        case "21":
            // 读取三轴传感器参数
            guard content.count == 14 else { break }
            operationID = .readThreeAxisParams
            returnDic = [
                "samplingRate": content.bleSubstring(from: 8, length: 2),
                "gravityReference": content.bleSubstring(from: 10, length: 2),
                "sensitivity": MKSwiftBleSDKAdopter.getDecimalStringWithHex(content,
                                                                           range: NSRange(location: 12, length: 2))
            ]
        case "22":
            // 读取温湿度存储条件
            let tempFunction = content.bleSubstring(from: 8, length: 2)
            var temperValue = ""
            var humidity = ""
            var time = ""
            if tempFunction == "00" && content.count == 14 {
                // 温度
                let value = MKSwiftBleSDKAdopter.getDecimalWithHex(content,
                                                                   range: NSRange(location: 10, length: 4))
                temperValue = String(format: "%.1f", Double(value) * 0.1)
            } else if tempFunction == "01" && content.count == 14 {
                // 湿度
                let value = MKSwiftBleSDKAdopter.getDecimalWithHex(content,
                                                                   range: NSRange(location: 10, length: 4))
                humidity = String(format: "%.1f", Double(value) * 0.1)
            } else if tempFunction == "02" && content.count == 18 {
                // 温湿度
                let value = MKSwiftBleSDKAdopter.getDecimalWithHex(content,
                                                                   range: NSRange(location: 10, length: 4))
                let value1 = MKSwiftBleSDKAdopter.getDecimalWithHex(content,
                                                                    range: NSRange(location: 14, length: 4))
                temperValue = String(format: "%.1f", Double(value) * 0.1)
                humidity = String(format: "%.1f", Double(value1) * 0.1)
            } else if tempFunction == "03" && content.count == 12 {
                // 时间
                time = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content,
                                                                    range: NSRange(location: 10, length: 2))
            }
            returnDic = [
                "functionType": tempFunction,
                "temperature": temperValue,
                "humidity": humidity,
                "storageTime": time
            ]
            operationID = .readHTStorageConditions
        case "23":
            // 读取温湿度采样率
            guard content.count == 12 else { break }
            operationID = .readHTSamplingRate
            returnDic = [
                "samplingRate": MKSwiftBleSDKAdopter.getDecimalStringWithHex(content,
                                                                             range: NSRange(location: 8, length: 4))
            ]
        case "24":
            // 删除已储存的温湿度数据
            guard content.count == 8 else { break }
            operationID = .deleteRecordHTData
            returnDic = ["success": true]
        case "25":
            // 读取设备当前时间
            guard content.count == 20 else { break }
            operationID = .readDeviceTime
            returnDic = [
                "deviceTime": MKBXPAdopter.deviceTime(content.bleSubstring(from: 8, length: 12))
            ]
        case "26":
            // 关机
            guard content.count == 8 else { break }
            operationID = .configPowerOff
            returnDic = ["success": true]
        case "28":
            // 读取按键关机状态
            guard content.count == 10 else { break }
            operationID = .readButtonPowerStatus
            returnDic = [
                "isOn": (content.bleSubstring(from: 8, length: 2) == "01")
            ]
        case "29":
            // 读取触发条件
            guard content.count >= 10 else { break }
            operationID = .readTriggerConditions
            returnDic = parseTriggerConditions(content.bleSubstring(from: 8, length: 2 * len))
        case "2a":
            // 读取厂商信息
            guard content.count >= 10 else { break }
            operationID = .readVendor
            let tempString = String(data: data.subdata(in: 4..<data.count), encoding: .utf8) ?? ""
            returnDic = ["vendor": tempString]
        case "2b":
            // 读取固件版本
            guard content.count >= 10 else { break }
            operationID = .readFirmware
            let tempString = String(data: data.subdata(in: 4..<data.count), encoding: .utf8) ?? ""
            returnDic = ["firmware": tempString]
        case "2c":
            // 读取软件版本
            guard content.count >= 10 else { break }
            operationID = .readSoftware
            let tempString = String(data: data.subdata(in: 4..<data.count), encoding: .utf8) ?? ""
            returnDic = ["software": tempString]
        case "2d":
            // 读取硬件版本
            guard content.count >= 10 else { break }
            operationID = .readHardware
            let tempString = String(data: data.subdata(in: 4..<data.count), encoding: .utf8) ?? ""
            returnDic = ["hardware": tempString]
        case "2e":
            // 读取产品型号信息
            guard content.count >= 10 else { break }
            operationID = .readModeID
            let tempString = String(data: data.subdata(in: 4..<data.count), encoding: .utf8) ?? ""
            returnDic = ["modeID": tempString]
        case "2f":
            // 读取回应包开关状态
            guard content.count == 10 else { break }
            operationID = .readScanResponsePacket
            returnDic = [
                "isOn": (content.bleSubstring(from: 8, length: 2) == "01")
            ]
        case "31":
            // 设置三轴传感器参数
            guard content.count == 8 else { break }
            operationID = .configThreeAxisParams
            returnDic = ["success": true]
        case "32":
            // 设置温湿度存储条件
            guard content.count == 8 else { break }
            operationID = .configHTStorageConditions
            returnDic = ["success": true]
        case "33":
            // 设置温湿度采样率
            guard content.count == 8 else { break }
            operationID = .configHTSamplingRate
            returnDic = ["success": true]
        case "35":
            // 设置设备当前时间
            guard content.count == 8 else { break }
            operationID = .configDeviceTime
            returnDic = ["success": true]
        case "38":
            // 设置按键关机状态
            guard content.count == 8 else { break }
            operationID = .configButtonPowerStatus
            returnDic = ["success": true]
        case "39":
            // 设置触发条件
            guard content.count == 8 else { break }
            operationID = .configTriggerConditions
            returnDic = ["success": true]
        case "3f":
            // 配置回应包开关状态
            guard content.count == 8 else { break }
            operationID = .configScanResponsePacket
            returnDic = ["success": true]
        case "46":
            // 删除已储存的光感数据
            guard content.count == 8 else { break }
            operationID = .deleteRecordLightSensorData
            returnDic = ["success": true]
        case "47":
            // 读取 LED 触发提醒
            guard content.count == 10 else { break }
            let isOn = (content.bleSubstring(from: 8, length: 2) == "01")
            returnDic = ["isOn": isOn]
            operationID = .readLEDTriggerStatus
        case "48":
            // 读取设备是否可以按键开关机
            guard content.count == 10 else { break }
            let isOn = (content.bleSubstring(from: 8, length: 2) == "01")
            returnDic = ["isOn": isOn]
            operationID = .readResetBeaconByButtonStatus
        case "4d":
            // 读取按键间隔时长
            guard content.count == 12 else { break }
            let interval = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content,
                                                                        range: NSRange(location: 8, length: 4))
            operationID = .readEffectiveClickInterval
            returnDic = ["interval": interval]
        case "4e":
            // 读取生产日期
            guard content.count >= 10 else { break }
            operationID = .readProductionDate
            let year = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content,
                                                                    range: NSRange(location: 8, length: 4))
            var month = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content,
                                                                     range: NSRange(location: 12, length: 2))
            if month.count == 1 {
                month = "0" + month
            }
            var day = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content,
                                                                   range: NSRange(location: 14, length: 2))
            if day.count == 1 {
                day = "0" + day
            }
            let productDate = "\(year)/\(month)/\(day)"
            returnDic = ["productionDate": productDate]
        case "4f":
            // 读取时间戳
            operationID = .readTimeStamp
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
            let value = MKSwiftBleSDKAdopter.getDecimalWithHex(content,
                                                               range: NSRange(location: 8, length: 8))
            let date = Date(timeIntervalSince1970: TimeInterval(value))
            let timeString = formatter.string(from: date)
            returnDic = ["deviceTime": timeString]
        case "57":
            // 设置 LED 触发提醒
            guard content.count == 8 else { break }
            operationID = .configLEDTriggerStatus
            returnDic = ["success": true]
        case "58":
            // 设置设备是否可以按键开关机
            guard content.count == 8 else { break }
            operationID = .configResetBeaconByButtonStatus
            returnDic = ["success": true]
        case "5d":
            // 设置按键间隔时长
            guard content.count == 8 else { break }
            operationID = .configEffectiveClickInterval
            returnDic = ["success": true]
        case "61":
            // 读取 LED 远程提醒参数
            guard content.count == 18 else { break }
            let color = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content,
                                                                     range: NSRange(location: 8, length: 2))
            let interval = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content,
                                                                       range: NSRange(location: 10, length: 4))
            let time = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content,
                                                                   range: NSRange(location: 14, length: 4))
            operationID = .readRemoteReminderLEDNotiParams
            returnDic = [
                "color": color,
                "interval": interval,
                "time": time
            ]
        case "62":
            // 读取远程控制蜂鸣器
            guard content.count == 20 else { break }
            let frequent = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content,
                                                                        range: NSRange(location: 8, length: 4))
            let interval = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content,
                                                                       range: NSRange(location: 12, length: 4))
            let time = MKSwiftBleSDKAdopter.getDecimalStringWithHex(content,
                                                                   range: NSRange(location: 16, length: 4))
            operationID = .readRemoteReminderBuzzerNotiParams
            returnDic = [
                "frequent": frequent,
                "interval": interval,
                "time": time
            ]
        case "71":
            // 配置远程 LED 控制参数
            guard content.count == 8 else { break }
            operationID = .configRemoteReminderLEDNotiParams
            returnDic = ["success": true]
        case "72":
            // 配置远程 buzzer 控制参数
            guard content.count == 8 else { break }
            operationID = .configRemoteReminderBuzzerNotiParams
            returnDic = ["success": true]
        default:
            break
        }
        return dataParserGetDataSuccess(returnDic, operationID: operationID)
    }

    /// 解析多包数据(ec 头)
    private static func parseMultiPacketData(_ content: String) -> [String: Any] {
        let cmd = content.bleSubstring(from: 4, length: 2)
        var operationID: MKBXPTaskOperationID = .default
        var returnDic: [String: Any] = [:]
        if cmd == "4c" {
            // 历史温湿度数据
            returnDic = MKBXPAdopter.parseHistoryHTData(content.bleSubstring(from: 6, length: (content.count - 6)))
            operationID = .readHundredHistoryData
        }
        return dataParserGetDataSuccess(returnDic, operationID: operationID)
    }

    /// 解析触发条件(对应 OC parseTriggerConditions:)
    private static func parseTriggerConditions(_ content: String) -> [String: Any] {
        let type = content.bleSubstring(from: 0, length: 2)
        var resultDic: [String: Any] = [:]
        switch type {
        case "00":
            guard content.count == 2 else { break }
            resultDic = [
                "type": type,
                "conditions": [String: Any]()
            ]
        case "01":
            guard content.count == 10 else { break }
            let tempValue = MKSwiftBleSDKAdopter.signedHexTurnToInt(content.bleSubstring(from: 4, length: 4))
            let temperature = Float(tempValue) * 0.1
            resultDic = [
                "type": type,
                "conditions": [
                    "above": (content.bleSubstring(from: 2, length: 2) == "01"),
                    "temperature": String(format: "%.1f", temperature),
                    "start": (content.bleSubstring(from: 8, length: 2) == "01")
                ] as [String: Any]
            ]
        case "02":
            guard content.count == 10 else { break }
            let tempValue = MKSwiftBleSDKAdopter.signedHexTurnToInt(content.bleSubstring(from: 4, length: 4))
            let humidity = Float(tempValue) * 0.1
            resultDic = [
                "type": type,
                "conditions": [
                    "above": (content.bleSubstring(from: 2, length: 2) == "01"),
                    "humidity": String(format: "%.1f", humidity),
                    "start": (content.bleSubstring(from: 8, length: 2) == "01")
                ] as [String: Any]
            ]
        case "03":
            guard content.count == 8 else { break }
            resultDic = [
                "type": type,
                "conditions": [
                    "time": MKSwiftBleSDKAdopter.getDecimalStringWithHex(content,
                                                                        range: NSRange(location: 2, length: 4)),
                    "start": (content.bleSubstring(from: 6, length: 2) == "01")
                ] as [String: Any]
            ]
        case "04":
            guard content.count == 8 else { break }
            resultDic = [
                "type": type,
                "conditions": [
                    "time": MKSwiftBleSDKAdopter.getDecimalStringWithHex(content,
                                                                        range: NSRange(location: 2, length: 4)),
                    "start": (content.bleSubstring(from: 6, length: 2) == "01")
                ] as [String: Any]
            ]
        case "05":
            guard content.count == 8 else { break }
            resultDic = [
                "type": type,
                "conditions": [
                    "time": MKSwiftBleSDKAdopter.getDecimalStringWithHex(content,
                                                                        range: NSRange(location: 2, length: 4)),
                    "start": (content.bleSubstring(from: 6, length: 2) == "01")
                ] as [String: Any]
            ]
        case "06":
            guard content.count == 10 else { break }
            resultDic = [
                "type": type,
                "conditions": [
                    "time": MKSwiftBleSDKAdopter.getDecimalStringWithHex(content,
                                                                        range: NSRange(location: 2, length: 4)),
                    "start": (content.bleSubstring(from: 8, length: 2) == "01")
                ] as [String: Any]
            ]
        case "07":
            guard content.count == 8 else { break }
            resultDic = [
                "type": type,
                "conditions": [
                    "time": MKSwiftBleSDKAdopter.getDecimalStringWithHex(content,
                                                                        range: NSRange(location: 2, length: 4)),
                    "start": (content.bleSubstring(from: 6, length: 2) == "01")
                ] as [String: Any]
            ]
        case "08":
            guard content.count == 8 else { break }
            resultDic = [
                "type": type,
                "conditions": [
                    "time": MKSwiftBleSDKAdopter.getDecimalStringWithHex(content,
                                                                        range: NSRange(location: 2, length: 4)),
                    "start": (content.bleSubstring(from: 6, length: 2) == "01")
                ] as [String: Any]
            ]
        default:
            break
        }
        return resultDic
    }

    // MARK: - Helper

    /// 包装返回数据(对应 OC dataParserGetDataSuccess:operationID:)
    /// - Note: 与 OC 略有差异——OC 在 returnData 为 nil 时返回 nil,Swift 一律返回包含 returnData/operationID 的字典
    private static func dataParserGetDataSuccess(_ returnData: [String: Any],
                                                 operationID: MKBXPTaskOperationID) -> [String: Any] {
        return [
            "returnData": returnData,
            "operationID": operationID.rawValue
        ]
    }
}
