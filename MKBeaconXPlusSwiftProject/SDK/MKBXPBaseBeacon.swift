//
//  MKBXPBaseBeacon.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import Foundation
@preconcurrency import CoreBluetooth
import MKSwiftBleModule

// MARK: - 帧类型枚举
/// Advertising data frame type
public enum MKBXPDataFrameType: Int {
    /// UID
    case uid = 0
    /// URL
    case url
    /// TLM
    case tlm
    /// Device information
    case deviceInfo
    /// iBeacon
    case beacon
    /// 3-axis accelerometer data
    case threeASensor
    /// Temperature and humidity sensor data
    case thSensor
    /// NO DATA
    case noData
    /// OTA Frame Type
    case ota
    /// Unknown
    case unknown
}

// MARK: - 基础 Beacon
public class MKBXPBaseBeacon: NSObject {

    /// 帧类型
    public var frameType: MKBXPDataFrameType = .unknown
    /// rssi
    public var rssi: NSNumber = 0
    /// 是否可连接
    public var connectEnable: Bool = false
    /// 扫描到的设备标识
    public var identifier: String = ""
    /// 扫描到的设备
    public var peripheral: CBPeripheral?
    /// 设备广播数据
    public var advertiseData: Data = Data()
    /// 设备名称
    public var deviceName: String = ""

    /// 解析广播数据
    /// - Parameter advData: 系统返回的 advertisementData 字典
    /// - Returns: 解析出的所有 Beacon
    public static func parseAdvData(_ advData: [String: Any]) -> [MKBXPBaseBeacon] {
        guard MKValidator.isValidDictionary(advData) else { return [] }
        guard let advDic = advData[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data] else {
            return []
        }

        var beaconList: [MKBXPBaseBeacon] = []

        for key in advDic.keys {
            if key == CBUUID(string: "FEAA") {
                if let feaaData = advDic[CBUUID(string: "FEAA")], MKValidator.isValidData(feaaData) {
                    let frameType = fetchFEAAFrameType(feaaData)
                    if let beacon = fetchBaseBeacon(withFrameType: frameType, advData: feaaData) {
                        beaconList.append(beacon)
                    }
                }
            } else if key == CBUUID(string: "FEAB") {
                if let feabData = advDic[CBUUID(string: "FEAB")], MKValidator.isValidData(feabData) {
                    let frameType = fetchFEABFrameType(feabData)
                    if let beacon = fetchBaseBeacon(withFrameType: frameType, advData: feabData) {
                        // 根据类型设置 txPower
                        if let tempBeacon = beacon as? MKBXPTHSensorBeacon {
                            if let txPower = advData[CBAdvertisementDataTxPowerLevelKey] as? NSNumber {
                                tempBeacon.txPower = txPower
                            }
                        } else if let tempBeacon = beacon as? MKBXPiBeacon {
                            if let txPower = advData[CBAdvertisementDataTxPowerLevelKey] as? NSNumber {
                                tempBeacon.txPower = txPower
                            }
                        } else if let tempBeacon = beacon as? MKBXPThreeASensorBeacon {
                            if let txPower = advData[CBAdvertisementDataTxPowerLevelKey] as? NSNumber {
                                tempBeacon.txPower = txPower
                            }
                        } else if let tempBeacon = beacon as? MKBXPDeviceInfoBeacon {
                            if let txPower = advData[CBAdvertisementDataTxPowerLevelKey] as? NSNumber {
                                tempBeacon.txPower = txPower
                            }
                        }
                        beaconList.append(beacon)
                    }
                }
            }
        }

        return beaconList
    }

    /// 根据 slotData 第一字节解析帧类型
    /// - Parameter slotData: 槽位数据
    /// - Returns: 帧类型
    public static func parseDataType(withSlotData slotData: Data) -> MKBXPDataFrameType {
        guard !slotData.isEmpty else { return .unknown }
        let firstByte = slotData[slotData.startIndex]
        switch firstByte {
        case 0x00:
            return .uid
        case 0x10:
            return .url
        case 0x20:
            return .tlm
        case 0x40:
            return .deviceInfo
        case 0x50:
            return .beacon
        case 0x60:
            return .threeASensor
        case 0x70:
            return .thSensor
        case 0xff:
            return .noData
        default:
            return .unknown
        }
    }

    // MARK: - private method

