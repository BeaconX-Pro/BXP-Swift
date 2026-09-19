//
//  MKBXPInterface+MKBXPConfig.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import Foundation
@preconcurrency import CoreBluetooth
import MKSwiftBleModule

// MARK: - BXP 配置枚举

/// 目标 SLOT 编号
public enum MKBXPActiveSlotNo: Int {
    case slot1 = 0
    case slot2
    case slot3
    case slot4
    case slot5
    case slot6
}

/// SLOT 发射功率
public enum MKBXPSlotRadioTxPower: Int {
    case neg40dBm = 0
    case neg20dBm
    case neg16dBm
    case neg12dBm
    case neg8dBm
    case neg4dBm
    case zero0dBm
    case three3dBm
    case four4dBm
}

/// URL Scheme 前缀类型
public enum MKBXPURLHeaderType: Int {
    case type1 = 0
    case type2
    case type3
    case type4
}

/// 三轴加速度采样率
public enum MKBXPThreeAxisDataRate: Int {
    case rate1Hz = 0
    case rate10Hz
    case rate25Hz
    case rate50Hz
    case rate100Hz
}

/// 三轴加速度量程
public enum MKBXPThreeAxisDataAG: Int {
    case ag0 = 0
    case ag1
    case ag2
    case ag3
}

/// 温湿度存储条件
public enum MKBXPHTStorageConditions: Int {
    case temperature = 0
    case humidity
    case temperatureOrHumidity
    case time
}

/// 远程 LED 提醒颜色
public enum MKBXPRemoteReminderLEDColor: Int {
    case red = 0
    case green
    case blue
}

// MARK: - BXP 配置协议

/// 设备时间协议
public protocol MKBXPDeviceTimeProtocol {
    var year: Int { get }
    var month: Int { get }
    var day: Int { get }
    var hour: Int { get }
    var minutes: Int { get }
    var seconds: Int { get }
}

/// 温湿度存储条件协议
public protocol MKBXPHTStorageConditionsProtocol {
    var condition: MKBXPHTStorageConditions { get }
    var temperature: Int { get }
    var humidity: Int { get }
    var time: Int { get }
}

// MARK: - BXP 配置接口
public extension MKBXPInterface {

    // MARK: - 密码与锁定

    static func bxp_configNewPassword(newPassword: String,
                                              originalPassword: String,
                                              sucBlock: @escaping (Any) -> Void,
                                              failedBlock: @escaping (Error) -> Void) {
        guard MKBXPAdopter.isPassword(newPassword),
              MKBXPAdopter.isPassword(originalPassword) else {
            operationParamsErrorBlock(failedBlock)
            return
        }
        var oldData = Data()
        for scalar in originalPassword.unicodeScalars {
            oldData.append(UInt8(scalar.value & 0xFF))
        }
        let oldPadding = 16 - oldData.count
        if oldPadding > 0 {
            oldData.append(Data(repeating: 0xff, count: oldPadding))
        }

        var newData = Data()
        for scalar in newPassword.unicodeScalars {
            newData.append(UInt8(scalar.value & 0xFF))
        }
        let newPadding = 16 - newData.count
        if newPadding > 0 {
            newData.append(Data(repeating: 0xff, count: newPadding))
        }

        guard let encryptData = MKBXPAdopter.aes128Encrypt(sourceData: newData, keyData: oldData),
              encryptData.count == 16 else {
            operationParamsErrorBlock(failedBlock)
            return
        }
        var commandData = Data([0x00])
        commandData.append(encryptData)
        let commandString = MKSwiftBleSDKAdopter.hexStringFromData(commandData)
        guard let characteristic = MKBXPCentralManager.shared.peripheral()?.bxp_lockState else {
            return
        }
        MKBXPCentralManager.shared.addTaskWithTaskID(.configLockState,
                                                     commandData: commandString,
                                                     characteristic: characteristic,
                                                     sucBlock: sucBlock,
                                                     failedBlock: failedBlock)
    }

    static func bxp_factoryDataReset(sucBlock: @escaping (Any) -> Void,
                                            failedBlock: @escaping (Error) -> Void) {
        guard let characteristic = MKBXPCentralManager.shared.peripheral()?.bxp_factoryReset else {
            return
        }
        MKBXPCentralManager.shared.addTaskWithTaskID(.configFactoryReset,
                                                     commandData: "0b",
                                                     characteristic: characteristic,
                                                     sucBlock: sucBlock,
                                                     failedBlock: failedBlock)
    }

