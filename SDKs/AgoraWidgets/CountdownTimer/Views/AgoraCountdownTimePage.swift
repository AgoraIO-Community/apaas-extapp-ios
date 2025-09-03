//
//  SingleTimeGroup.swift
//  AgoraWidgets
//
//  Created by LYY on 2021/5/11.
//  Copyright © 2021 Agora. All rights reserved.
//

import AgoraUIBaseViews
import Foundation

public class AgoraCountdownSingleTimeView: UIView, AgoraUIContentContainer {
    private lazy var bgImageView = UIImageView()
    
    private(set) lazy var label = UILabel()
    
    public func turnColor(color: UIColor) {
        self.label.textColor = color
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
   
        initViews()
        initViewFrame()
        updateViewProperties()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func initViews() {
        label.backgroundColor = .clear
        label.text = "0"
        addSubview(bgImageView)
        addSubview(label)
    }
    
    public func initViewFrame() {
        bgImageView.agora_mas_makeConstraints { make in
            make?.left.right().top().bottom().equalTo()(0)
        }
        
        label.agora_mas_makeConstraints { make in
            make?.left.right().top().bottom().equalTo()(0)
        }
    }
    
    public func updateViewProperties() {
        let config = UIConfig.counter.time
        
        bgImageView.image = config.image
        label.textAlignment = config.textAlignment
        label.textColor = config.normalTextColor
        label.font = config.font
    }
}

@objcMembers class AgoraCountdownSingleTimeGroup: UIView {
    private lazy var topView: AgoraCountdownSingleTimeView = AgoraCountdownSingleTimeView(frame: .zero)
    private lazy var bottomView: AgoraCountdownSingleTimeView = AgoraCountdownSingleTimeView(frame: .zero)
    private lazy var upPageView: AgoraCountdownSingleTimeView = AgoraCountdownSingleTimeView(frame: .zero)
    private lazy var downPageView: AgoraCountdownSingleTimeView = AgoraCountdownSingleTimeView(frame: .zero)
    
    private lazy var lineLayer = CALayer()
    
    private var timeStr: String = "" {
        didSet {
            guard oldValue != timeStr else {
                return
            }
            self.startAnimation()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initViews()
        initViewFrame()
        updateViewProperties()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        topView.frame = self.bounds
        bottomView.frame = self.bounds
        upPageView.frame = self.bounds
        downPageView.frame = self.bounds
        
        lineLayer.frame = CGRect(center: self.center,
                                 size: CGSize(width: self.width,
                                              height: 1))
        
        maskTopView()
        maskBottomView()
    }
}

// MARK: - Public
extension AgoraCountdownSingleTimeGroup {
    func updateStr(str: String) {
        DispatchQueue.main.async {
            self.timeStr = str
        }
    }
    
    func turnColor(color: UIColor) {
        DispatchQueue.main.async {
            for timeView in [self.topView,
                             self.bottomView,
                             self.upPageView,
                             self.downPageView] {
                timeView.turnColor(color: color)
            }
        }
    }
}

// MARK: - AgoraUIContentContainer
extension AgoraCountdownSingleTimeGroup: AgoraUIContentContainer {
    func initViews() {
        upPageView.layer.transform = CATransform3DMakeRotation(CGFloat(Double.pi * -0.1),
                                                               1,
                                                               0,
                                                               0)
        addSubview(upPageView)
        addSubview(topView)
        addSubview(bottomView)
        downPageView.layer.transform = CATransform3DMakeRotation(CGFloat(Double.pi * -1.5),
                                                                 1,
                                                                 0,
                                                                 0)
        addSubview(downPageView)
        layer.addSublayer(lineLayer)

        self.isUserInteractionEnabled = false
    }
    
    func initViewFrame() {
    }
    
    func updateViewProperties() {
        let config = UIConfig.counter
        lineLayer.backgroundColor = config.sepColor.cgColor
    }
}

// MARK: - Private
private extension AgoraCountdownSingleTimeGroup {
    func maskTopView() {
        let height = self.bounds.height
        let path = UIBezierPath(rect: CGRect(x: 0,
                                             y: 0,
                                             width: self.bounds.width,
                                             height: height * 0.5))
        let shapeLayer = CAShapeLayer()
        shapeLayer.fillRule = .evenOdd
        shapeLayer.path = path.cgPath
        topView.layer.mask = shapeLayer
    }
    func maskBottomView() {
        let height = self.bounds.height
        let path = UIBezierPath(rect: CGRect(x: 0,
                                             y: height * 0.5,
                                             width: self.bounds.width,
                                             height: height * 0.5))
        let shapeLayer = CAShapeLayer()
        shapeLayer.fillRule = .evenOdd
        shapeLayer.path = path.cgPath
        bottomView.layer.mask = shapeLayer
    }
    
    func startAnimation() {
        upPageView.isHidden = false
        topView.label.text = self.timeStr
        downPageView.isHidden = true
        
        UIView.animate(withDuration: TimeInterval.agora_animation,
                       delay: 0,
                       options: .curveLinear) {
            self.upPageView.layer.transform = CATransform3DMakeRotation(CGFloat(Double.pi * -0.5),
                                                                        1,
                                                                        0,
                                                                        0)
        } completion: { isFinish in
            self.upPageView.layer.transform = CATransform3DMakeRotation(CGFloat(Double.pi * -0.1),
                                                                        1,
                                                                        0,
                                                                        0)
            self.upPageView.isHidden = true
            self.continueAnimation()
            self.upPageView.label.text = self.timeStr
        }
    }
    
    func continueAnimation() {
        downPageView.label.text = timeStr
        downPageView.isHidden = false
        
        UIView.animate(withDuration: TimeInterval.agora_animation,
                       delay: 0,
                       options: .curveLinear) {
            self.downPageView.layer.transform = CATransform3DMakeRotation(CGFloat(Double.pi * -1.9),
                                                                          1,
                                                                          0,
                                                                          0)
        } completion: { isFinish in
            self.downPageView.layer.transform = CATransform3DMakeRotation(CGFloat(Double.pi * -1.5),
                                                                          1,
                                                                          0,
                                                                          0)
            self.bottomView.label.text = self.timeStr
        }
    }
}
