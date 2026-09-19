//
//  MKBXPInterface.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import Foundation
@preconcurrency import CoreBluetooth
import MKSwiftBleModule

/// BXP 读接口集合
public enum MKBXPInterface {

    // MARK: - Device Service Information

    /// 读取设备类型
    /// 00: 无传感器, 01: 三轴加速度传感器, 02: 温湿度传感器, 03: 三轴加速度/温湿度传感器
    public static func bxp_readDeviceType(sucBlock: @escaping (Any) -> Void,
                                         failedBlock: @escaping (Error) -> Void) {
        guard let characteristic = MKBXPCentralManager.shared.peripheral()?.bxp_deviceType else {
            return
        }
        MKBXPCentralManager.shared.addReadTaskWithTaskID(.readDeviceType,
                                                          characteristic: characteristic,
                                                         sucBlock: sucBlock,
                                                         failedBlock: failedBlock)
    }

    /// 读取设备 MAC 地址
    public static func bxp_readMacAddres(sucBlock: @escaping (Any) -> Void,
                                        failedBlock: @escaping (Error) -> Void) {
        readData(withTaskID: .readMacAddress,
                 cmdFlag: "20",
                 sucBlock: sucBlock,
                 failedBlock: failedBlock)
    }

    /// 读取产品型号
    public static func bxp_readModeID(sucBlock: @escaping (Any) -> Void,
                                     failedBlock: @escaping (Error) -> Void) {
        guard let characteristic = MKBXPCentralManager.shared.peripheral()?.bxp_modeID else {
            // 新固件已经不支持180A服务下面的特征读取,通过自定义协议读
            readData(withTaskID: .readModeID,
                     cmdFlag: "2e",
                     sucBlock: sucBlock,
                     failedBlock: failedBlock)
            return
        }
        MKBXPCentralManager.shared.addReadTaskWithTaskID(.readModeID,
                                                          characteristic: characteristic,
                                                         sucBlock: sucBlock,
                                                         failedBlock: failedBlock)
    }

    /// 读取软件版本
    public static func bxp_readSoftware(sucBlock: @escaping (Any) -> Void,
                                        failedBlock: @escaping (Error) -> Void) {
        guard let characteristic = MKBXPCentralManager.shared.peripheral()?.bxp_software else {
            // 新固件已经不支持180A服务下面的特征读取,通过自定义协议读
            readData(withTaskID: .readSoftware,
                     cmdFlag: "2c",
                     sucBlock: sucBlock,
                     failedBlock: failedBlock)
            return
        }
        MKBXPCentralManager.shared.addReadTaskWithTaskID(.readSoftware,
                                                          characteristic: characteristic,
                                                         sucBlock: sucBlock,
                                                         failedBlock: failedBlock)
    }

    /// 读取固件版本
    public static func bxp_readFirmware(sucBlock: @escaping (Any) -> Void,
                                        failedBlock: @escaping (Error) -> Void) {
        guard let characteristic = MKBXPCentralManager.shared.peripheral()?.bxp_firmware else {
            // 新固件已经不支持180A服务下面的特征读取,通过自定义协议读
            readData(withTaskID: .readFirmware,
                     cmdFlag: "2b",
                     sucBlock: sucBlock,
                     failedBlock: failedBlock)
            return
        }
        MKBXPCentralManager.shared.addReadTaskWithTaskID(.readFirmware,
                                                          characteristic: characteristic,
                                                         sucBlock: sucBlock,
                                                         failedBlock: failedBlock)
    }

    /// 读取硬件版本
    public static func bxp_readHardware(sucBlock: @escaping (Any) -> Void,
                                       failedBlock: @escaping (Error) -> Void) {
        guard let characteristic = MKBXPCentralManager.shared.peripheral()?.bxp_hardware else {
            // 新固件已经不支持180A服务下面的特征读取,通过自定义协议读
            readData(withTaskID: .readHardware,
                     cmdFlag: "2d",
                     sucBlock: sucBlock,
                     failedBlock: failedBlock)
            return
        }
        MKBXPCentralManager.shared.addReadTaskWithTaskID(.readHardware,
                                                          characteristic: characteristic,
                                                         sucBlock: sucBlock,
                                                         failedBlock: failedBlock)
    }

