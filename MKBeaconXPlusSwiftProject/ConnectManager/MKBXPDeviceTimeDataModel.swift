//
//  MKBXPDeviceTimeDataModel.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import Foundation

/// 设备时间数据模型（实现 MKBXPDeviceTimeProtocol）
public final class MKBXPDeviceTimeDataModel: NSObject, MKBXPDeviceTimeProtocol {

    public var year: Int = 0
    public var month: Int = 0
    public var day: Int = 0
    public var hour: Int = 0
    public var minutes: Int = 0
    public var seconds: Int = 0

    public override init() {
        super.init()
    }
}
