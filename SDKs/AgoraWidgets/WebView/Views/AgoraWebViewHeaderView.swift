//
//  AgoraWebViewContentTabView.swift
//  AgoraWidgets
//
//  Created by DoubleCircle on 2022/5/26.
//

import AgoraUIBaseViews
import CoreGraphics

class AgoraWebViewHeaderView: UIView, AgoraUIContentContainer {
    /**Views**/
    private let titleLabel = UILabel()
    private let buttonsStackView = UIStackView(frame: .zero)
    private let line = CALayer()
    
    let refreshButton = UIButton()
    let scaleButton = UIButton()
    let closeButton = UIButton()
    
    private let buttonHorizontalSpace: CGFloat = 12
    private let buttonSize = CGSize(width: 20,
                                    height: 20)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initViews()
        initViewFrame()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        line.frame = CGRect(x: 0,
                            y: bounds.height - 1,
                            width: bounds.width,
                            height: 1)
    }
    
    func initViews() {
        let itemName = UIConfig.webView.name
        
        // TitleLabel
        titleLabel.text = itemName.text
        titleLabel.font = itemName.font
        titleLabel.agora_enable = itemName.enable
        addSubview(titleLabel)
        
        layer.addSublayer(line)
        
        // StackView
        buttonsStackView.backgroundColor = .clear
        buttonsStackView.axis = .horizontal
        buttonsStackView.distribution = .fillEqually
        buttonsStackView.alignment = .center
        buttonsStackView.spacing = buttonHorizontalSpace
        
        addSubview(buttonsStackView)
        
        // RefreshButton
        let itemRefresh = UIConfig.webView.refresh
        refreshButton.agora_enable = itemRefresh.enable
        refreshButton.agora_visible = itemRefresh.visible
        refreshButton.setImage(itemRefresh.image,
                               for: .normal)
        
        if refreshButton.agora_enable {
            buttonsStackView.addArrangedSubview(refreshButton)
        }
        
        // ScaleButton
        let itemScale = UIConfig.webView.scale
        scaleButton.agora_enable = itemScale.enable
        scaleButton.agora_visible = itemScale.visible
        scaleButton.setImage(itemScale.image,
                             for: .normal)
        
        if scaleButton.agora_enable {
            buttonsStackView.addArrangedSubview(scaleButton)
        }
        
        // CloseButton
        let itemClose = UIConfig.webView.close
        closeButton.agora_enable = itemClose.enable
        closeButton.agora_visible = itemClose.visible
        closeButton.setImage(itemClose.image,
                             for: .normal)
        
        if closeButton.agora_enable {
            buttonsStackView.addArrangedSubview(closeButton)
        }
    }
    
    func initViewFrame() {
        let stackWidth = stackWidth(count: 1)
        
        buttonsStackView.agora_mas_makeConstraints { make in
            make?.top.equalTo()(0)
            make?.bottom.equalTo()(0)
            make?.right.equalTo()(-15)
            make?.width.equalTo()(stackWidth)
        }
        
        titleLabel.agora_mas_makeConstraints { make in
            make?.top.equalTo()(0)
            make?.bottom.equalTo()(0)
            make?.left.equalTo()(15)
            make?.right.equalTo()(buttonsStackView.agora_mas_right)
        }
    }
    
    func updateViewProperties() {
        let config = UIConfig.webView
        
        backgroundColor = config.headerBackgroundColor
        titleLabel.textColor = config.name.textColor
        line.backgroundColor = config.sepLine.backgroundColor.cgColor
    }
    
    func setOperationPrivilege(_ hasPrivilege: Bool) {
        scaleButton.agora_visible = hasPrivilege
        closeButton.agora_visible = hasPrivilege
        
        let stackWidth = stackWidth(count: hasPrivilege ? 3 : 1)

        buttonsStackView.agora_mas_updateConstraints { make in
            make?.width.equalTo()(stackWidth)
        }
    }
    
    private func stackWidth(count: Int) -> CGFloat {
        let width: CGFloat = buttonSize.width * CGFloat(count) + buttonHorizontalSpace * CGFloat(count - 1)
        return width
    }
}