    /// 读取生产日期
    public static func bxp_readProductionDate(sucBlock: @escaping (Any) -> Void,
                                              failedBlock: @escaping (Error) -> Void) {
        guard let characteristic = MKBXPCentralManager.shared.peripheral()?.bxp_productionDate else {
            // 新固件已经不支持180A服务下面的特征读取,通过自定义协议读
            readData(withTaskID: .readProductionDate,
                     cmdFlag: "4e",
                     sucBlock: sucBlock,
                     failedBlock: failedBlock)
            return
        }
        MKBXPCentralManager.shared.addReadTaskWithTaskID(.readProductionDate,
                                                          characteristic: characteristic,
                                                         sucBlock: sucBlock,
                                                         failedBlock: failedBlock)
    }

    /// 读取厂商信息
    public static func bxp_readVendor(sucBlock: @escaping (Any) -> Void,
                                      failedBlock: @escaping (Error) -> Void) {
        guard let characteristic = MKBXPCentralManager.shared.peripheral()?.bxp_vendor else {
            // 新固件已经不支持180A服务下面的特征读取,通过自定义协议读
            readData(withTaskID: .readVendor,
                     cmdFlag: "2a",
                     sucBlock: sucBlock,
                     failedBlock: failedBlock)
            return
        }
        MKBXPCentralManager.shared.addReadTaskWithTaskID(.readVendor,
                                                          characteristic: characteristic,
                                                         sucBlock: sucBlock,
                                                         failedBlock: failedBlock)
    }

    /// 读取电池电量百分比
    public static func bxp_readBattery(sucBlock: @escaping (Any) -> Void,
                                       failedBlock: @escaping (Error) -> Void) {
        guard let characteristic = MKBXPCentralManager.shared.peripheral()?.bxp_battery else {
            return
        }
        MKBXPCentralManager.shared.addReadTaskWithTaskID(.readBattery,
                                                          characteristic: characteristic,
                                                         sucBlock: sucBlock,
                                                         failedBlock: failedBlock)
    }

    /// 读取当前连接状态
    public static func bxp_readConnectEnableStatus(sucBlock: @escaping (Any) -> Void,
                                                    failedBlock: @escaping (Error) -> Void) {
        guard let characteristic = MKBXPCentralManager.shared.peripheral()?.bxp_remainConnectable else {
            return
        }
        MKBXPCentralManager.shared.addReadTaskWithTaskID(.readConnectEnable,
                                                          characteristic: characteristic,
                                                         sucBlock: sucBlock,
                                                         failedBlock: failedBlock)
    }

    /// 读取 6 个 SLOT 的当前帧类型
    /// @"00":UID, @"10":URL, @"20":TLM, @"40":Device Info,
    /// @"50":iBeacon, @"60":3-axis, @"70":H&T, @"FF":NO DATA
    public static func bxp_readSlotDataType(sucBlock: @escaping (Any) -> Void,
                                            failedBlock: @escaping (Error) -> Void) {
        guard let characteristic = MKBXPCentralManager.shared.peripheral()?.bxp_slotType else {
            return
        }
        MKBXPCentralManager.shared.addReadTaskWithTaskID(.readSlotType,
                                                          characteristic: characteristic,
                                                         sucBlock: sucBlock,
                                                         failedBlock: failedBlock)
    }

    /// 读取 Radio Tx Power
    public static func bxp_readRadioTxPower(sucBlock: @escaping (Any) -> Void,
                                            failedBlock: @escaping (Error) -> Void) {
        guard let characteristic = MKBXPCentralManager.shared.peripheral()?.bxp_radioTxPower else {
            return
        }
        MKBXPCentralManager.shared.addReadTaskWithTaskID(.readRadioTxPower,
                                                          characteristic: characteristic,
                                                         sucBlock: sucBlock,
                                                         failedBlock: failedBlock)
    }

    /// 读取活跃 SLOT 的广播数据
    public static func bxp_readAdvData(sucBlock: @escaping (Any) -> Void,
                                      failedBlock: @escaping (Error) -> Void) {
        guard let characteristic = MKBXPCentralManager.shared.peripheral()?.bxp_advSlotData else {
            return
        }
        MKBXPCentralManager.shared.addReadTaskWithTaskID(.readAdvSlotData,
                                                          characteristic: characteristic,
                                                         sucBlock: sucBlock,
                                                         failedBlock: failedBlock)
    }