    static func bxp_configLockState(_ lockState: MKBXPLockState,
                                           sucBlock: @escaping (Any) -> Void,
                                           failedBlock: @escaping (Error) -> Void) {
        var commandString = "00"
        if lockState == .open {
            commandString = "01"
        } else if lockState == .unlockAutoMaticRelockDisabled {
            commandString = "02"
        }
        guard let characteristic = MKBXPCentralManager.shared.peripheral()?.bxp_lockState else {
            return
        }
        MKBXPCentralManager.shared.addTaskWithTaskID(.configLockState,
                                                     commandData: commandString,
                                                     characteristic: characteristic,
                                                     sucBlock: sucBlock,
                                                     failedBlock: failedBlock)
    }

    static func bxp_configPowerOff(sucBlock: @escaping (Any) -> Void,
                                          failedBlock: @escaping (Error) -> Void) {
        configCustomData(withTaskID: .configPowerOff,
                         data: "ea260000",
                         sucBlock: sucBlock,
                         failedBlock: failedBlock)
    }

    static func bxp_configConnectStatus(_ connectEnable: Bool,
                                               sucBlock: @escaping (Any) -> Void,
                                               failedBlock: @escaping (Error) -> Void) {
        let commandString = connectEnable ? "01" : "00"
        guard let characteristic = MKBXPCentralManager.shared.peripheral()?.bxp_remainConnectable else {
            return
        }
        MKBXPCentralManager.shared.addTaskWithTaskID(.configConnectEnable,
                                                     commandData: commandString,
                                                     characteristic: characteristic,
                                                     sucBlock: sucBlock,
                                                     failedBlock: failedBlock)
    }

    // MARK: - SLOT 配置

    static func bxp_configActiveSlot(_ slotNo: MKBXPActiveSlotNo,
                                            sucBlock: @escaping (Any) -> Void,
                                            failedBlock: @escaping (Error) -> Void) {
        let slotNumber = fetchSlotNumber(slotNo)
        guard let characteristic = MKBXPCentralManager.shared.peripheral()?.bxp_activeSlot else {
            return
        }
        MKBXPCentralManager.shared.addTaskWithTaskID(.configActiveSlot,
                                                     commandData: slotNumber,
                                                     characteristic: characteristic,
                                                     sucBlock: sucBlock,
                                                     failedBlock: failedBlock)
    }

    static func bxp_configAdvTxPower(_ advTxPower: Int,
                                           sucBlock: @escaping (Any) -> Void,
                                           failedBlock: @escaping (Error) -> Void) {
        if advTxPower < -100 || advTxPower > 20 {
            operationParamsErrorBlock(failedBlock)
            return
        }
        let advPower = MKSwiftBleSDKAdopter.hexStringFromSignedNumber(advTxPower)
        guard let characteristic = MKBXPCentralManager.shared.peripheral()?.bxp_advertisedTxPower else {
            return
        }
        MKBXPCentralManager.shared.addTaskWithTaskID(.configAdvTxPower,
                                                     commandData: advPower,
                                                     characteristic: characteristic,
                                                     sucBlock: sucBlock,
                                                     failedBlock: failedBlock)
    }

    static func bxp_configRadioTxPower(_ power: MKBXPSlotRadioTxPower,
                                               sucBlock: @escaping (Any) -> Void,
                                               failedBlock: @escaping (Error) -> Void) {
        let commandString = fetchTxPower(power)
        guard let characteristic = MKBXPCentralManager.shared.peripheral()?.bxp_radioTxPower else {
            return
        }
        MKBXPCentralManager.shared.addTaskWithTaskID(.configRadioTxPower,
                                                     commandData: commandString,
                                                     characteristic: characteristic,
                                                     sucBlock: sucBlock,
                                                     failedBlock: failedBlock)
    }

    static func bxp_configAdvInterval(_ interval: Int,
                                             sucBlock: @escaping (Any) -> Void,
                                             failedBlock: @escaping (Error) -> Void) {
        if interval < 1 || interval > 100 {
            operationParamsErrorBlock(failedBlock)
            return
        }
        let advInterval = MKSwiftBleSDKAdopter.fetchHexValue(UInt(interval * 100), byteLen: 2)
        guard let characteristic = MKBXPCentralManager.shared.peripheral()?.bxp_advertisingInterval else {
            return
        }
        MKBXPCentralManager.shared.addTaskWithTaskID(.configAdvertisingInterval,
                                                     commandData: advInterval,
                                                     characteristic: characteristic,
                                                     sucBlock: sucBlock,
                                                     failedBlock: failedBlock)
    }