    /// 根据帧类型构造对应的 Beacon
    private static func fetchBaseBeacon(withFrameType frameType: MKBXPDataFrameType,
                                        advData: Data) -> MKBXPBaseBeacon? {
        var beacon: MKBXPBaseBeacon?
        switch frameType {
        case .uid:
            if let temp = MKBXPUIDBeacon(advertiseData: advData) {
                beacon = temp
                beacon?.advertiseData = advData
            }
        case .url:
            if let temp = MKBXPURLBeacon(advertiseData: advData) {
                beacon = temp
                beacon?.advertiseData = advData
            }
        case .tlm:
            if let temp = MKBXPTLMBeacon(advertiseData: advData) {
                beacon = temp
                beacon?.advertiseData = advData
            }
        case .deviceInfo:
            if let temp = MKBXPDeviceInfoBeacon(advertiseData: advData) {
                beacon = temp
                beacon?.advertiseData = advData
            }
        case .beacon:
            if let temp = MKBXPiBeacon(advertiseData: advData) {
                beacon = temp
                beacon?.advertiseData = advData
            }
        case .threeASensor:
            if let temp = MKBXPThreeASensorBeacon(advertiseData: advData) {
                beacon = temp
                beacon?.advertiseData = advData
            }
        case .thSensor:
            if let temp = MKBXPTHSensorBeacon(advertiseData: advData) {
                beacon = temp
                beacon?.advertiseData = advData
            }
        default:
            return nil
        }
        beacon?.frameType = frameType
        return beacon
    }

    /// 解析 FEAA 帧类型
    private static func fetchFEAAFrameType(_ stoneData: Data) -> MKBXPDataFrameType {
        guard MKValidator.isValidData(stoneData), !stoneData.isEmpty else {
            return .unknown
        }
        let firstByte = stoneData[stoneData.startIndex]
        switch firstByte {
        case 0x00:
            return .uid
        case 0x10:
            return .url
        case 0x20:
            return .tlm
        default:
            return .unknown
        }
    }

    /// 解析 FEAB 帧类型
    private static func fetchFEABFrameType(_ customData: Data) -> MKBXPDataFrameType {
        guard MKValidator.isValidData(customData), !customData.isEmpty else {
            return .unknown
        }
        let firstByte = customData[customData.startIndex]
        switch firstByte {
        case 0x40:
            return .deviceInfo
        case 0x50:
            return .beacon
        case 0x60:
            return .threeASensor
        case 0x70:
            return .thSensor
        default:
            return .unknown
        }
    }

    /// 根据广播数据字典解析帧类型（私有，保持与 OC 一致）
    private static func fetchFrameType(withAdvData advDic: [CBUUID: Data]) -> MKBXPDataFrameType {
        if let stoneData = advDic[CBUUID(string: "FEAA")], MKValidator.isValidData(stoneData) {
            // Eddystone 信息帧
            guard !stoneData.isEmpty else { return .unknown }
            let firstByte = stoneData[stoneData.startIndex]
            switch firstByte {
            case 0x00:
                return .uid
            case 0x10:
                return .url
            case 0x20:
                return .tlm
            default:
                return .unknown
            }
        }
        guard let customData = advDic[CBUUID(string: "FEAB")],
              MKValidator.isValidData(customData),
              !customData.isEmpty else {
            return .unknown
        }
        let firstByte = customData[customData.startIndex]
        switch firstByte {
        case 0x40:
            return .deviceInfo
        case 0x50:
            return .beacon
        case 0x60:
            return .threeASensor
        case 0x70:
            return .thSensor
        default:
            return .unknown
        }
    }
}

// MARK: - UID Beacon
public class MKBXPUIDBeacon: MKBXPBaseBeacon {
    /// RSSI@0m
    public var txPower: NSNumber = 0
    public var namespaceId: String = ""
    public var instanceId: String = ""

