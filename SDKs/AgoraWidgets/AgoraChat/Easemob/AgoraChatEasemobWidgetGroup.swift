//
//  AgoraChatEssWidget.swift
//  AgoraWidgets
//
//  Created by LYY on 2022/7/17.
//

import AgoraWidget
import CoreMedia
import AgoraChat

@objcMembers public class AgoraChatEasemobWidgetGroup: AgoraNativeWidget {
    private lazy var mainView = AgoraChatMainView()
        
    private var easemob: AgoraChatEasemobGroup?
    
    private var localMuted: Bool = false {
        didSet {
            guard localMuted != oldValue,
                  !isTeacher else {
                return
            }
            mainView.updateBottomBarMuteState(islocalMuted: localMuted,
                                              isAllMuted: allMuted,
                                              localMuteAuth: isTeacher)
        }
    }
    private var allMuted: Bool = false {
        didSet {
            guard allMuted != oldValue else {
                return
            }
            mainView.updateBottomBarMuteState(islocalMuted: localMuted,
                                              isAllMuted: allMuted,
                                              localMuteAuth: isTeacher)
        }
    }
        
    private var launchCondition: (flag: Bool,
                                  config: AgoraChatEasemobLaunchConfig?,
                                  serverAPI: AgoraChatServerAPI?) = (flag: false,
                                                                     config: nil,
                                                                     serverAPI: nil) {
        didSet {
            guard !launchCondition.flag,
                  let config = launchCondition.config,
                  let serverAPI = launchCondition.serverAPI else {
                return
            }
            fetchEsasemobToken(config: config,
                               serverAPI: serverAPI)
        }
    }
    override init(widgetInfo: AgoraWidgetInfo) {
        super.init(widgetInfo: widgetInfo)
        log(content: "AgoraWidgetGroup init >>>",
            type: .info )
        initData()
    }
    
    public override func onLoad() {
        super.onLoad()
      
        mainView.delegate = self
        mainView.editAnnouncementEnabled = isTeacher
        view.addSubview(mainView)

        mainView.mas_makeConstraints { make in
            make?.left.right().top().bottom().equalTo()(0)
        }
        
        let roomType = AgoraWidgetRoomType(rawValue: Int(info.roomInfo.roomType)) ?? .small
        let roleType = AgoraWidgetRoleType(rawValue: info.localUserInfo.userRole) ?? .student

        var items = AgoraChatMainViewItem.allCases
        
        switch roomType {
        case .oneToOne:
            items.removeAll([.announcement, .muteAll])
        default:
            break
        }
        
        switch roleType {
        case .student:
            items.removeAll([.muteAll])
        case .observer:
            items.removeAll([.muteAll, .input])
        default:
            break
        }
        let extra = ["viewItem": items.agDescription]
        log(content: "update view items",
            extra: extra.agDescription,
            type: .info )
        mainView.updateViewItems(items)
    }
    
    public override func onMessageReceived(_ message: String) {
        super.onMessageReceived(message)
        
        if let keys = message.toRequestKeys() {
            let serverAPI = AgoraChatServerAPI(host: keys.host,
                                               appId: keys.agoraAppId,
                                               token: keys.token,
                                               roomId: info.roomInfo.roomUuid,
                                               userId: info.localUserInfo.userUuid,
                                               logTube: logger)
            launchCondition.serverAPI = serverAPI
        }
    }
    
    public override func onWidgetRoomPropertiesUpdated(_ properties: [String : Any],
                                                       cause: [String : Any]?,
                                                       keyPaths: [String],
                                                       operatorUser: AgoraWidgetUserInfo?) {
        super.onWidgetRoomPropertiesUpdated(properties,
                                            cause: cause,
                                            keyPaths: keyPaths,
                                            operatorUser: operatorUser)
        
        initData()
    }
    
    public override func onWidgetUserPropertiesUpdated(_ properties: [String : Any], cause: [String : Any]?, keyPaths: [String], operatorUser: AgoraWidgetUserInfo?) {
        super.onWidgetUserPropertiesUpdated(properties, cause: cause, keyPaths: keyPaths, operatorUser: operatorUser)
    }
    
    deinit {
        easemob?.logout()
    }
}