    // MARK: - 广播帧内容配置

    static func bxp_configTLMAdvData(sucBlock: @escaping (Any) -> Void,
                                            failedBlock: @escaping (Error) -> Void) {
        configAdvSlotData(commandString: "20",
                          sucBlock: sucBlock,
                          failedBlock: failedBlock)
    }

    static func bxp_configUIDAdvDataWithNameSpace(_ nameSpace: String,
                                                         instanceID: String,
                                                         sucBlock: @escaping (Any) -> Void,
                                                         failedBlock: @escaping (Error) -> Void) {
        guard MKBXPAdopter.isNameSpace(nameSpace),
              MKBXPAdopter.isInstanceID(instanceID) else {
            operationParamsErrorBlock(failedBlock)
            return
        }
        let commandString = "00" + nameSpace + instanceID
        configAdvSlotData(commandString: commandString,
                          sucBlock: sucBlock,
                          failedBlock: failedBlock)
    }

    static func bxp_configURLAdvData(_ urlHeader: MKBXPURLHeaderType,
                                            urlContent: String,
                                            sucBlock: @escaping (Any) -> Void,
                                            failedBlock: @escaping (Error) -> Void) {
        guard MKBXPAdopter.checkUrlContent(urlContent) else {
            operationParamsErrorBlock(failedBlock)
            return
        }
        var header = ""
        var tempHeader = ""
        switch urlHeader {
        case .type1:
            header = "00"
            tempHeader = "http://www."
        case .type2:
            header = "01"
            tempHeader = "https://www."
        case .type3:
            header = "02"
            tempHeader = "http://"
        case .type4:
            header = "03"
            tempHeader = "https://"
        }
        let urlString = MKBXPAdopter.fetchUrlString(header: tempHeader, urlContent: urlContent)
        let commandString = "10" + header + urlString
        configAdvSlotData(commandString: commandString,
                          sucBlock: sucBlock,
                          failedBlock: failedBlock)
    }

    static func bxp_configiBeaconAdvData(major: Int,
                                                minor: Int,
                                                uuid: String,
                                                sucBlock: @escaping (Any) -> Void,
                                                failedBlock: @escaping (Error) -> Void) {
        if major < 0 || major > 65535 || minor < 0 || minor > 65535 {
            operationParamsErrorBlock(failedBlock)
            return
        }
        guard !uuid.isEmpty, uuid.count == 32 else {
            operationParamsErrorBlock(failedBlock)
            return
        }
        for i in 0..<16 {
            let start = uuid.index(uuid.startIndex, offsetBy: i * 2)
            let end = uuid.index(start, offsetBy: 2)
            let tempHex = String(uuid[start..<end])
            if !MKSwiftBleSDKAdopter.checkHexCharacter(tempHex) {
                operationParamsErrorBlock(failedBlock)
                return
            }
        }
        let majorHex = MKSwiftBleSDKAdopter.fetchHexValue(UInt(major), byteLen: 2)
        let minorHex = MKSwiftBleSDKAdopter.fetchHexValue(UInt(minor), byteLen: 2)
        let cleanUUID = uuid.replacingOccurrences(of: "-", with: "")
        let commandString = "50" + cleanUUID + majorHex + minorHex
        guard let characteristic = MKBXPCentralManager.shared.peripheral()?.bxp_advSlotData else {
            return
        }
        MKBXPCentralManager.shared.addTaskWithTaskID(.configAdvSlotData,
                                                     commandData: commandString,
                                                     characteristic: characteristic,
                                                     sucBlock: { returnData in
                                                         Thread.sleep(forTimeInterval: 0.1)
                                                         sucBlock(returnData)
                                                     },
                                                     failedBlock: failedBlock)
    }

    static func bxp_configNODATAAdvData(sucBlock: @escaping (Any) -> Void,
                                               failedBlock: @escaping (Error) -> Void) {
        configAdvSlotData(commandString: "ff",
                          sucBlock: sucBlock,
                          failedBlock: failedBlock)
    }