    public init?(advertiseData advData: Data) {
        super.init()
        // 规范上 20 字节，但有些 beacon 不广播最后 2 个 RFU 字节
        guard advData.count >= 18 else {
            return nil
        }
        let bytes = [UInt8](advData)
        let txPowerChar = bytes[1]
        if txPowerChar & 0x80 != 0 {
            self.txPower = NSNumber(value: Int(txPowerChar) - 0x100)
        } else {
            self.txPower = NSNumber(value: Int(txPowerChar))
        }
        // namespace 10 字节，instance 6 字节
        let namespaceBytes = Array(bytes[2..<12])
        let instanceBytes = Array(bytes[12..<18])
        self.namespaceId = namespaceBytes.map { String(format: "%02x", $0) }.joined()
        self.instanceId = instanceBytes.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - URL Beacon
public class MKBXPURLBeacon: MKBXPBaseBeacon {
    /// RSSI@0m
    public var txPower: NSNumber = 0
    /// URL Content
    public var shortUrl: String = ""

    public init?(advertiseData advData: Data) {
        super.init()
        assert(!(advData.count < 3), "Invalid advertiseData:\(advData)")
        let bytes = [UInt8](advData)
        guard bytes.count >= 3 else { return nil }
        let txPowerChar = bytes[1]
        if txPowerChar & 0x80 != 0 {
            self.txPower = NSNumber(value: Int(txPowerChar) - 0x100)
        } else {
            self.txPower = NSNumber(value: Int(txPowerChar))
        }
        let urlScheme = MKBXPAdopter.getUrlscheme(CChar(bytes[2]))
        var url = urlScheme
        for i in 0..<(advData.count - 3) {
            url += MKBXPAdopter.getEncodedString(CChar(bytes[i + 3]))
        }
        self.shortUrl = url
    }
}

// MARK: - TLM Beacon
public class MKBXPTLMBeacon: MKBXPBaseBeacon {
    public var version: NSNumber = 0
    public var mvPerbit: NSNumber = 0
    public var temperature: NSNumber = 0
    public var advertiseCount: NSNumber = 0
    public var deciSecondsSinceBoot: NSNumber = 0

    public init?(advertiseData advData: Data) {
        super.init()
        assert(!(advData.count < 14), "Invalid advertiseData:\(advData)")
        guard advData.count >= 14 else { return nil }
        let bytes = [UInt8](advData)
        self.version = NSNumber(value: Int(bytes[1]))
        self.mvPerbit = NSNumber(value: (Int(bytes[2]) << 8) + Int(bytes[3]))
        let temperatureInt = bytes[4]
        if temperatureInt & 0x80 != 0 {
            self.temperature = NSNumber(value: Float(Int(temperatureInt) - 0x100) + Float(bytes[5]) / 256.0)
        } else {
            self.temperature = NSNumber(value: Float(temperatureInt) + Float(bytes[5]) / 256.0)
        }
        let advertiseCountValue = Int(bytes[6]) * 16777216
            + Int(bytes[7]) * 65536
            + Int(bytes[8]) * 256
            + Int(bytes[9])
        self.advertiseCount = NSNumber(value: advertiseCountValue)
        let deciSecondsValue = Int(bytes[10]) * 16777216
            + Int(bytes[11]) * 65536
            + Int(bytes[12]) * 256
            + Int(bytes[13])
        self.deciSecondsSinceBoot = NSNumber(value: Float(deciSecondsValue) / 10.0)
    }
}

// MARK: - DeviceInfo Beacon
public class MKBXPDeviceInfoBeacon: MKBXPBaseBeacon {
    public var rangingData: NSNumber = 0
    public var txPower: NSNumber = 0
    /// 广播间隔，单位：100ms
    public var interval: String = ""
    /// 电池电压
    public var battery: String = ""

    /// 00: need password     02: Password-free connection
    public var lockState: String = ""

    /// 设备是否有光感
    public var lightSensor: Bool = false

    /// 设备是否有防拆传感器
    public var tamperSensor: Bool = false

    /// 光感是否可用（lightSensor 必须为 true 才有效）
    public var lightSensorStatus: Bool = false

    public var macAddress: String = ""

    public var softVersion: String = ""

    /// 防拆告警（tamperSensor 为 true 时有效）
    public var tamperAlert: Bool = false

    public init?(advertiseData advData: Data) {
        super.init()
        assert(!(advData.count < 13), "Invalid advertiseData:\(advData)")
        guard advData.count >= 13 else { return nil }
        let bytes = [UInt8](advData)
        let txPowerChar = bytes[1]
        if txPowerChar & 0x80 != 0 {
            self.rangingData = NSNumber(value: Int(txPowerChar) - 0x100)
        } else {
            self.rangingData = NSNumber(value: Int(txPowerChar))
        }
        let tempContent = MKSwiftBleSDKAdopter.hexStringFromData(advData)
        self.interval = MKSwiftBleSDKAdopter.getDecimalStringWithHex(tempContent, range: NSRange(location: 4, length: 2))
        self.battery = MKSwiftBleSDKAdopter.getDecimalStringWithHex(tempContent, range: NSRange(location: 6, length: 4))
        let binary1 = MKSwiftBleSDKAdopter.binaryByhex(tempContent.bleSubstring(from: 10, length: 2))
        self.lockState = "00"
        if binary1.bleSubstring(from: 6, length: 2) == "10" {
            self.lockState = "02"
        }
        self.lightSensor = (binary1.bleSubstring(from: 5, length: 1) == "1")
        self.tamperSensor = (binary1.bleSubstring(from: 3, length: 1) == "1")
        let binary2 = MKSwiftBleSDKAdopter.binaryByhex(tempContent.bleSubstring(from: 12, length: 2))
        self.lightSensorStatus = (binary2.bleSubstring(from: 6, length: 1) == "1")
        self.tamperAlert = (binary2.bleSubstring(from: 4, length: 1) == "1")
        let tempMac = tempContent.bleSubstring(from: 14, length: 12).uppercased()
        self.macAddress = "\(tempMac.bleSubstring(from: 0, length: 2)):" +
                          "\(tempMac.bleSubstring(from: 2, length: 2)):" +
                          "\(tempMac.bleSubstring(from: 4, length: 2)):" +
                          "\(tempMac.bleSubstring(from: 6, length: 2)):" +
                          "\(tempMac.bleSubstring(from: 8, length: 2)):" +
                          "\(tempMac.bleSubstring(from: 10, length: 2))"
        self.softVersion = "\(MKSwiftBleSDKAdopter.getDecimalStringWithHex(tempContent, range: NSRange(location: 26, length: 2))).\(MKSwiftBleSDKAdopter.getDecimalStringWithHex(tempContent, range: NSRange(location: 28, length: 2)))"
    }
}

// MARK: - iBeacon
public class MKBXPiBeacon: MKBXPBaseBeacon {
    /// RSSI@1m
    public var rssi1M: NSNumber = 0
    public var txPower: NSNumber = 0
    /// 广播间隔
    public var interval: String = ""

    public var major: String = ""

    public var minor: String = ""

    public var uuid: String = ""

    public init?(advertiseData advData: Data) {
        super.init()
        assert(!(advData.count < 7), "Invalid advertiseData:\(advData)")
        guard advData.count >= 7 else { return nil }
        let bytes = [UInt8](advData)
        let txPowerChar = bytes[1]
        if txPowerChar & 0x80 != 0 {
            self.rssi1M = NSNumber(value: Int(txPowerChar) - 0x100)
        } else {
            self.rssi1M = NSNumber(value: Int(txPowerChar))
        }
        let content = MKSwiftBleSDKAdopter.hexStringFromData(advData)
        let temp = content.bleSubstring(from: 4, length: content.count - 4)
        self.interval = MKSwiftBleSDKAdopter.getDecimalStringWithHex(temp, range: NSRange(location: 0, length: 2))
        var array: [String] = [
            temp.bleSubstring(from: 2, length: 8),
            temp.bleSubstring(from: 10, length: 4),
            temp.bleSubstring(from: 14, length: 4),
            temp.bleSubstring(from: 18, length: 4),
            temp.bleSubstring(from: 22, length: 12)
        ]
        array.insert("-", at: 1)
        array.insert("-", at: 3)
        array.insert("-", at: 5)
        array.insert("-", at: 7)
        self.uuid = array.joined().uppercased()
        let majorHex = temp.bleSubstring(from: 34, length: 4)
        let minorHex = temp.bleSubstring(from: 38, length: 4)
        if let majorValue = UInt64(majorHex, radix: 16) {
            self.major = String(format: "%ld", majorValue)
        }
        if let minorValue = UInt64(minorHex, radix: 16) {
            self.minor = String(format: "%ld", minorValue)
        }
    }
}

// MARK: - 3-axis Sensor Beacon
public class MKBXPThreeASensorBeacon: MKBXPBaseBeacon {
    /// RSSI@0m
    public var rssi0M: NSNumber = 0
    public var txPower: NSNumber = 0
    /// 广播间隔，单位：100ms
    public var interval: String = ""
    /**
     采样率，@"00":1Hz,@"01":10Hz,@"02":25Hz,@"03":50Hz,@"04":100Hz,
     @"05":200Hz,@"06":400Hz,@"07":1344Hz,@"08":1620Hz,@"09":5376Hz
     */
    public var samplingRate: String = ""
    /**
     3-axis accelerometer scale,@"00":±2g,@"01"":±4g,@"02":±8g,@"03":±16g
     */
    public var accelerationOfGravity: String = ""
    /// 3-axis accelerometer sensitivity
    public var sensitivity: String = ""

    public var xData: String = ""

    public var yData: String = ""

    public var zData: String = ""

    /// 电池电压（固件版本不低于 1.1 支持）
    public var battery: String = ""
    /// 传感器类型（固件版本不低于 1.1 支持）
    public var sensorType: String = ""
    /// 固件版本不低于 1.1 支持
    public var macAddress: String = ""

    public init?(advertiseData advData: Data) {
        super.init()
        let bytes = [UInt8](advData)
        guard bytes.count >= 2 else { return nil }
        let txPowerChar = bytes[1]
        if txPowerChar & 0x80 != 0 {
            self.rssi0M = NSNumber(value: Int(txPowerChar) - 0x100)
        } else {
            self.rssi0M = NSNumber(value: Int(txPowerChar))
        }
        let content = MKSwiftBleSDKAdopter.hexStringFromData(advData)
        let temp = content.bleSubstring(from: 4, length: content.count - 4)
        self.interval = MKSwiftBleSDKAdopter.getDecimalStringWithHex(temp, range: NSRange(location: 0, length: 2))
        self.samplingRate = temp.bleSubstring(from: 2, length: 2)
        self.accelerationOfGravity = temp.bleSubstring(from: 4, length: 2)
        self.sensitivity = MKSwiftBleSDKAdopter.getDecimalStringWithHex(temp, range: NSRange(location: 6, length: 2))
        self.xData = temp.bleSubstring(from: 8, length: 4)
        self.yData = temp.bleSubstring(from: 12, length: 4)
        self.zData = temp.bleSubstring(from: 16, length: 4)
        if advData.count == 21 {
            self.battery = MKSwiftBleSDKAdopter.getDecimalStringWithHex(temp, range: NSRange(location: 20, length: 4))
            self.sensorType = temp.bleSubstring(from: 24, length: 2)
            let tempMac = temp.bleSubstring(from: 26, length: 12).uppercased()
            self.macAddress = "\(tempMac.bleSubstring(from: 0, length: 2)):" +
                              "\(tempMac.bleSubstring(from: 2, length: 2)):" +
                              "\(tempMac.bleSubstring(from: 4, length: 2)):" +
                              "\(tempMac.bleSubstring(from: 6, length: 2)):" +
                              "\(tempMac.bleSubstring(from: 8, length: 2)):" +
                              "\(tempMac.bleSubstring(from: 10, length: 2))"
        }
    }
}

// MARK: - TH Sensor Beacon
public class MKBXPTHSensorBeacon: MKBXPBaseBeacon {
    public var txPower: NSNumber = 0
    /// RSSI@0m
    public var rssi0M: NSNumber = 0
    /// 广播间隔，单位：100ms
    public var interval: String = ""
    /// 温度
    public var temperature: String = ""
    /// 湿度
    public var humidity: String = ""

    /// 电池电压（固件版本不低于 1.1 支持）
    public var battery: String = ""
    /// 传感器类型（固件版本不低于 1.1 支持）
    public var sensorType: String = ""
    /// 固件版本不低于 1.1 支持
    public var macAddress: String = ""

    public init?(advertiseData advData: Data) {
        super.init()
        let bytes = [UInt8](advData)
        guard bytes.count >= 2 else { return nil }
        let txPowerChar = bytes[1]
        if txPowerChar & 0x80 != 0 {
            self.rssi0M = NSNumber(value: Int(txPowerChar) - 0x100)
        } else {
            self.rssi0M = NSNumber(value: Int(txPowerChar))
        }
        let content = MKSwiftBleSDKAdopter.hexStringFromData(advData)
        let temp = content.bleSubstring(from: 4, length: content.count - 4)
        self.interval = MKSwiftBleSDKAdopter.getDecimalStringWithHex(temp, range: NSRange(location: 0, length: 2))
        let tempTemp = MKSwiftBleSDKAdopter.signedHexTurnToInt(temp.bleSubstring(from: 2, length: 4))
        let tempHui = MKSwiftBleSDKAdopter.getDecimalWithHex(temp, range: NSRange(location: 6, length: 4))
        self.temperature = String(format: "%.1f", Float(tempTemp) * 0.1)
        self.humidity = String(format: "%.1f", Float(tempHui) * 0.1)
        if advData.count == 16 {
            // 新版本固件
            self.battery = MKSwiftBleSDKAdopter.getDecimalStringWithHex(temp, range: NSRange(location: 10, length: 4))
            self.sensorType = temp.bleSubstring(from: 14, length: 2)
            let tempMac = temp.bleSubstring(from: 16, length: 12).uppercased()
            self.macAddress = "\(tempMac.bleSubstring(from: 0, length: 2)):" +
                              "\(tempMac.bleSubstring(from: 2, length: 2)):" +
                              "\(tempMac.bleSubstring(from: 4, length: 2)):" +
                              "\(tempMac.bleSubstring(from: 6, length: 2)):" +
                              "\(tempMac.bleSubstring(from: 8, length: 2)):" +
                              "\(tempMac.bleSubstring(from: 10, length: 2))"
        }
    }
}

// MARK: - OTA Beacon
public class MKBXPOTABeacon: MKBXPBaseBeacon {
}