// MARK: - view delegate
extension AgoraChatEasemobWidgetGroup: AgoraChatMainViewDelegate {
    func onSendImageData(_ data: Data) {
        easemob?.sendImageMessageData(data)
    }
    
    func onSendTextMessage(_ message: String) {
        easemob?.sendTextMessage(message)
    }
    
    func onClickAllMuted(_ isAllMuted: Bool) {
        guard isTeacher else {
            return
        }
        easemob?.muteAll(mute: isAllMuted)
    }
    
    func onSetAnnouncement(_ announcement: String?) {
        easemob?.setAnnouncement(announcement)
    }
    
    func onShowErrorMessage(_ errorMessage: String) {
        sendSignal(.error(errorMessage))
    }
}

// MARK: - private
private extension AgoraChatEasemobWidgetGroup {
    func initData() {
        guard launchCondition.config == nil,
              let extra = info.roomProperties?.toObject(AgoraChatEasemobRoomProperties.self),
              let userId = info.localUserProperties?["userId"] as? String else {
            return
        }
        // 1. init easemob
        var enableConsoleLog = false
#if DEBUG
        enableConsoleLog = true
#endif
        
        var avatarUrl: String?
        if let extraDic = info.extraInfo as? [String: Any],
         let url = extraDic["avatarUrl"] as? String {
            avatarUrl = url
        }
        var userName = info.localUserInfo.userUuid
        
        if let userId = info.localUserProperties?["userId"] as? String {
            userName = userId
        }
        let chatGroupUuids = info.localUserProperties?["chatGroupUuids"] as? Array<String>
        let sendRoomIds = info.localUserProperties?["sendChatRoomIds"] as? Array<String>
        let recvRoomIds = info.localUserProperties?["receiveChatRoomIds"] as? Array<String>
        let userConfig = AgoraChatEasemobUserConfig(userName: userName,
                                                    nickName: info.localUserInfo.userName,
                                                    avatarurl: avatarUrl,
                                                    fcrRoomId: info.roomInfo.roomUuid,
                                                    role: info.localUserInfo.userRole.userRoleToInt(),
                                                    sendRoomIds: sendRoomIds,
                                                    recvRoomIds: recvRoomIds,
                                                    chatGroupUuids: chatGroupUuids)
        easemob = AgoraChatEasemobGroup(appKey: extra.appKey,
                                   chatRoomId: extra.chatRoomId,
                                   userConfig: userConfig,
                                   enableConsoleLog: enableConsoleLog,
                                   delegate: self)
        
        let launchConfig = AgoraChatEasemobLaunchConfig(roomId: info.roomInfo.roomUuid,
                                                        userId: userId,
                                                        userName: info.localUserInfo.userName,
                                                        chatRoomId: extra.chatRoomId,
                                                        password: userId)
        launchCondition.config = launchConfig
    }
    
    func launchEsasemob(token: String) {
        // 3. join easemob
        let failureBlock: EasemobFailureCompletion = { [weak self] type in
            self?.handleError(type: type)
        }
        
        let joinSuccessBlock: (() -> Void) = { [weak self] in
           guard let `self` = self else {
               return
           }
           self.initEasemobState()
        }
        
        let loginSuccessBlock: EasemobSuccessCompletion = { [weak easemob] in
            guard let `easemob` = easemob else {
                return
            }
            easemob.join(success: joinSuccessBlock, failure: failureBlock)
        }
        
        // 2. login easemob
        self.easemob?.login(token: token,
                            success: loginSuccessBlock,
                            failure: failureBlock)

    }
    
    func fetchEsasemobToken(config: AgoraChatEasemobLaunchConfig,
                            serverAPI: AgoraChatServerAPI) {
        launchCondition.flag = true

        serverAPI.fetchEasemobIMToken(success: { [weak self] (bodyDic) in
            guard let `self` = self,
            let dataDic = bodyDic["data"] as? [String : Any],
            let hxToken = dataDic["token"] as? String else {
                return
            }
            self.launchEsasemob(token: hxToken)
        }, failure: { [weak self] error in
            self?.handleError(type: .loginFailed)
        })
    }
    