    static func bxp_configDeviceInfoAdvData(deviceName: String,
                                                    sucBlock: @escaping (Any) -> Void,
                                                    failedBlock: @escaping (Error) -> Void) {
        guard !deviceName.isEmpty, deviceName.count <= 20 else {
            operationParamsErrorBlock(failedBlock)
            return
        }
        var tempString = ""
        for scalar in deviceName.unicodeScalars {
            tempString += String(format: "%02lx", Int(scalar.value))
        }
        let commandString = "40" + tempString
        guard let characteristic = MKBXPCentralManager.shared.peripheral()?.bxp_advSlotData else {
            return
        }
        MKBXPCentralManager.shared.addTaskWithTaskID(.configAdvSlotData,
                                                     commandData: commandString,
                                                     characteristic: characteristic,
                                                     sucBlock: { returnData in
                                                         Thread.sleep(forTimeInterval: 0.1)
                                                         sucBlock(returnData)
                                                     },
                                                     failedBlock: failedBlock)
    }

    static func bxp_configThreeAxisAdvData(sucBlock: @escaping (Any) -> Void,
                                                   failedBlock: @escaping (Error) -> Void) {
        configAdvSlotData(commandString: "60",
                          sucBlock: sucBlock,
                          failedBlock: failedBlock)
    }

    static func bxp_configHTAdvData(sucBlock: @escaping (Any) -> Void,
                                           failedBlock: @escaping (Error) -> Void) {
        configAdvSlotData(commandString: "70",
                          sucBlock: sucBlock,
                          failedBlock: failedBlock)
    }

    // MARK: - 传感器参数配置

    static func bxp_configThreeAxisDataParams(dataRate: MKBXPThreeAxisDataRate,
                                                     acceleration: MKBXPThreeAxisDataAG,
                                                     sensitivity: Int,
                                                     sucBlock: @escaping (Any) -> Void,
                                                     failedBlock: @escaping (Error) -> Void) {
        if sensitivity < 1 || sensitivity > 255 {
            operationParamsErrorBlock(failedBlock)
            return
        }
        let rate = fetchThreeAxisDataRate(dataRate)
        let ag = fetchThreeAxisDataAG(acceleration)
        let sen = MKSwiftBleSDKAdopter.fetchHexValue(UInt(sensitivity), byteLen: 1)
        let commandString = "ea310003" + rate + ag + sen
        configCustomData(withTaskID: .configThreeAxisParams,
                         data: commandString,
                         sucBlock: sucBlock,
                         failedBlock: failedBlock)
    }

    static func bxp_configDeviceTime(_ time: MKBXPDeviceTimeProtocol,
                                            sucBlock: @escaping (Any) -> Void,
                                            failedBlock: @escaping (Error) -> Void) {
        guard validTimeProtocol(time) else {
            operationParamsErrorBlock(failedBlock)
            return
        }
        let hexTime = getTimeString(time)
        guard !hexTime.isEmpty else {
            operationParamsErrorBlock(failedBlock)
            return
        }
        let commandString = "ea350006" + hexTime
        configCustomData(withTaskID: .configDeviceTime,
                         data: commandString,
                         sucBlock: sucBlock,
                         failedBlock: failedBlock)
    }

    static func bxp_configHTStorageConditions(_ params: MKBXPHTStorageConditionsProtocol,
                                                     sucBlock: @escaping (Any) -> Void,
                                                     failedBlock: @escaping (Error) -> Void) {
        guard validHTStorageConditionsProtocol(params) else {
            operationParamsErrorBlock(failedBlock)
            return
        }
        let commandString = fetchHTStorageConditionsCommand(params)
        guard !commandString.isEmpty else {
            operationParamsErrorBlock(failedBlock)
            return
        }
        configCustomData(withTaskID: .configHTStorageConditions,
                         data: commandString,
                         sucBlock: sucBlock,
                         failedBlock: failedBlock)
    }

    static func bxp_configHTSamplingRate(_ rate: Int,
                                                sucBlock: @escaping (Any) -> Void,
                                                failedBlock: @escaping (Error) -> Void) {
        if rate < 1 || rate > 65535 {
            operationParamsErrorBlock(failedBlock)
            return
        }
        let rateString = MKSwiftBleSDKAdopter.fetchHexValue(UInt(rate), byteLen: 2)
        let commandString = "ea330002" + rateString
        configCustomData(withTaskID: .configHTSamplingRate,
                         data: commandString,
                         sucBlock: sucBlock,
                         failedBlock: failedBlock)
    }

    // MARK: - 触发条件配置

    static func bxp_configTriggerConditionsNone(sucBlock: @escaping (Any) -> Void,
                                                       failedBlock: @escaping (Error) -> Void) {
        configCustomData(withTaskID: .configTriggerConditions,
                         data: "ea39000100",
                         sucBlock: sucBlock,
                         failedBlock: failedBlock)
    }

