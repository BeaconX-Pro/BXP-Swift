//
//  MKBXPAccelerationModel.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import Foundation
import MKBaseSwiftModule

/// 三轴加速度传感器参数模型
public final class MKBXPAccelerationModel: NSObject {

    /// 0:1hz, 1:10hz, 2:25hz, 3:50hz, 4:100hz
    public var samplingRate: Int = 0

    /// 0:±2g, 1:±4g, 2:±8g, 3:±16g
    public var scale: Int = 0

    /// 灵敏度
    public var sensitivityValue: Int = 0

    // MARK: - 私有

    private lazy var readQueue: DispatchQueue = {
        DispatchQueue(label: "accelerationQueue")
    }()

    private lazy var semaphore: DispatchSemaphore = {
        DispatchSemaphore(value: 0)
    }()

    // MARK: - 公开方法

    public func read(sucBlock: @escaping () -> Void,
                     failedBlock: @escaping (Error) -> Void) {
        readQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.readParams() else {
                self.operationFailedBlockWithMsg("Read Params Error", block: failedBlock)
                return
            }
            DispatchQueue.main.async {
                sucBlock()
            }
        }
    }

    public func config(sucBlock: @escaping () -> Void,
                       failedBlock: @escaping (Error) -> Void) {
        readQueue.async { [weak self] in
            guard let self = self else { return }
            guard self.configParams() else {
                self.operationFailedBlockWithMsg("Config Params Error", block: failedBlock)
                return
            }
            DispatchQueue.main.async {
                sucBlock()
            }
        }
    }

    // MARK: - Private：读写

    private func readParams() -> Bool {
        var success = false

        MKBXPInterface.bxp_readThreeAxisDataParams { [weak self] returnData in
            guard let self = self else {
                self?.semaphore.signal()
                return
            }
            success = true
            if let result = (returnData as? [String: Any])?["result"] as? [String: Any] {
                self.scale = Int(result["gravityReference"] as? String ?? "0") ?? 0
                self.samplingRate = Int(result["samplingRate"] as? String ?? "0") ?? 0
                self.sensitivityValue = Int(result["sensitivity"] as? String ?? "0") ?? 0
            }
            self.semaphore.signal()
        } failedBlock: { [weak self] _ in
            self?.semaphore.signal()
        }

        semaphore.wait()
        return success
    }

    private func configParams() -> Bool {
        var success = false

        let rate = MKBXPThreeAxisDataRate(rawValue: samplingRate) ?? .rate1Hz
        let ag = MKBXPThreeAxisDataAG(rawValue: scale) ?? .ag0

        MKBXPInterface.bxp_configThreeAxisDataParams(dataRate: rate,
                                                      acceleration: ag,
                                                      sensitivity: sensitivityValue) { [weak self] _ in
            success = true
            self?.semaphore.signal()
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
            let error = NSError(domain: "acceleration",
                                code: -999,
                                userInfo: ["errorInfo": msg])
            block(error)
        }
    }
}
