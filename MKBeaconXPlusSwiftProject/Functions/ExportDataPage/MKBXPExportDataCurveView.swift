//
//  MKBXPExportDataCurveView.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import UIKit
import SnapKit
import MKBaseSwiftModule

public final class MKBXPExportDataCurveView: UIView {

    // MARK: - Subviews

    private lazy var totalLabel: UILabel = {
        let label = UILabel()
        label.textColor = .blue
        label.textAlignment = .right
        label.font = MKFont.font(10)
        label.text = "Total Data Points: 0"
        return label
    }()

    private lazy var displayLabel: UILabel = {
        let label = UILabel()
        label.textColor = .blue
        label.textAlignment = .right
        label.font = MKFont.font(10)
        label.text = "Window Display Points: 0"
        return label
    }()

    private lazy var tempView: MKBXPTHCurveView = {
        let view = MKBXPTHCurveView()
        return view
    }()

    private lazy var tempModel: MKBXPTHCurveViewModel = {
        let model = MKBXPTHCurveViewModel()
        model.curveTitle = "Temperature(℃)"
        model.curveViewBackgroundColor = .white
        model.lineWidth = 3
        model.labelColor = UIColor(red: 136/255.0, green: 136/255.0, blue: 136/255.0, alpha: 1)
        return model
    }()

    private lazy var humidityView: MKBXPTHCurveView = {
        let view = MKBXPTHCurveView()
        return view
    }()

    private lazy var humidityModel: MKBXPTHCurveViewModel = {
        let model = MKBXPTHCurveViewModel()
        model.lineColor = .green
        model.curveViewBackgroundColor = .white
        model.lineWidth = 3
        model.curveTitle = "Humidity(%RH)"
        model.labelColor = UIColor(red: 136/255.0, green: 136/255.0, blue: 136/255.0, alpha: 1)
        return model
    }()

    // MARK: - Init

    public override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .white
        addSubview(tempView)
        addSubview(humidityView)
        addSubview(totalLabel)
        addSubview(displayLabel)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    public override func layoutSubviews() {
        super.layoutSubviews()

        totalLabel.snp.makeConstraints { make in
            make.left.equalTo(10)
            make.right.equalTo(-10)
            make.top.equalTo(5)
            make.height.equalTo(MKFont.font(10).lineHeight)
        }
        displayLabel.snp.makeConstraints { make in
            make.left.equalTo(10)
            make.right.equalTo(-10)
            make.top.equalTo(totalLabel.snp.bottom).offset(3)
            make.height.equalTo(MKFont.font(10).lineHeight)
        }
        tempView.snp.remakeConstraints { make in
            make.left.equalTo(5)
            make.right.equalTo(-5)
            make.top.equalTo(20)
            make.bottom.equalTo(self.snp.centerY).offset(-5)
        }
        humidityView.snp.remakeConstraints { make in
            make.left.equalTo(5)
            make.right.equalTo(-5)
            make.top.equalTo(self.snp.centerY).offset(5)
            make.height.equalTo(tempView)
        }
    }

    // MARK: - Public

    /// 绘制温湿度曲线图
    public func updateTemperatureDatas(_ temperatureList: [String],
                                       temperatureMax: CGFloat,
                                       temperatureMin: CGFloat,
                                       humidityList: [String],
                                       humidityMax: CGFloat,
                                       humidityMin: CGFloat,
                                       completeBlock: (() -> Void)?) {
        guard !temperatureList.isEmpty, !humidityList.isEmpty else {
            completeBlock?()
            return
        }
        totalLabel.text = "Total Data Points: " + "\(temperatureList.count)"
        var displayText = "\(temperatureList.count)"
        if temperatureList.count > 1000 {
            displayText = "1000"
        }
        displayLabel.text = "Window Display Points: " + displayText

        tempView.drawCurveWithParamModel(tempModel,
                                         pointList: temperatureList,
                                         maxValue: temperatureMax,
                                         minValue: temperatureMin)
        humidityView.drawCurveWithParamModel(humidityModel,
                                             pointList: humidityList,
                                             maxValue: humidityMax,
                                             minValue: humidityMin)
        completeBlock?()
    }
}