    static func bxp_configTriggerConditionsWithTemperature(above: Bool,
                                                                  temperature: Int,
                                                                  startAdvertising start: Bool,
                                                                  sucBlock: @escaping (Any) -> Void,
                                                                  failedBlock: @escaping (Error) -> Void) {
        if temperature < -20 || temperature > 90 {
            operationParamsErrorBlock(failedBlock)
            return
        }
        var tempString = String(format: "%lX", UInt(bitPattern: temperature * 10))
        if tempString.count == 1 {
            tempString = "000" + tempString
        } else if tempString.count == 2 {
            tempString = "00" + tempString
        } else if tempString.count == 3 {
            tempString = "0" + tempString
        } else if tempString.count > 4 {
            tempString = String(tempString.suffix(4))
        }
        let aboveString = above ? "01" : "02"
        let advertising = start ? "01" : "02"
        let commandString = "ea39000501" + aboveString + tempString + advertising
        configCustomData(withTaskID: .configTriggerConditions,
                         data: commandString,
                         sucBlock: sucBlock,
                         failedBlock: failedBlock)
    }

    static func bxp_configTriggerConditionsWithHudimity(above: Bool,
                                                                humidity: Int,
                                                                startAdvertising start: Bool,
                                                                sucBlock: @escaping (Any) -> Void,
                                                                failedBlock: @escaping (Error) -> Void) {
        if humidity < 0 || humidity > 100 {
            operationParamsErrorBlock(failedBlock)
            return
        }
        var tempString = String(format: "%lX", UInt(bitPattern: humidity * 10))
        if tempString.count == 1 {
            tempString = "000" + tempString
        } else if tempString.count == 2 {
            tempString = "00" + tempString
        } else if tempString.count == 3 {
            tempString = "0" + tempString
        } else if tempString.count > 4 {
            tempString = String(tempString.suffix(4))
        }
        let aboveString = above ? "01" : "02"
        let advertising = start ? "01" : "02"
        let commandString = "ea39000502" + aboveString + tempString + advertising
        configCustomData(withTaskID: .configTriggerConditions,
                         data: commandString,
                         sucBlock: sucBlock,
                         failedBlock: failedBlock)
    }

    static func bxp_configTriggerConditionsWithDoubleTap(_ time: Int,
                                                                start: Bool,
                                                                sucBlock: @escaping (Any) -> Void,
                                                                failedBlock: @escaping (Error) -> Void) {
        if time < 0 || time > 65535 {
            operationParamsErrorBlock(failedBlock)
            return
        }
        let timeString = MKSwiftBleSDKAdopter.fetchHexValue(UInt(time), byteLen: 2)
        let commandString = "ea39000403" + timeString + (start ? "01" : "02")
        configCustomData(withTaskID: .configTriggerConditions,
                         data: commandString,
                         sucBlock: sucBlock,
                         failedBlock: failedBlock)
    }

    static func bxp_configTriggerConditionsWithTripleTap(_ time: Int,
                                                                start: Bool,
                                                                sucBlock: @escaping (Any) -> Void,
                                                                failedBlock: @escaping (Error) -> Void) {
        if time < 0 || time > 65535 {
            operationParamsErrorBlock(failedBlock)
            return
        }
        let timeString = MKSwiftBleSDKAdopter.fetchHexValue(UInt(time), byteLen: 2)
        let commandString = "ea39000404" + timeString + (start ? "01" : "02")
        configCustomData(withTaskID: .configTriggerConditions,
                         data: commandString,
                         sucBlock: sucBlock,
                         failedBlock: failedBlock)
    }

    static func bxp_configTriggerConditionsWithMoves(_ time: Int,
                                                           start: Bool,
                                                           sucBlock: @escaping (Any) -> Void,
                                                           failedBlock: @escaping (Error) -> Void) {
        if time < 0 || time > 65535 {
            operationParamsErrorBlock(failedBlock)
            return
        }
        let timeString = MKSwiftBleSDKAdopter.fetchHexValue(UInt(time), byteLen: 2)
        let commandString = "ea39000405" + timeString + (start ? "01" : "02")
        configCustomData(withTaskID: .configTriggerConditions,
                         data: commandString,
                         sucBlock: sucBlock,
                         failedBlock: failedBlock)
    }