    /// 读取 Advertised Tx Power (RSSI@0m, 仅 eddystone 帧)
    public static func bxp_readAdvTxPower(sucBlock: @escaping (Any) -> Void,
                                          failedBlock: @escaping (Error) -> Void) {
        guard let characteristic = MKBXPCentralManager.shared.peripheral()?.bxp_advertisedTxPower else {
            return
        }
        MKBXPCentralManager.shared.addReadTaskWithTaskID(.readAdvTxPower,
                                                          characteristic: characteristic,
                                                         sucBlock: sucBlock,
                                                         failedBlock: failedBlock)
    }

    /// 读取当前 SLOT 的广播间隔
    public static func bxp_readAdvInterval(sucBlock: @escaping (Any) -> Void,
                                          failedBlock: @escaping (Error) -> Void) {
        guard let characteristic = MKBXPCentralManager.shared.peripheral()?.bxp_advertisingInterval else {
            return
        }
        MKBXPCentralManager.shared.addReadTaskWithTaskID(.readAdvertisingInterval,
                                                          characteristic: characteristic,
                                                         sucBlock: sucBlock,
                                                         failedBlock: failedBlock)
    }

    /// 读取三轴加速度传感器参数（采样率/量程/灵敏度）
    public static func bxp_readThreeAxisDataParams(sucBlock: @escaping (Any) -> Void,
                                                   failedBlock: @escaping (Error) -> Void) {
        readData(withTaskID: .readThreeAxisParams,
                 cmdFlag: "21",
                 sucBlock: sucBlock,
                 failedBlock: failedBlock)
    }

    /// 读取温湿度采样率
    public static func bxp_readHTSamplingRate(sucBlock: @escaping (Any) -> Void,
                                             failedBlock: @escaping (Error) -> Void) {
        readData(withTaskID: .readHTSamplingRate,
                 cmdFlag: "23",
                 sucBlock: sucBlock,
                 failedBlock: failedBlock)
    }

    /// 读取温湿度存储条件
    public static func bxp_readHTStorageConditions(sucBlock: @escaping (Any) -> Void,
                                                   failedBlock: @escaping (Error) -> Void) {
        readData(withTaskID: .readHTStorageConditions,
                 cmdFlag: "22",
                 sucBlock: sucBlock,
                 failedBlock: failedBlock)
    }

    /// 读取设备当前时间
    public static func bxp_readDeviceTime(sucBlock: @escaping (Any) -> Void,
                                         failedBlock: @escaping (Error) -> Void) {
        readData(withTaskID: .readDeviceTime,
                 cmdFlag: "25",
                 sucBlock: sucBlock,
                 failedBlock: failedBlock)
    }

    /// 读取设备当前触发条件
    public static func bxp_readTriggerConditions(sucBlock: @escaping (Any) -> Void,
                                                 failedBlock: @escaping (Error) -> Void) {
        readData(withTaskID: .readTriggerConditions,
                 cmdFlag: "29",
                 sucBlock: sucBlock,
                 failedBlock: failedBlock)
    }

    /// 读取设备是否可以按键关机
    /// 注意：生产日期在 2021.01.01 之后的设备支持此指令
    public static func bxp_readButtonPowerStatus(sucBlock: @escaping (Any) -> Void,
                                                 failedBlock: @escaping (Error) -> Void) {
        readData(withTaskID: .readButtonPowerStatus,
                 cmdFlag: "28",
                 sucBlock: sucBlock,
                 failedBlock: failedBlock)
    }

    /// 读取光感状态
    public static func bxp_readLightSensorStatus(sucBlock: @escaping (Any) -> Void,
                                                  failedBlock: @escaping (Error) -> Void) {
        guard let characteristic = MKBXPCentralManager.shared.peripheral()?.bxp_lightStatus else {
            return
        }
        MKBXPCentralManager.shared.addReadTaskWithTaskID(.readLightSensorStatus,
                                                          characteristic: characteristic,
                                                         sucBlock: sucBlock,
                                                         failedBlock: failedBlock)
    }

