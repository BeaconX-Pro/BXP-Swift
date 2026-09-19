//
//  MKBXPTHCurveView.swift
//  MKBeaconXPlusSwiftProject
//
//  Created by aa on 2026/9/18.
//

import UIKit
import SnapKit
import MKBaseSwiftModule

// MARK: - View Model

public final class MKBXPTHCurveViewModel: NSObject {
    /// 曲线颜色，默认蓝色
    public var lineColor: UIColor = .blue
    /// 曲线线宽，默认 1.f
    public var lineWidth: CGFloat = 1
    /// 曲线背景颜色，默认 RGBCOLOR(224, 245, 254)
    public var curveViewBackgroundColor: UIColor = UIColor(red: 224/255.0, green: 245/255.0, blue: 254/255.0, alpha: 1)
    /// 右侧曲线标题
    public var curveTitle: String = ""
    /// 标题颜色，默认 #353535
    public var titleColor: UIColor = MKColor.defaultText
    /// 标题字体大小，默认 12.f
    public var titleFont: UIFont = MKFont.font(12)
    /// 竖轴的颜色，默认 #353535
    public var yPostionColor: UIColor = MKColor.defaultText
    /// 竖轴线宽，默认 0.5
    public var yPostionWidth: CGFloat = 0.5
    /// 左侧竖轴显示的标签字体颜色，默认 #353535
    public var labelColor: UIColor = MKColor.defaultText
    /// 左侧竖轴显示的标签字体大小，默认 10.f
    public var labelFont: UIFont = MKFont.font(10)

    public override init() {
        super.init()
    }
}

// MARK: - 内部曲线绘制 View

private final class MKBXPCurveView: UIView {

    private lazy var pointList: [CGFloat] = []

    var lineColor: UIColor = .blue
    var lineWidth: CGFloat = 1

    override func draw(_ rect: CGRect) {
        super.draw(rect)
        drawCurve()
    }

    func updatePointValues(_ pointList: [String],
                           maxValue: CGFloat,
                           minValue: CGFloat) {
        guard !pointList.isEmpty else { return }
        self.pointList.removeAll()
        let totalValue = maxValue - minValue
        if totalValue == 0 {
            for _ in 0..<pointList.count {
                self.pointList.append(frame.size.height - 13)
            }
        } else {
            for value in pointList {
                let tempValue = (frame.size.height - 13) * (maxValue - (CGFloat(Float(value) ?? 0))) / totalValue
                self.pointList.append(tempValue)
            }
        }
        setNeedsDisplay()
    }

    private func drawCurve() {
        guard !pointList.isEmpty else { return }
        guard let context = UIGraphicsGetCurrentContext() else { return }
        context.setLineWidth(lineWidth > 0 ? lineWidth : 1)
        context.setStrokeColor(lineColor.cgColor)
        context.move(to: CGPoint(x: 0, y: pointList[0]))
        let width = frame.size.width / CGFloat(pointList.count)
        for i in 1..<pointList.count {
            context.addLine(to: CGPoint(x: CGFloat(i) * width, y: pointList[i]))
        }
        context.strokePath()
    }
}

// MARK: - MKBXPTHCurveView

public final class MKBXPTHCurveView: UIView {

    private static let valueLabelWidth: CGFloat = 35
    private static let maxPointCount: Int = 1000

    // MARK: - Subviews