    static func bxp_configTriggerConditionsWithAmbientLightDetected(_ time: Int,
                                                                            start: Bool,
                                                                            sucBlock: @escaping (Any) -> Void,
                                                                            failedBlock: @escaping (Error) -> Void) {
        if time < 0 || time > 65535 {
            operationParamsErrorBlock(failedBlock)
            return
        }
        let timeString = MKSwiftBleSDKAdopter.fetchHexValue(UInt(time), byteLen: 2)
        let commandString = "ea39000506" + timeString + (time == 0 ? "00" : "01") + (start ? "01" : "02")
        configCustomData(withTaskID: .configTriggerConditions,
                         data: commandString,
                         sucBlock: sucBlock,
                         failedBlock: failedBlock)
    }

    static func bxp_configTriggerConditionsWithSingleTap(_ time: Int,
                                                                start: Bool,
                                                                sucBlock: @escaping (Any) -> Void,
                                                                failedBlock: @escaping (Error) -> Void) {
        if time < 0 || time > 65535 {
            operationParamsErrorBlock(failedBlock)
            return
        }
        let timeString = MKSwiftBleSDKAdopter.fetchHexValue(UInt(time), byteLen: 2)
        let commandString = "ea39000407" + timeString + (start ? "01" : "02")
        configCustomData(withTaskID: .configTriggerConditions,
                         data: commandString,
                         sucBlock: sucBlock,
                         failedBlock: failedBlock)
    }

    static func bxp_configTriggerConditionsWithTamperDetect(_ time: Int,
                                                                   start: Bool,
                                                                   sucBlock: @escaping (Any) -> Void,
                                                                   failedBlock: @escaping (Error) -> Void) {
        if time < 0 || time > 65535 {
            operationParamsErrorBlock(failedBlock)
            return
        }
        let timeString = MKSwiftBleSDKAdopter.fetchHexValue(UInt(time), byteLen: 2)
        let commandString = "ea39000408" + timeString + (start ? "01" : "02")
        configCustomData(withTaskID: .configTriggerConditions,
                         data: commandString,
                         sucBlock: sucBlock,
                         failedBlock: failedBlock)
    }

    // MARK: - 数据清除

    static func bxp_deleteBXPRecordHTDatas(sucBlock: @escaping (Any) -> Void,
                                                  failedBlock: @escaping (Error) -> Void) {
        configCustomData(withTaskID: .deleteRecordHTData,
                         data: "ea240000",
                         sucBlock: sucBlock,
                         failedBlock: failedBlock)
    }

    static func bxp_configButtonPowerStatus(_ isOn: Bool,
                                                   sucBlock: @escaping (Any) -> Void,
                                                   failedBlock: @escaping (Error) -> Void) {
        let commandString = isOn ? "ea38000101" : "ea38000100"
        configCustomData(withTaskID: .configButtonPowerStatus,
                         data: commandString,
                         sucBlock: sucBlock,
                         failedBlock: failedBlock)
    }

    static func bxp_clearLightSensorDatas(sucBlock: @escaping (Any) -> Void,
                                                 failedBlock: @escaping (Error) -> Void) {
        configCustomData(withTaskID: .deleteRecordLightSensorData,
                         data: "ea460000",
                         sucBlock: sucBlock,
                         failedBlock: failedBlock)
    }

    static func bxp_configLEDTriggerStatus(_ isOn: Bool,
                                                  sucBlock: @escaping (Any) -> Void,
                                                  failedBlock: @escaping (Error) -> Void) {
        let commandString = isOn ? "ea57000101" : "ea57000100"
        configCustomData(withTaskID: .configLEDTriggerStatus,
                         data: commandString,
                         sucBlock: sucBlock,
                         failedBlock: failedBlock)
    }

    static func bxp_configResetBeaconByButtonStatus(_ isOn: Bool,
                                                           sucBlock: @escaping (Any) -> Void,
                                                           failedBlock: @escaping (Error) -> Void) {
        let commandString = isOn ? "ea58000101" : "ea58000100"
        configCustomData(withTaskID: .configResetBeaconByButtonStatus,
                         data: commandString,
                         sucBlock: sucBlock,
                         failedBlock: failedBlock)
    }

    static func bxp_configEffectiveClickInterval(_ interval: Int,
                                                        sucBlock: @escaping (Any) -> Void,
                                                        failedBlock: @escaping (Error) -> Void) {
        if interval < 5 || interval > 15 {
            operationParamsErrorBlock(failedBlock)
            return
        }
        let value = MKSwiftBleSDKAdopter.fetchHexValue(UInt(interval * 100), byteLen: 2)
        let commandString = "ea5d0002" + value
        configCustomData(withTaskID: .configEffectiveClickInterval,
                         data: commandString,
                         sucBlock: sucBlock,
                         failedBlock: failedBlock)
    }