    /// 读取 LED 触发提醒状态
    public static func bxp_readLEDTriggerStatus(sucBlock: @escaping (Any) -> Void,
                                                failedBlock: @escaping (Error) -> Void) {
        readData(withTaskID: .readLEDTriggerStatus,
                 cmdFlag: "47",
                 sucBlock: sucBlock,
                 failedBlock: failedBlock)
    }

    /// 读取设备是否可以按键恢复出厂设置
    public static func bxp_readResetBeaconByButtonStatus(sucBlock: @escaping (Any) -> Void,
                                                        failedBlock: @escaping (Error) -> Void) {
        readData(withTaskID: .readResetBeaconByButtonStatus,
                 cmdFlag: "48",
                 sucBlock: sucBlock,
                 failedBlock: failedBlock)
    }

    /// 读取前 100 条历史数据（仅 BXP-CL-a 固件版本支持）
    public static func bxp_readHundredHistoryData(sucBlock: @escaping (Any) -> Void,
                                                  failedBlock: @escaping (Error) -> Void) {
        readData(withTaskID: .readHundredHistoryData,
                 cmdFlag: "4c",
                 sucBlock: sucBlock,
                 failedBlock: failedBlock)
    }

    /// 读取按键有效间隔时长（默认 600ms）
    public static func bxp_readEffectiveClickInterval(sucBlock: @escaping (Any) -> Void,
                                                       failedBlock: @escaping (Error) -> Void) {
        readData(withTaskID: .readEffectiveClickInterval,
                 cmdFlag: "4d",
                 sucBlock: sucBlock,
                 failedBlock: failedBlock)
    }

    /// 读取设备时间戳（仅 BXP-CL-a 固件版本支持）
    public static func bxp_readTimeStamp(sucBlock: @escaping (Any) -> Void,
                                         failedBlock: @escaping (Error) -> Void) {
        readData(withTaskID: .readTimeStamp,
                 cmdFlag: "4f",
                 sucBlock: sucBlock,
                 failedBlock: failedBlock)
    }

    /// 读取回应包开关状态
    public static func bxp_readScanResponsePacket(sucBlock: @escaping (Any) -> Void,
                                                  failedBlock: @escaping (Error) -> Void) {
        readData(withTaskID: .readScanResponsePacket,
                 cmdFlag: "2f",
                 sucBlock: sucBlock,
                 failedBlock: failedBlock)
    }

    /// 读取远程 LED 提醒参数
    public static func bxp_readRemoteReminderLEDNotiParams(sucBlock: @escaping (Any) -> Void,
                                                            failedBlock: @escaping (Error) -> Void) {
        readData(withTaskID: .readRemoteReminderLEDNotiParams,
                 cmdFlag: "61",
                 sucBlock: sucBlock,
                 failedBlock: failedBlock)
    }

    /// 读取远程蜂鸣器提醒参数
    public static func bxp_readRemoteReminderBuzzerNotiParams(sucBlock: @escaping (Any) -> Void,
                                                               failedBlock: @escaping (Error) -> Void) {
        readData(withTaskID: .readRemoteReminderBuzzerNotiParams,
                 cmdFlag: "62",
                 sucBlock: sucBlock,
                 failedBlock: failedBlock)
    }

    // MARK: - private

    /// 通过自定义特征发送读取命令的统一封装
    /// - Parameters:
    ///   - taskID: 任务 ID
    ///   - flag: 命令标识（2 字符十六进制）
    ///   - sucBlock: 成功回调
    ///   - failedBlock: 失败回调
    fileprivate static func readData(withTaskID taskID: MKBXPTaskOperationID,
                                     cmdFlag flag: String,
                                     sucBlock: @escaping (Any) -> Void,
                                     failedBlock: @escaping (Error) -> Void) {
        let commandString = "ea" + flag + "0000"
        guard let characteristic = MKBXPCentralManager.shared.peripheral()?.bxp_customWrite else {
            return
        }
        MKBXPCentralManager.shared.addTaskWithTaskID(taskID,
                                                     commandData: commandString, characteristic: characteristic,
                                                     sucBlock: sucBlock,
                                                     failedBlock: failedBlock)
    }
}