    private lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.font = MKFont.font(12)
        label.textAlignment = .center
        label.transform = CGAffineTransform(rotationAngle: -.pi / 2)
        return label
    }()

    private lazy var horizontalLine: UIView = {
        let view = UIView()
        view.backgroundColor = MKColor.defaultText
        return view
    }()

    private lazy var maxLabel: UILabel = makeLabel()
    private lazy var maxLine: UIView = makeLine()
    private lazy var minLabel: UILabel = makeLabel()
    private lazy var minLine: UIView = makeLine()
    private lazy var aveLabel: UILabel = makeLabel()
    private lazy var aveLine: UIView = makeLine()
    private lazy var valueMaxLabel: UILabel = makeLabel()
    private lazy var valueMaxLine: UIView = makeLine()
    private lazy var valueMinLabel: UILabel = makeLabel()
    private lazy var valueMinLine: UIView = makeLine()

    private lazy var curveView: MKBXPCurveView = {
        let view = MKBXPCurveView()
        return view
    }()

    private lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.delegate = self
        sv.showsVerticalScrollIndicator = false
        sv.showsHorizontalScrollIndicator = false
        return sv
    }()

    // MARK: - Init

    public override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(titleLabel)
        addSubview(horizontalLine)
        addSubview(maxLabel)
        addSubview(maxLine)
        addSubview(valueMaxLabel)
        addSubview(valueMaxLine)
        addSubview(valueMinLabel)
        addSubview(valueMinLine)
        addSubview(minLabel)
        addSubview(minLine)
        addSubview(aveLabel)
        addSubview(aveLine)
        addSubview(scrollView)
        scrollView.addSubview(curveView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    public override func layoutSubviews() {
        super.layoutSubviews()

        let labelSpace = (frame.size.height - 10 - 5 * MKFont.font(10).lineHeight) / 4
        let curveViewWidth = frame.size.width - 60
        let curveViewHeight = frame.size.height - 10 - 2 * MKFont.font(10).lineHeight - 2 * labelSpace

        titleLabel.snp.remakeConstraints { make in
            make.left.equalTo(-40)
            make.width.equalTo(120)
            make.centerY.equalTo(self)
            make.height.equalTo(20)
        }
        maxLabel.snp.remakeConstraints { make in
            make.left.equalTo(30)
            make.width.equalTo(Self.valueLabelWidth)
            make.top.equalTo(5)
            make.height.equalTo(MKFont.font(10).lineHeight)
        }
        valueMaxLabel.snp.remakeConstraints { make in
            make.left.right.equalTo(maxLabel)
            make.top.equalTo(maxLabel.snp.bottom).offset(labelSpace)
            make.height.equalTo(maxLabel)
        }
        aveLabel.snp.remakeConstraints { make in
            make.left.right.equalTo(maxLabel)
            make.top.equalTo(valueMaxLabel.snp.bottom).offset(labelSpace)
            make.height.equalTo(maxLabel)
        }
        valueMinLabel.snp.remakeConstraints { make in
            make.left.right.equalTo(maxLabel)
            make.top.equalTo(aveLabel.snp.bottom).offset(labelSpace)
            make.height.equalTo(maxLabel)
        }
        minLabel.snp.remakeConstraints { make in
            make.left.right.equalTo(maxLabel)
            make.bottom.equalTo(-5)
            make.height.equalTo(maxLabel)
        }
        horizontalLine.snp.remakeConstraints { make in
            make.left.equalTo(maxLabel.snp.right).offset(3)
            make.width.equalTo(0.5)
            make.top.equalTo(5)
            make.bottom.equalTo(-5)
        }
        maxLine.snp.remakeConstraints { make in
            make.left.equalTo(horizontalLine.snp.right)
            make.width.equalTo(3)
            make.centerY.equalTo(maxLabel)
            make.height.equalTo(0.5)
        }
        minLine.snp.remakeConstraints { make in
            make.left.equalTo(horizontalLine.snp.right)
            make.width.equalTo(3)
            make.centerY.equalTo(minLabel)
            make.height.equalTo(0.5)
        }
        aveLine.snp.remakeConstraints { make in
            make.left.equalTo(horizontalLine.snp.right)
            make.width.equalTo(3)
            make.centerY.equalTo(aveLabel)
            make.height.equalTo(0.5)
        }
        valueMaxLine.snp.remakeConstraints { make in
            make.left.equalTo(horizontalLine.snp.right)
            make.width.equalTo(3)
            make.centerY.equalTo(valueMaxLabel)
            make.height.equalTo(0.5)
        }
        valueMinLine.snp.remakeConstraints { make in
            make.left.equalTo(horizontalLine.snp.right)
            make.width.equalTo(3)
            make.centerY.equalTo(valueMinLabel)
            make.height.equalTo(0.5)
        }
        scrollView.snp.remakeConstraints { make in
            make.left.equalTo(horizontalLine.snp.right)
            make.right.equalTo(-5)
            make.top.equalTo(valueMaxLabel.snp.centerY)
            make.bottom.equalTo(valueMinLabel.snp.centerY)
        }
        curveView.frame = CGRect(x: 0, y: 0, width: curveViewWidth, height: curveViewHeight)
    }

    // MARK: - Public

    public func drawCurveWithParamModel(_ dataModel: MKBXPTHCurveViewModel,
                                        pointList: [String],
                                        maxValue: CGFloat,
                                        minValue: CGFloat) {
        guard !pointList.isEmpty else { return }
        configParamsWithModel(dataModel)

        let labelSpace = (frame.size.height - 10 - 5 * MKFont.font(10).lineHeight) / 4
        let curveViewWidth = frame.size.width - 60
        let curveViewHeight = frame.size.height - 10 - 2 * MKFont.font(10).lineHeight - 2 * labelSpace

        horizontalLine.snp.remakeConstraints { make in
            make.left.equalTo(maxLabel.snp.right).offset(3)
            make.width.equalTo(dataModel.yPostionWidth > 0 ? dataModel.yPostionWidth : 0.5)
            make.top.equalTo(5)
            make.bottom.equalTo(-5)
        }

        let tempValue = (maxValue - minValue) / 2
        valueMaxLabel.text = String(format: "%.1f", maxValue)
        valueMinLabel.text = String(format: "%.1f", minValue)
        maxLabel.text = String(format: "%.1f", maxValue + tempValue)
        minLabel.text = String(format: "%.1f", minValue - tempValue)
        aveLabel.text = String(format: "%.1f", minValue + tempValue)

        var tempViewWidth = curveViewWidth
        if pointList.count > Self.maxPointCount {
            let space = curveViewWidth / CGFloat(Self.maxPointCount)
            tempViewWidth = CGFloat(pointList.count / Self.maxPointCount) * curveViewWidth
                + CGFloat(pointList.count % Self.maxPointCount) * space
        }
        curveView.frame = CGRect(x: 0, y: 0, width: tempViewWidth, height: curveViewHeight)
        curveView.updatePointValues(pointList, maxValue: maxValue, minValue: minValue)

        if pointList.count <= Self.maxPointCount {
            scrollView.contentSize = .zero
        } else {
            scrollView.contentSize = CGSize(width: tempViewWidth, height: 0)
        }
    }

    public func drawCurveWithPointList(_ pointList: [String],
                                       maxValue: CGFloat,
                                       minValue: CGFloat) {
        let dataModel = MKBXPTHCurveViewModel()
        drawCurveWithParamModel(dataModel,
                                pointList: pointList,
                                maxValue: maxValue,
                                minValue: minValue)
    }

    // MARK: - Private

    private func configParamsWithModel(_ paramModel: MKBXPTHCurveViewModel) {
        backgroundColor = paramModel.curveViewBackgroundColor
        curveView.lineColor = paramModel.lineColor
        curveView.lineWidth = paramModel.lineWidth > 0 ? paramModel.lineWidth : 1
        curveView.backgroundColor = paramModel.curveViewBackgroundColor
        titleLabel.textColor = paramModel.titleColor
        titleLabel.font = paramModel.titleFont
        titleLabel.text = paramModel.curveTitle
        horizontalLine.backgroundColor = paramModel.yPostionColor

        for label in [maxLabel, valueMaxLabel, aveLabel, valueMinLabel, minLabel] {
            label.textColor = paramModel.labelColor
            label.font = paramModel.labelFont
        }
    }

    private func makeLabel() -> UILabel {
        let label = UILabel()
        label.textColor = MKColor.defaultText
        label.textAlignment = .right
        label.font = MKFont.font(10)
        return label
    }

    private func makeLine() -> UIView {
        let view = UIView()
        view.backgroundColor = UIColor(red: 136/255.0, green: 136/255.0, blue: 136/255.0, alpha: 1)
        return view
    }
}

// MARK: - UIScrollViewDelegate

extension MKBXPTHCurveView: UIScrollViewDelegate {
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        NSLog("当前滚动范围: \(scrollView.contentOffset.x)")
        if scrollView.contentOffset.x <= 0 {
            var offset = scrollView.contentOffset
            offset.x = 0
            scrollView.contentOffset = offset
        }
    }
}
