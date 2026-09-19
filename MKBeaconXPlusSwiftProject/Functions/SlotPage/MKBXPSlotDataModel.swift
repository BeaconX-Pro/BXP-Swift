//
//  MKBXPSlotDataModel.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import Foundation

import MKSwiftBeaconXCustomUI

/// Slot 列表 Cell 模型
public final class MKBXPSlotDataModel: NSObject {

    /// 数据通道类型
    public var slotType: MKSwiftBXSlotFrameType = .null

    /// 通道 index
    public var slotIndex: Int = 0

    /// 左侧标题
    public var leftMsg: String = ""

    /// 右侧文本
    public var rightMsg: String = ""

    public override init() {
        super.init()
    }
}
