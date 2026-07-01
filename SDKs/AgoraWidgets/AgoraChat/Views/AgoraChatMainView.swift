//
//  AgoraChatMainView.swift
//  AgoraWidgets
//
//  Created by LYY on 2022/7/17.
//

import AgoraUIBaseViews

import UIKit

protocol AgoraChatMainViewDelegate: NSObjectProtocol {
    func onSendImageData(_ data: Data)
    func onSendTextMessage(_ message: String)
    func onClickAllMuted(_ isAllMuted: Bool)
    func onSetAnnouncement(_ announcement: String?)
    func onShowErrorMessage(_ errorMessage: String)
}

class AgoraChatMainView: UIView {
    /**views**/
    private lazy var topBar = AgoraChatTopBar()
    
    private lazy var messageView = AgoraChatMessageView(frame: .zero)
    private lazy var announcementView = AgoraChatAnnouncementView(frame: .zero)
    
    private(set) lazy var bottomBar = AgoraChatBottomBar()
    
    /**data**/
    private var currentContentType: AgoraChatContentType = .messages {
        didSet {
            guard currentContentType != oldValue else {
                return
            }
            updateContentType()
        }
    }
    
    var editAnnouncementEnabled: Bool = false {
        didSet {
            announcementView.editAnnouncementEnabled = editAnnouncementEnabled
        }
    }
    
    weak var delegate: AgoraChatMainViewDelegate?
    
    private override init(frame: CGRect) {
        super.init(frame: frame)
        
        initViews()
        initViewFrame()
        updateViewProperties()
    }
    
    func updateViewItems(_ items: [AgoraChatMainViewItem]) {
        let topBarVisible = items.contains(.topBar)
        let announcementVisible = (items.contains(.announcement))
        let inputVisible = items.contains(.input)
        
        let muteAllVisible = items.contains(.muteAll)
        let emojiVisible = items.contains(.emoji)
        let imageVisible = items.contains(.image)
        
        topBar.agora_visible = topBarVisible
        topBar.updateAnnouncementVisible(announcementVisible)
        bottomBar.agora_visible = inputVisible
        
        guard inputVisible else {
            return
        }

        var bottomBarFunctions = [AgoraChatBottomBarFunction.input]

        if muteAllVisible {
            bottomBarFunctions.append(.mute)
        }
        if emojiVisible {
            bottomBarFunctions.append(.emoji)
        }
        if imageVisible {
            bottomBarFunctions.append(.picture)
        }
        bottomBar.functions = bottomBarFunctions
    }
    
    func updateBottomBarMuteState(islocalMuted: Bool,
                                  isAllMuted:Bool,
                                  localMuteAuth: Bool) {
        guard !localMuteAuth else {
            bottomBar.muteButton.isSelected = isAllMuted
            return
        }
        let config = UIConfig.agoraChat
        guard !isAllMuted else {
            bottomBar.updateInputText(config.muteAll.fieldText)
            bottomBar.isUserInteractionEnabled = false
            return
        }
        
        guard !islocalMuted else {
            bottomBar.updateInputText(config.mute.fieldtext)
            bottomBar.isUserInteractionEnabled = false
            return
        }
        
        bottomBar.updateInputText(config.message.placeholderText)
        bottomBar.isUserInteractionEnabled = true
    }
    
    func setupHistoryMessages(list: [AgoraChatMessageViewType]) {
        guard list.count > 0 else {
            return
        }
        var originDataSource = messageView.messageDataSource
        messageView.messageDataSource = list + originDataSource
    }
    
    func appendMessages(_ list: [AgoraChatMessageViewType]) {
        var originDataSource = messageView.messageDataSource
        messageView.messageDataSource = originDataSource + list
        
        if currentContentType == .announcement {
            topBar.showRedDot(.messages)
        }
    }
    