    func initEasemobState() {
        guard let `easemob` = easemob else {
            return
        }
        let failureHandle: ((AgoraChatErrorType) -> Void) = { [weak self] type in
            self?.handleError(type: type)
        }
        
        easemob.getAllMutedState(success: { [weak self] muted in
            guard let `self` = self else {
                return
            }
            self.allMuted = muted
        }, failure: failureHandle)
        
        if !isTeacher {
            easemob.getLocalMutedState(success: { [weak self] muted in
                guard let `self` = self else {
                    return
                }
                self.localMuted = muted
            },failure: failureHandle)
        }
        
        easemob.getAnnouncement(success: { [weak self] announcement in
            guard let text = announcement,
            text.count > 0 else {
                self?.mainView.setAnnouncement(nil,
                                               showRemind: false)
                return
            }
            self?.mainView.setAnnouncement(text,
                                           showRemind: false)
        }, failure: failureHandle)
        
        fetchHistoryMessage()
    }
    
    func fetchHistoryMessage() {
        guard let `easemob` = easemob else {
            return
        }
        
        let failureHandle: ((AgoraChatErrorType) -> Void) = { [weak self] type in
            self?.handleError(type: type)
        }
        
        easemob.getHistoryMessages(success: { [weak self] messageList in
            guard let list = messageList,
                  let `self` = self else {
                return
            }
            var modelList = [AgoraChatMessageViewType]()
            let localUserId = easemob.userConfig.userName ?? self.info.localUserInfo.userUuid
            for chatMessage in list {
                guard let model = chatMessage.toViewModel(localUserId: localUserId) else {
                    continue
                }
                modelList.append(model)
            }
            self.mainView.setupHistoryMessages(list: modelList)
        }, failure: failureHandle)
    }

    func handleError(type: AgoraChatErrorType) {
        var errorLocalized: String?
        switch type {
        case .loginFailed:
            errorLocalized = "fcr_hyphenate_im_login_faild".widgets_localized()
        case .joinFailed:
            errorLocalized = "fcr_hyphenate_im_join_faild".widgets_localized()
        case .loginedFromRemote:
            errorLocalized = "fcr_hyphenate_im_login_on_other_device".widgets_localized()
        case .forcedLogOut:
            errorLocalized = "fcr_hyphenate_im_logout_forced".widgets_localized()
        default:
            return
        }
        
        guard let errorString = errorLocalized else {
            return
        }
        self.sendSignal(.error(errorString))
    }
    
    func sendSignal(_ signal: AgoraChatInteractionSignal) {
        guard let message = signal.toMessageString() else {
            return
        }
        sendMessage(message)
    }
}

// MARK: - ChatManagerDelegate
extension AgoraChatEasemobWidgetGroup: AgoraChatEasemobDelegate {
    func didReceiveMessages(list: [AgoraChatMessage]) {
        let localUserId = easemob?.userConfig.userName ?? info.localUserInfo.userUuid
        for message in list {
            guard let viewModel = message.toViewModel(localUserId: localUserId) else {
                continue
            }
            mainView.appendMessages([viewModel])
        }
        
        sendSignal(.messageReceived)
    }
    
    func didSendMessages(list: [AgoraChatMessage]) {
        let localUserId = easemob?.userConfig.userName ?? info.localUserInfo.userUuid
        for message in list {
            guard let viewModel = message.toViewModel(localUserId: localUserId) else {
                continue
            }
            
            mainView.appendMessages([viewModel])
        }
    }
    
    func didLocalMuteStateChanged(_ muted: Bool) {
        guard !isTeacher else {
            return
        }
        localMuted = muted
    }
    
    func didAllMuteStateChanged(_ muted: Bool) {
        allMuted = muted
    }
    
    func didReceiveAnnouncement(_ announcement: String?) {
        guard let text = announcement,
        text.count > 0 else {
            mainView.setAnnouncement(nil)
            return
        }
        sendSignal(.messageReceived)
        mainView.setAnnouncement(text)
    }
    
    func didConnectionStateChaned(_ state: AgoraChatConnectionState) {

    }
    
    func didOccurError(type: AgoraChatErrorType) {
        handleError(type: type)
    }
    
    func onEasemobLog(content: String,
                      extra: String?,
                      type: FcrEasemobLogType) {
        log(content: content,
            extra: extra,
            type: type.agoraType)
    }
}