    static func bxp_configScanResponsePacket(_ isOn: Bool,
                                                    sucBlock: @escaping (Any) -> Void,
                                                    failedBlock: @escaping (Error) -> Void) {
        let commandString = isOn ? "ea3f000101" : "ea3f000100"
        configCustomData(withTaskID: .configScanResponsePacket,
                         data: commandString,
                         sucBlock: sucBlock,
                         failedBlock: failedBlock)
    }

    static func bxp_configRemoteReminderLEDNotiParams(blinkingTime: Int,
                                                              blinkingInterval: Int,
                                                              color: MKBXPRemoteReminderLEDColor,
                                                              sucBlock: @escaping (Any) -> Void,
                                                              failedBlock: @escaping (Error) -> Void) {
        if blinkingTime < 10 || blinkingTime > 6000 || blinkingInterval < 1 || blinkingInterval > 100 {
            operationParamsErrorBlock(failedBlock)
            return
        }
        let colorString = MKSwiftBleSDKAdopter.fetchHexValue(UInt(color.rawValue + 3), byteLen: 1)
        let time = MKSwiftBleSDKAdopter.fetchHexValue(UInt(blinkingTime), byteLen: 2)
        let interval = MKSwiftBleSDKAdopter.fetchHexValue(UInt(blinkingInterval), byteLen: 2)
        let commandString = "ea710005" + colorString + interval + time
        configCustomData(withTaskID: .configRemoteReminderLEDNotiParams,
                         data: commandString,
                         sucBlock: sucBlock,
                         failedBlock: failedBlock)
    }

    static func bxp_configRemoteReminderBuzzerNotiParams(ringingTime: Int,
                                                                 ringingInterval: Int,
                                                                 frequent: Int,
                                                                 sucBlock: @escaping (Any) -> Void,
                                                                 failedBlock: @escaping (Error) -> Void) {
        if ringingTime < 10 || ringingTime > 6000 || ringingInterval < 1 || ringingInterval > 100 || frequent < 200 || frequent > 20000 {
            operationParamsErrorBlock(failedBlock)
            return
        }
        let frequentHex = MKSwiftBleSDKAdopter.fetchHexValue(UInt(frequent), byteLen: 2)
        let time = MKSwiftBleSDKAdopter.fetchHexValue(UInt(ringingTime), byteLen: 2)
        let interval = MKSwiftBleSDKAdopter.fetchHexValue(UInt(ringingInterval), byteLen: 2)
        let commandString = "ea720006" + frequentHex + interval + time
        configCustomData(withTaskID: .configRemoteReminderBuzzerNotiParams,
                         data: commandString,
                         sucBlock: sucBlock,
                         failedBlock: failedBlock)
    }

    // MARK: - private

    fileprivate static func configAdvSlotData(commandString: String,
                                              sucBlock: @escaping (Any) -> Void,
                                              failedBlock: @escaping (Error) -> Void) {
        guard let characteristic = MKBXPCentralManager.shared.peripheral()?.bxp_advSlotData else {
            return
        }
        MKBXPCentralManager.shared.addTaskWithTaskID(.configAdvSlotData,
                                                     commandData: commandString,
                                                     characteristic: characteristic,
                                                     sucBlock: sucBlock,
                                                     failedBlock: failedBlock)
    }

    fileprivate static func configCustomData(withTaskID taskID: MKBXPTaskOperationID,
                                             data: String,
                                             sucBlock: @escaping (Any) -> Void,
                                             failedBlock: @escaping (Error) -> Void) {
        guard let characteristic = MKBXPCentralManager.shared.peripheral()?.bxp_customWrite else {
            return
        }
        MKBXPCentralManager.shared.addTaskWithTaskID(taskID,
                                                     commandData: data,
                                                     characteristic: characteristic,
                                                     sucBlock: sucBlock,
                                                     failedBlock: failedBlock)
    }

    fileprivate static func fetchSlotNumber(_ slotNo: MKBXPActiveSlotNo) -> String {
        switch slotNo {
        case .slot1: return "00"
        case .slot2: return "01"
        case .slot3: return "02"
        case .slot4: return "03"
        case .slot5: return "04"
        case .slot6: return "05"
        }
    }

