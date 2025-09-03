//
//  AgoraChatTopView.swift
//  AgoraWidgets
//
//  Created by LYY on 2022/7/17.
//

import AgoraUIBaseViews

protocol AgoraChatTopBarDelegate: NSObjectProtocol {
    func didSelectMessage()
    func didSelectAnnouncement()
}

class AgoraChatTopBar: UIView {
    weak var delegate: AgoraChatTopBarDelegate?
    
    private let buttonLength: CGFloat = 50
    
    private lazy var messageButton = UIButton()
    private lazy var announcementButton = UIButton()
    private lazy var selectedLine = UIView()
    private lazy var redDot = UIView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initViews()
        initViewFrame()
        updateViewProperties()
    }
    
    func foucusOnMessageTab(_ type: AgoraChatContentType) {
        switch type {
        case .messages:
            selectedLine.agora_mas_remakeConstraints { make in
                make?.width.equalTo()(buttonLength)
                make?.height.equalTo()(2)
                make?.bottom.equalTo()(0)
                make?.centerX.equalTo()(messageButton.agora_mas_centerX)
            }
        case .announcement:
            selectedLine.agora_mas_remakeConstraints { make in
                make?.width.equalTo()(buttonLength)
                make?.height.equalTo()(2)
                make?.bottom.equalTo()(0)
                make?.centerX.equalTo()(announcementButton.agora_mas_centerX)
            }
        }
    }
    
    func showRedDot(_ type: AgoraChatContentType) {
        redDot.agora_visible = true
        switch type {
        case .messages:
            redDot.agora_mas_remakeConstraints { make in
                make?.width.height().equalTo()(4)
                make?.top.equalTo()(5)
                make?.right.equalTo()(messageButton.agora_mas_right)?.offset()(-5)
            }
        case .announcement:
            redDot.agora_mas_remakeConstraints { make in
                make?.width.height().equalTo()(4)
                make?.top.equalTo()(5)
                make?.right.equalTo()(announcementButton.agora_mas_right)?.offset()(-5)
            }
        }
    }
    
    func hideRedDot() {
        redDot.agora_visible = false
    }
    
    func updateAnnouncementVisible(_ visible: Bool) {
        announcementButton.agora_visible = visible
        selectedLine.agora_visible = visible
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AgoraChatTopBar: AgoraUIContentContainer {
    func initViews() {
        messageButton.setTitleForAllStates("fcr_hyphenate_im_chat".widgets_localized())
        messageButton.addTarget(self,
                                action: #selector(onClickMessage),
                                for: .touchUpInside)
        announcementButton.setTitleForAllStates("fcr_hyphenate_im_announcement".widgets_localized())
        announcementButton.addTarget(self,
                                action: #selector(onClickAnnouncement),
                                for: .touchUpInside)
        redDot.agora_visible = false
        redDot.isUserInteractionEnabled = false
        
        redDot.layer.cornerRadius = 2
        redDot.clipsToBounds = true
        
        addSubview(messageButton)
        addSubview(announcementButton)
        addSubview(selectedLine)
        addSubview(redDot)
    }
    
    func initViewFrame() {
        messageButton.agora_mas_makeConstraints { make in
            make?.top.bottom().equalTo()(0)
            make?.left.equalTo()(0)
            make?.width.equalTo()(buttonLength)
        }
        
        announcementButton.agora_mas_makeConstraints { make in
            make?.top.bottom().equalTo()(0)
            make?.left.equalTo()(messageButton.agora_mas_right)
            make?.width.equalTo()(buttonLength)
        }
        
        selectedLine.agora_mas_makeConstraints { make in
            make?.width.equalTo()(buttonLength)
            make?.height.equalTo()(2)
            make?.bottom.equalTo()(0)
            make?.left.equalTo()(messageButton.agora_mas_left)
        }
        
        redDot.agora_mas_makeConstraints { make in
            make?.width.height().equalTo()(4)
            make?.top.equalTo()(5)
            make?.right.equalTo()(messageButton.agora_mas_right)?.offset()(-5)
        }
    }
    
    func updateViewProperties() {
        let config = UIConfig.agoraChat.topBar
        messageButton.setTitleColor(config.titleColor,
                                    for: .normal)
        messageButton.titleLabel?.font = config.titleFont
        announcementButton.setTitleColor(config.titleColor,
                                         for: .normal)
        announcementButton.titleLabel?.font = config.titleFont
        selectedLine.backgroundColor = config.selectedColor
        redDot.backgroundColor = config.remindColor
    }
}

private extension AgoraChatTopBar {
    @objc func onClickMessage() {
        delegate?.didSelectMessage()
    }
    
    @objc func onClickAnnouncement() {
        delegate?.didSelectAnnouncement()
    }
}