    func setAnnouncement(_ announcement: String?,
                         showRemind: Bool = true) {
        messageView.announcementText = announcement
        announcementView.announcementText = announcement
        
        guard showRemind,
              let _ = announcement,
              currentContentType == .messages else {
            return
        }
        topBar.showRedDot(.announcement)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>,
                               with event: UIEvent?) {
        super.touchesBegan(touches,
                           with: event)
        UIWindow.agora_top_window()?.endEditing(true)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

extension AgoraChatMainView: AgoraUIContentContainer {
    func initViews() {
        let config = UIConfig.agoraChat
        addSubview(topBar)
        
        addSubview(messageView)
        messageView.annoucementButton.addTarget(self,
                                                action: #selector(onClickAnnouncement(_:)),
                                                for: .touchUpInside)
        addSubview(announcementView)
        
        bottomBar.updateInputText(config.message.placeholderText)
        addSubview(bottomBar)
        
        topBar.delegate = self
        announcementView.delegate = self
        bottomBar.delegate = self
        
        messageView.agora_enable = config.message.enable
        messageView.agora_visible = true
        
        announcementView.agora_enable = config.announcement.enable
        announcementView.agora_visible = false
    }
    
    func initViewFrame() {
        topBar.agora_mas_makeConstraints { make in
            make?.left.top().right().equalTo()(0)
            make?.height.equalTo()(34)
        }
        bottomBar.agora_mas_makeConstraints { make in
            make?.left.right().bottom().equalTo()(0)
            make?.height.equalTo()(40)
        }
        announcementView.agora_mas_remakeConstraints { make in
            make?.left.right().equalTo()(0)
            make?.top.equalTo()(topBar.agora_mas_bottom)?.offset()(0)
            make?.bottom.equalTo()(0)
        }
        messageView.agora_mas_makeConstraints { make in
            make?.left.right().equalTo()(0)
            make?.top.equalTo()(topBar.agora_mas_bottom)?.offset()(0)
            make?.bottom.equalTo()(bottomBar.agora_mas_top)?.offset()(0)
        }
    }
    
    func updateViewProperties() {
        let config = UIConfig.agoraChat
        backgroundColor = config.backgroundColor
        layer.cornerRadius = config.cornerRadius
    }
}

// MARK: - view delegate
extension AgoraChatMainView: AgoraChatTopBarDelegate,
                             AgoraChatBottomBarDelegate,
                             AgoraChatAnnouncementViewDelegate,
                             UIImagePickerControllerDelegate,
                             UINavigationControllerDelegate {
    // MARK: AgoraChatTopBarDelegate
    func didSelectMessage() {
        currentContentType = .messages
        bottomBar.agora_visible = true
        topBar.hideRedDot()
    }
    
    func didSelectAnnouncement() {
        currentContentType = .announcement
        bottomBar.agora_visible = false
        topBar.hideRedDot()
    }
    
    func didTouchAnnouncement() {
        currentContentType = .announcement
        bottomBar.agora_visible = false
        topBar.hideRedDot()
    }
    
    // MARK: AgoraChatAnnouncementViewDelegate
    func onSetAnnouncement(_ announcement: String?) {
        messageView.announcementText = announcement
        delegate?.onSetAnnouncement(announcement)
    }
    
    // MARK: AgoraChatBottomBarDelegate
    func onClickAllMuted(_ isAllMuted: Bool) {
        delegate?.onClickAllMuted(isAllMuted)
    }
    
    func onPhotoNoAuth() {
        let config = UIConfig.agoraChat.picture
        delegate?.onShowErrorMessage(config.noAuthText)
    }
    
    func onSendChatText(message: String) {
        delegate?.onSendTextMessage(message)
    }
    
    func onSelectImage(_ image: UIImage?) {
        guard let `image` = image,
              let data = image.compressedData() else {
            return
        }
        delegate?.onSendImageData(data)
    }
}

// MARK: - private
private extension AgoraChatMainView {
    func updateContentType() {
        switch currentContentType {
        case .messages:
            topBar.foucusOnMessageTab(.messages)
            messageView.agora_visible = true
            announcementView.agora_visible = false
            bottomBar.agora_visible = true
        case .announcement:
            topBar.foucusOnMessageTab(.announcement)
            messageView.agora_visible = false
            announcementView.agora_visible = true
            bottomBar.agora_visible = false
        }
    }
    
    @objc func onClickAnnouncement(_ sender: UIButton) {
        currentContentType = .announcement
        topBar.hideRedDot()
    }
}
