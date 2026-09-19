//
//  MKBXPLightSensorDataModel.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import Foundation
import MKBaseSwiftModule

/// 光感数据模型
public final class MKBXPLightSensorDataModel: NSObject {

    /// 是否检测到环境光
    public var detected: Bool = false

    /// 日期，格式 "yyyy/MM/dd HH:mm:ss"
    public var date: String = ""

    // MARK: - 私有

    private lazy var readQueue: DispatchQueue = {
        DispatchQueue(label: "lightSensorQueue")
    }()

    private lazy var semaphore: DispatchSemaphore = {
        DispatchSemaphore(value: 0)
    }()

    // MARK: - 公开方法

    public func read(sucBlock: @escaping () -> Void,
                     failedBlock: @escaping (Error) -> Void) {
        readQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.readDetected() else {
                self.operationFailedBlockWithMsg("Read Detected Error", block: failedBlock)
                return
            }
            guard self.readDeviceTime() else {
                self.operationFailedBlockWithMsg("Read Device Time Error", block: failedBlock)
                return
            }
            DispatchQueue.main.async {
                sucBlock()
            }
        }
    }

    // MARK: - Private：读取

    private func readDetected() -> Bool {
        var success = false

        MKBXPInterface.bxp_readLightSensorStatus { [weak self] returnData in
            guard let self = self else {
                self?.semaphore.signal()
                return
            }
            success = true
            if let result = (returnData as? [String: Any])?["result"] as? [String: Any] {
                self.detected = (result["status"] as? String) == "01"
            }
            self.semaphore.signal()
        } failedBlock: { [weak self] _ in
            self?.semaphore.signal()
        }

        semaphore.wait()
        return success
    }

    private func readDeviceTime() -> Bool {
        var success = false

        MKBXPInterface.bxp_readDeviceTime { [weak self] returnData in
            guard let self = self else {
                self?.semaphore.signal()
                return
            }
            success = true
            if let result = (returnData as? [String: Any])?["result"] as? [String: Any],
               let deviceTime = result["deviceTime"] as? String {
                let dateList = deviceTime.components(separatedBy: "-")
                if dateList.count >= 6 {
                    self.date = "\(dateList[2])/\(dateList[1])/\(dateList[0]) \(dateList[3]):\(dateList[4]):\(dateList[5])"
                }
            }
            self.semaphore.signal()
        } failedBlock: { [weak self] _ in
            self?.semaphore.signal()
        }

        semaphore.wait()
        return success
    }

    // MARK: - Private：失败处理

    private func operationFailedBlockWithMsg(_ msg: String,
                                             block: @escaping (Error) -> Void) {
        DispatchQueue.main.async {
            let error = NSError(domain: "lightSensorParams",
                                code: -999,
                                userInfo: ["errorInfo": msg])
            block(error)
        }
    }
}