    fileprivate static func fetchTxPower(_ power: MKBXPSlotRadioTxPower) -> String {
        switch power {
        case .four4dBm:    return "04"
        case .three3dBm:   return "03"
        case .zero0dBm:    return "00"
        case .neg4dBm:     return "fc"
        case .neg8dBm:     return "f8"
        case .neg12dBm:    return "f4"
        case .neg16dBm:    return "f0"
        case .neg20dBm:    return "ec"
        case .neg40dBm:    return "d8"
        }
    }

    fileprivate static func fetchThreeAxisDataRate(_ dataRate: MKBXPThreeAxisDataRate) -> String {
        switch dataRate {
        case .rate1Hz:    return "00"
        case .rate10Hz:   return "01"
        case .rate25Hz:   return "02"
        case .rate50Hz:   return "03"
        case .rate100Hz:  return "04"
        }
    }

    fileprivate static func fetchThreeAxisDataAG(_ ag: MKBXPThreeAxisDataAG) -> String {
        switch ag {
        case .ag0:  return "00"
        case .ag1:  return "01"
        case .ag2:  return "02"
        case .ag3:  return "03"
        }
    }

    fileprivate static func validTimeProtocol(_ time: MKBXPDeviceTimeProtocol) -> Bool {
        if time.year < 2000 || time.year > 2099 { return false }
        if time.month < 1 || time.month > 12 { return false }
        if time.day < 1 || time.day > 31 { return false }
        if time.hour < 0 || time.hour > 23 { return false }
        if time.minutes < 0 || time.minutes > 59 { return false }
        if time.seconds < 0 || time.seconds > 59 { return false }
        return true
    }

    fileprivate static func getTimeString(_ time: MKBXPDeviceTimeProtocol) -> String {
        let yearValue = time.year - 2000
        let yearString = MKSwiftBleSDKAdopter.fetchHexValue(UInt(yearValue), byteLen: 1)
        let monthString = MKSwiftBleSDKAdopter.fetchHexValue(UInt(time.month), byteLen: 1)
        let dayString = MKSwiftBleSDKAdopter.fetchHexValue(UInt(time.day), byteLen: 1)
        let hourString = MKSwiftBleSDKAdopter.fetchHexValue(UInt(time.hour), byteLen: 1)
        let minString = MKSwiftBleSDKAdopter.fetchHexValue(UInt(time.minutes), byteLen: 1)
        let secString = MKSwiftBleSDKAdopter.fetchHexValue(UInt(time.seconds), byteLen: 1)
        return yearString + monthString + dayString + hourString + minString + secString
    }

    fileprivate static func validHTStorageConditionsProtocol(_ params: MKBXPHTStorageConditionsProtocol) -> Bool {
        switch params.condition {
        case .temperature:
            if params.temperature < 0 || params.temperature > 1000 { return false }
        case .humidity:
            if params.humidity < 0 || params.humidity > 1000 { return false }
        case .temperatureOrHumidity:
            if params.temperature < 0 || params.temperature > 1000 { return false }
            if params.humidity < 0 || params.humidity > 1000 { return false }
        case .time:
            if params.time < 1 || params.time > 255 { return false }
        }
        return true
    }

    fileprivate static func fetchHTStorageConditionsCommand(_ params: MKBXPHTStorageConditionsProtocol) -> String {
        switch params.condition {
        case .temperature:
            let temper = MKSwiftBleSDKAdopter.fetchHexValue(UInt(params.temperature), byteLen: 2)
            return "ea32000300" + temper
        case .humidity:
            let humi = MKSwiftBleSDKAdopter.fetchHexValue(UInt(params.humidity), byteLen: 2)
            return "ea32000301" + humi
        case .temperatureOrHumidity:
            let temper = MKSwiftBleSDKAdopter.fetchHexValue(UInt(params.temperature), byteLen: 2)
            let humi = MKSwiftBleSDKAdopter.fetchHexValue(UInt(params.humidity), byteLen: 2)
            return "ea32000502" + temper + humi
        case .time:
            let time = MKSwiftBleSDKAdopter.fetchHexValue(UInt(params.time), byteLen: 1)
            return "ea32000203" + time
        }
    }

    fileprivate static func operationParamsErrorBlock(_ failedBlock: @escaping (Error) -> Void) {
        let error = NSError(domain: "com.moko.BXPCentralManager",
                             code: -999,
                             userInfo: ["errorInfo": "Params error"])
        DispatchQueue.main.async {
            failedBlock(error)
        }
    }
}
