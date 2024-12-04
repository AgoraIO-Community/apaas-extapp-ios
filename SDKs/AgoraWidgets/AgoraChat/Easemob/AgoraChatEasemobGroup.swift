//
//  AgoraChatEasemobGroup.swift
//  AgoraWidgets
//
//  Created by DoubleCircle on 2022/7/20.
//

import Foundation
import AgoraChat

class AgoraChatEasemobGroup: NSObject {
    private weak var delegate: AgoraChatEasemobDelegate?
    private(set) var userConfig: AgoraChatEasemobUserConfig
    private var chatRoomId: String
    
    private var latestMessageId = ""
    private var loginRetryCount = 0
    private var joinRetryCountMap: [String: Int] = [:]
    private let maxRetryCount = 10
    private let muteMemberKey = "muteMember"
    
    var recvRoomIds:Array<String> {
        get{
            return self.userConfig.recvRoomIds
        }
    }
    var sendRoomIds:Array<String> {
        get{
            return self.userConfig.sendRoomIds
        }
    }
    
    var joinRoomIds:Array<String> {
        get {
            var roomIds:Array<String> = []
            roomIds.append(self.chatRoomId)
            self.sendRoomIds.forEach { roomId in
                if(!roomIds.contains(roomId)){
                    roomIds.append(roomId)
                }
            }
            self.recvRoomIds.forEach { roomId in
                if(!roomIds.contains(roomId)){
                    roomIds.append(roomId)
                }
            }
            return roomIds
        }
    }
    
    init(appKey: String,
         chatRoomId: String,
         userConfig: AgoraChatEasemobUserConfig,
         enableConsoleLog: Bool,
         delegate: AgoraChatEasemobDelegate?) {
        self.chatRoomId = chatRoomId
        self.userConfig = userConfig
        self.delegate = delegate
        super.init()
        
        let option = AgoraChatOptions(appkey: appKey)
        option.enableConsoleLog = false
        option.isAutoLogin = false
        
        AgoraChatClient.shared().initializeSDK(with: option)
        AgoraChatClient.shared().add(self,
                                     delegateQueue: nil)
        AgoraChatClient.shared().chatManager.add(self,
                                                 delegateQueue: nil)
        AgoraChatClient.shared().roomManager.add(self,
                                                 delegateQueue: nil)
        let extra = ["appKey": appKey,
                     "chatRoomId": chatRoomId,
                     "userId": userConfig.userName,
                     "role": "\(userConfig.role)",
                     "fcrRoomId": userConfig.fcrRoomId]
        delegate?.onEasemobLog(content: "init",
                               extra: extra.agDescription,
                               type: .info)
    }
    
    func login(token: String,
               success: EasemobSuccessCompletion?,
               failure: EasemobFailureCompletion?) {
        let lowercaseName = userConfig.userName.lowercased()
        let extra = ["token": token,
                     "lowercaseName": lowercaseName]
        delegate?.onEasemobLog(content: "start login",
                               extra: extra.agDescription,
                               type: .info)
        _login(token: token,
               lowercaseName: lowercaseName,
               success: success,
               failure: failure)
    }
    
    func join(success: EasemobSuccessCompletion?,
              failure: EasemobFailureCompletion?) {
        
        var joinRoomCount = 0
        
        let joinSuccessBlock: EasemobJoinSuccessCompletion = { [weak self] room in
            guard let `self` = self else {
                return
            }
            joinRoomCount += 1
            if(joinRoomCount == self.joinRoomIds.count){
                success?()
            }
        }
        
        let joinFailureBlock: EasemobJoinFailureCompletion = { [weak self] (roomId, errType) in
            guard let `self` = self else {
                return
            }
            failure?(errType)
        }
        self.joinRoomIds.forEach { roomId in
            let extra = ["chatRoomId": roomId]
            delegate?.onEasemobLog(content: "start join",
                                   extra: extra.agDescription,
                                   type: .info)
            _join(roomId: roomId, success: joinSuccessBlock,
                  failure: joinFailureBlock)
        }
    }
    
    func logout() {
        delegate?.onEasemobLog(content: "logout",
                               extra: nil,
                               type: .info)
        
        AgoraChatClient.shared().roomManager.leaveChatroom(chatRoomId,
                                                           completion: nil)
        AgoraChatClient.shared().removeDelegate(self)
        AgoraChatClient.shared().chatManager.remove(self)
        AgoraChatClient.shared().roomManager.remove(self)
        AgoraChatClient.shared().logout(false)
    }
    
    func sendImageMessageData(_ data: Data?) {
        let imageBody = AgoraChatImageMessageBody(data: data,
                                                  displayName: "image")
        let ext = messageExt()
        let message = AgoraChatMessage(conversationID: chatRoomId,
                                       from: userConfig.userName,
                                       to: chatRoomId,
                                       body: imageBody,
                                       ext: ext)
        
        let success: EasemobSendSuccessCompletion = { msgs in
            // 只需要取第一个发送成功的
            self.delegate?.didSendMessages(list: [msgs[0]])
        }
        let failure: EasemobSendFailureCompletion = { type in
            self.delegate?.didOccurError(type: type)
        }
        batchSendMsg(message: message, success: success, failure: failure)
    }
    
  
    func batchSendMsg(message: AgoraChatMessage, success: EasemobSendSuccessCompletion?, failure: EasemobSendFailureCompletion?) {
        
        var sendResult: [AgoraChatMessage] = []
      
        self.sendRoomIds.forEach { roomId in
            let msg = AgoraChatMessage(conversationID: roomId, from: userConfig.userName, to: roomId, body: message.body, ext: message.ext)
            msg.chatType = .chatRoom
            
            let extra = ["chatRoomId": roomId,
                         "from": userConfig.userName,
                         "to": roomId,
                         "text":message.agDescription]
            delegate?.onEasemobLog(content: "send message",
                                   extra: extra.agDescription,
                                   type: .info)
            
            AgoraChatClient.shared().chatManager.send(msg,
                                                      progress: nil){ [weak self] (chatMessage, chatError) in
                guard let `self` = self else {
                    return
                }
                
                guard let message = chatMessage,
                      chatError == nil else {
                    failure?(.sendFailed(chatError!.code.rawValue))
                    return
                }
                sendResult.append(chatMessage!)
                if(self.sendRoomIds.count == sendResult.count){
                    success?(sendResult)
                }
            }
        }
    }
    
    
    func sendTextMessage(_ text: String) {
        guard text.count > 0 else {
            return
        }
        let textBody = AgoraChatTextMessageBody(text: text)
        let ext = messageExt()
        let message = AgoraChatMessage(conversationID: chatRoomId,
                                       from: userConfig.userName,
                                       to: chatRoomId,
                                       body: textBody,
                                       ext: ext)
        
        let success: EasemobSendSuccessCompletion = { msgs in
            // 只需要取第一个发送成功的
            self.delegate?.didSendMessages(list: [msgs[0]])
        }
        let failure: EasemobSendFailureCompletion = { type in
            self.delegate?.didOccurError(type: type)
        }
        batchSendMsg(message: message, success: success, failure: failure)
    }
    
    func sendCmdMessage(action: String) {
        guard action.count > 0 else {
            return
        }
        let textBody = AgoraChatCmdMessageBody(action: action)
        let ext = messageExt()
        let message = AgoraChatMessage(conversationID: chatRoomId,
                                       from: userConfig.userName,
                                       to: chatRoomId,
                                       body: textBody,
                                       ext: ext)
        
        let success: EasemobSendSuccessCompletion = { msgs in
            // 只需要取第一个发送成功的
            self.delegate?.didReceiveMessages(list: [msgs[0]])
        }
        let failure: EasemobSendFailureCompletion = { type in
            self.delegate?.didOccurError(type: type)
        }
        batchSendMsg(message: message, success: success, failure: failure)
    }
    
    func muteAll(mute: Bool) {
        let extra = ["mute": "\(mute)"]
        delegate?.onEasemobLog(content: "mute all",
                               extra: extra.agDescription,
                               type: .info)
        
        if mute {
            AgoraChatClient.shared().roomManager.muteAllMembers(fromChatroom: chatRoomId) { [weak self] (chatRoom, chatError) in
                guard let `self` = self else {
                    return
                }
                guard chatError == nil else {
                    var extra = ["aError": "\(chatError!.code.rawValue)"]
 
                    self.delegate?.onEasemobLog(content: "mute all fail",
                                                extra: extra.agDescription,
                                                type: .error)
                    self.delegate?.didOccurError(type: .muteFailed(chatError!.code.rawValue))
                    return
                }
                self.sendCmdMessage(action: "setAllMute")
            }
        } else {
            AgoraChatClient.shared().roomManager.unmuteAllMembers(fromChatroom: chatRoomId) { [weak self] (chatRoom, chatError) in
                guard let `self` = self else {
                    return
                }
                guard chatError == nil else {
                    var extra = ["aError": "\(chatError!.code.rawValue)"]
                    
                    self.delegate?.onEasemobLog(content: "unmute all fail",
                                                extra: extra.agDescription,
                                                type: .error)
                    self.delegate?.didOccurError(type: .muteFailed(chatError!.code.rawValue))
                    return
                }
                self.sendCmdMessage(action: "removeAllMute")
            }
        }
    }
    
    func muteUsers(userList: [String],
                  mute: Bool) {
        let extra = ["mute": "\(mute)",
                     "userList": userList.description]
        delegate?.onEasemobLog(content: "mute users",
                               extra: extra.agDescription,
                               type: .info)
        // TODO: 移动端暂时没有该功能
    }
    
    func setAnnouncement(_ announcement: String?) {
        let extra = ["announcement": announcement ?? ""]
        delegate?.onEasemobLog(content: "set announcement",
                               extra: extra.agDescription,
                               type: .info)
        AgoraChatClient.shared().roomManager.updateChatroomAnnouncement(withId: chatRoomId,
                                                                        announcement: announcement) { [weak self] (chatRoom,chatError) in
            guard let error = chatError else {
                return
            }
            let extra = ["announcement": announcement ?? "",
                         "errorCode": "\(error.code)"]
            self?.delegate?.onEasemobLog(content: "set announcement error",
                                         extra: extra.agDescription,
                                         type: .error)
        }
    }
    
    func getAllMutedState(success: EasemobMuteStateCompletion?,
                          failure: EasemobFailureCompletion?) {
        let extra = ["chatRoomId": chatRoomId]
        delegate?.onEasemobLog(content: "get chatroom specification",
                               extra: extra.agDescription,
                               type: .info)
        AgoraChatClient.shared().roomManager.getChatroomSpecificationFromServer(withId: chatRoomId) { [weak self] (chatRoom, chatError) in
            guard let `self` = self else {
                return
            }
            guard chatError == nil else {
                var extra = ["aError": "\(chatError!.code.rawValue)"]
                
                self.delegate?.onEasemobLog(content: "get chatroom specification fail",
                                            extra: extra.agDescription,
                                            type: .error)
                self.delegate?.didOccurError(type: .fetchError(chatError!.code.rawValue))
                return
            }
            guard let room = chatRoom else {
                return
            }
            
            let isMuteAllMembers = room.isMuteAllMembers
            let extra = ["isMuteAllMembers": isMuteAllMembers ? 1 : 0]
            self.delegate?.onEasemobLog(content: "chatroom specification",
                                        extra: extra.agDescription,
                                        type: .info)
            
        
            success?(room.isMuteAllMembers)
        }
    }
    
    func getLocalMutedState(success: EasemobMuteStateCompletion?,
                            failure: EasemobFailureCompletion?) {
        let extra = ["chatRoomId": chatRoomId]
        
        delegate?.onEasemobLog(content: "get local mute state",
                               extra: extra.agDescription,
                               type: .info)
        AgoraChatClient.shared().roomManager.getChatroomMuteListFromServer(withId: chatRoomId,
                                                                           pageNumber: 0,
                                                                           pageSize: 100) { [weak self] (muteList, chatError)  in
            guard let `self` = self else {
                return
            }
            guard chatError == nil else {
                var extra = ["aError": "\(chatError!.code.rawValue)"]
                
                self.delegate?.onEasemobLog(content: "get local mute state fail",
                                            extra: extra.agDescription,
                                            type: .error)
                failure?(.fetchError(chatError!.code.rawValue))
                return
            }
            
            var localMuted: Bool = false
            
            if let list = muteList {
                localMuted = list.contains([self.userConfig.userName])
            }
            
            let extra = ["localMuted": localMuted ? 1 : 0]
            self.delegate?.onEasemobLog(content: "local mute state",
                                        extra: extra.agDescription,
                                        type: .info)
            success?(localMuted)
        }
    }
    
    func getAnnouncement(success: EasemobStringCompletion?,
                         failure: EasemobFailureCompletion?) {
        var extra = ["chatRoomId": chatRoomId]
        
        self.delegate?.onEasemobLog(content: "get announcement",
                                    extra: extra.agDescription,
                                    type: .info)
        AgoraChatClient.shared().roomManager.getChatroomAnnouncement(withId: chatRoomId) { [weak self] (announcement,chatError)  in
            guard let `self` = self else {
                return
            }
            guard chatError == nil else {
                var extra = ["aError": "\(chatError!.code.rawValue)"]
                
                self.delegate?.onEasemobLog(content: "get announcement fail",
                                            extra: extra.agDescription,
                                            type: .error)
                failure?(.fetchError(chatError!.code.rawValue))
                return
            }
            let extra = ["announcement": announcement ?? ""]
            self.delegate?.onEasemobLog(content: "announcement",
                                        extra: extra.agDescription,
                                        type: .info)
            success?(announcement)
        }
    }
    
    
    
    func getHistoryMessages(success: EasemobMessageListCompletion?,
                            failure: EasemobFailureCompletion?) {
        var historyMsg:Array<AgoraChatMessage> = []
        var taskResult: [[AgoraChatMessage]] = []
        self.recvRoomIds.forEach { roomId in
            var extra = ["chatRoomId": roomId]
            
            self.delegate?.onEasemobLog(content: "get history messages",
                                        extra: extra.agDescription,
                                        type: .info)
            AgoraChatClient.shared().chatManager.asyncFetchHistoryMessages(fromServer: roomId,
                                                                           conversationType: .chatRoom,
                                                                           startMessageId: "",
                                                                           pageSize: 50) { [weak self] (result,chatError) in
                guard let `self` = self else {
                    return
                }
                guard chatError == nil else {
                    var extra = ["aError": "\(chatError!.code.rawValue)"]
                    
                    self.delegate?.onEasemobLog(content: "get history messages fail",
                                                extra: extra.agDescription,
                                                type: .error)
                    failure?(.fetchError(chatError!.code.rawValue))
                    return
                }
               
                let list = result?.list as? [AgoraChatMessage] ?? []
                let messageList = list.filter({return ($0.body.type == .text || $0.body.type == .image || $0.body.type == .cmd)})
                
                taskResult.append(messageList)
                // 所有消息获取到再回掉回去
                if(self.recvRoomIds.count == taskResult.count){
                    taskResult.forEach { msgs in
                        msgs.forEach { msg in
                            historyMsg.append(msg)
                        }
                    }
                  
                    guard let last = historyMsg.last else {
                        success?(nil)
                        return
                    }
                    
                    historyMsg.sort{(a,b) -> Bool in
                        return a.timestamp < b.timestamp
                    }
                    self.latestMessageId = last.messageId
                    success?(historyMsg)
                    
                    // 从消息中回溯出当前是否在禁言, 有bug
                    let cmdMessageList:[AgoraChatMessage] = historyMsg.filter({
                        if($0.body.type != .cmd){
                            return false
                        }
                        
                        return true
                        
                        let body = $0.body as? AgoraChatCmdMessageBody
                        
                        if(body?.action == "setAllMute" || body?.action == "removeAllMute" || body?.action == "mute" || body?.action == "unmute"){
                            return true
                        }
                        return false
                    })
                    
                    guard let cmdMessage = cmdMessageList.last else {
                        return
                    }
                    
                    
                    let body = cmdMessage.body as? AgoraChatCmdMessageBody
                    let type = AgoraChatEasemobCmdMessageBodyActionType(rawValue: body!.action)
                    // 最后一条cmd消息是否是禁言
                    switch type {
                    case .delete:
                        // recall消息暂不处理
                        break
                    case .setAllMute:
                        self.delegate?.didAllMuteStateChanged(true)
                    case .removeAllMute:
                        self.delegate?.didAllMuteStateChanged(false)
                    case .mute:
                        guard let muteUserId = cmdMessage.ext?[muteMemberKey] as? String,
                              muteUserId == userConfig.userName else {
                            break
                        }
                        self.delegate?.didLocalMuteStateChanged(true)
                    case .unmute:
                        guard let muteUserId = cmdMessage.ext?[muteMemberKey] as? String,
                              muteUserId == userConfig.userName else {
                            break
                        }
                        self.delegate?.didLocalMuteStateChanged(false)
                    case .none:
                        break
                    }
                }
            }
        }
    }
}

// MARK: - private
private extension AgoraChatEasemobGroup {
    func _login(token: String,
                lowercaseName: String,
                success: EasemobSuccessCompletion?,
                failure: EasemobFailureCompletion?) {
        AgoraChatClient.shared().login(withUsername: lowercaseName,
                                       token: token) { [weak self] (userName, aLoginError) in
            guard let `self` = self else {
                return
            }
            guard let loginError = aLoginError,
                  loginError.code != .userAlreadyLoginSame else {
                self.loginRetryCount = 0
                self.joinRetryCountMap.removeAll()
                self.delegate?.onEasemobLog(content: "login success",
                                            extra: nil,
                                            type: .info)
                self.updateLocalUserInfo()
                success?()
                return
            }
            switch loginError.code {
            case .userNotFound:
                AgoraChatClient.shared().register(withUsername: self.userConfig.userName,
                                                  password: self.userConfig.password) { (userName, chatError) in
                    if let chatError = chatError {
                        self.loginRetryCount = 0
                        self.joinRetryCountMap.removeAll()
                        let extra = ["userId":self.userConfig.userName,
                                     "password":self.userConfig.password,
                                     "code": "\(chatError.code.rawValue)"]
                        self.delegate?.onEasemobLog(content: "register fail",
                                                    extra: extra.agDescription,
                                                    type: .error)
                        failure?(.loginFailed)
                        return
                    }
                    self.delegate?.onEasemobLog(content: "register success",
                                                extra: nil,
                                                type: .info)
                    self._login(token: token,
                                lowercaseName: lowercaseName,
                                success: success,
                                failure: failure)
                }
            default:
                guard self.loginRetryCount < self.maxRetryCount else {
                    self.loginRetryCount = 0
                    failure?(.loginFailed)
                    return
                }
                self.loginRetryCount += 1
                self._login(token: token,
                            lowercaseName: lowercaseName,
                            success: success,
                            failure: failure)
            }
        }
    }
    
    
    
    
    func _join(roomId:String, success: EasemobJoinSuccessCompletion?,
               failure: EasemobJoinFailureCompletion?) {
        AgoraChatClient.shared().roomManager.joinChatroom(roomId) { [weak self] (chatRoom, chatError) in
            guard let `self` = self else {
                return
            }
            guard let `chatError` = chatError else {
//                self.chatRoom = chatRoom
                self.joinRetryCountMap[roomId] = 0
                let extra = ["chatRoomId":roomId]
                self.delegate?.onEasemobLog(content: "join chat success",
                                            extra: extra.agDescription,
                                            type: .info)
                success?(chatRoom)
                return
            }
            
            let retryCount = self.joinRetryCountMap[roomId] ?? 0
            guard retryCount < self.maxRetryCount else {
                self.joinRetryCountMap[roomId] = 0
                let extra = ["chatRoomId":roomId]
                self.delegate?.onEasemobLog(content: "join chat fail",
                                            extra: extra.agDescription,
                                            type: .error)
                failure?(roomId, .joinFailed)
                return
            }
            let extra = ["chatRoomId":roomId]
            self.delegate?.onEasemobLog(content: "retry join chat",
                                        extra: extra.agDescription,
                                        type: .error)
            self.joinRetryCountMap[roomId] = retryCount + 1
            self._join(roomId: roomId, success: success,
                       failure: failure)
        }
    }
    
    func updateLocalUserInfo() {
        let userInfo = AgoraChatUserInfo()
        userInfo.nickname = userConfig.nickName
        let extDic = ["role": userConfig.role, "chatGroupUuids": self.userConfig.chatGroupUuids] as [String : Any]
        
        if let data = extDic.jsonData() {
            let extString = String(data: data,
                                   encoding: .utf8)
            userInfo.ext = extString
        }
        
        if let avatarUrl = userConfig.avatarurl {
            userInfo.avatarUrl = avatarUrl
        }
        AgoraChatClient.shared().userInfoManager.updateOwn(userInfo) { [weak self] (chatUserInfo, chatError) in
            guard let `self` = self else {
                return
            }
            guard let `chatError` = chatError else {
                let extra = ["ext": userInfo.ext ?? ""]
                self.delegate?.onEasemobLog(content: "update user info success",
                                            extra: extra.agDescription,
                                            type: .info)
                return
            }
            
            let extra = ["ext": userInfo.ext ?? "",
                         "code": "\(chatError.code.rawValue)"]
            self.delegate?.onEasemobLog(content: "update user info fail",
                                        extra: extra.agDescription,
                                        type: .error)
            self.delegate?.didOccurError(type: .updateUserInfo)
        }
    }
    
    func messageExt() -> [String: Any] {
        var ext: [String : Any] = ["msgtype": 0,
                                   "role": userConfig.role,
                                   "nickName": userConfig.nickName,
                                   "roomUuid": userConfig.fcrRoomId]
        ext["avatarUrl"] = userConfig.avatarurl
        return ext
    }
}

// MARK: - Easemob Delegate
extension AgoraChatEasemobGroup: AgoraChatClientDelegate,
                            AgoraChatManagerDelegate,
                            AgoraChatroomManagerDelegate {
    // MARK: AgoraChatClientDelegate
    func connectionStateDidChange(_ aConnectionState: AgoraChatConnectionState) {
        delegate?.didConnectionStateChaned(aConnectionState)
        
        let extra = ["state": aConnectionState]
        delegate?.onEasemobLog(content: "connection state chaned",
                               extra: extra.agDescription,
                               type: .info)
    }
    
    func userAccountDidLoginFromOtherDevice() {
        delegate?.onEasemobLog(content: "user account did login from other device",
                                    extra: nil,
                                    type: .error)
        
        delegate?.didOccurError(type: .loginedFromRemote)
    }
    
    func userAccountDidForced(toLogout aError: AgoraChatError?) {
        delegate?.didOccurError(type: .forcedLogOut)
        
        var extra: [String: String]?
        if let error = aError {
            extra = ["aError": "\(error.code.rawValue)"]
        }
        
        delegate?.onEasemobLog(content: "user account was forced to logout",
                               extra: extra?.agDescription,
                               type: .error)
    }
    
    // MARK: AgoraChatManagerDelegate
    func messagesDidReceive(_ aMessages: [AgoraChatMessage]) {
        let extra = ["messages": aMessages.agDescription]
        delegate?.onEasemobLog(content: "receive messages",
                               extra: extra.agDescription,
                               type: .info)
        // 只接受接受组消息
        let list = aMessages.filter { message in
            guard message.chatType == .chatRoom,
                  recvRoomIds.contains(message.to),
                  (message.body.type == .text || message.body.type == .image) else {
                return false
            }
            return true
        }
        guard list.count > 0,
         let last = list.last else {
            return
        }
        latestMessageId = last.messageId
        delegate?.didReceiveMessages(list: list)
    }
    
    func cmdMessagesDidReceive(_ aCmdMessages: [AgoraChatMessage]) {
        let extra = ["messages": aCmdMessages.agDescription]
        delegate?.onEasemobLog(content: "easemob receive cmd messages",
                               extra: extra.agDescription,
                               type: .info)
        
        var messageList = [AgoraChatMessage]()
        for cmdMessage in aCmdMessages {
            guard recvRoomIds.contains(cmdMessage.to),
                  let body = cmdMessage.body as? AgoraChatCmdMessageBody,
                  let type = AgoraChatEasemobCmdMessageBodyActionType(rawValue: body.action) else {
                continue
            }
            switch type {
            case .delete:
                // recall消息暂不处理
                break
            case .setAllMute:
                messageList.append(cmdMessage)
                delegate?.didAllMuteStateChanged(true)
            case .removeAllMute:
                messageList.append(cmdMessage)
                delegate?.didAllMuteStateChanged(false)
            case .mute:
                guard let muteUserId = cmdMessage.ext?[muteMemberKey] as? String,
                      muteUserId == userConfig.userName else {
                    continue
                }
                messageList.append(cmdMessage)
                delegate?.didLocalMuteStateChanged(true)
            case .unmute:
                guard let muteUserId = cmdMessage.ext?[muteMemberKey] as? String,
                      muteUserId == userConfig.userName else {
                    continue
                }
                messageList.append(cmdMessage)
                delegate?.didLocalMuteStateChanged(false)
            }
        }
        guard messageList.count > 0 else {
            return
        }
        delegate?.didReceiveMessages(list: messageList)
    }

    // MARK: AgoraChatroomManagerDelegate
    func chatroomMuteListDidUpdate(_ aChatroom: AgoraChatroom,
                                   addedMutedMembers aMutes: [String],
                                   muteExpire aMuteExpire: Int) {
        let extra = ["aMutes": aMutes.agDescription]
        delegate?.onEasemobLog(content: "users muted",
                               extra: extra.agDescription,
                               type: .info)
        
        guard aChatroom.chatroomId == chatRoomId,
              aMutes.count > 0,
              aMutes.contains(userConfig.userName) else {
            return
        }
        delegate?.didLocalMuteStateChanged(true)
    }
    
    func chatroomMuteListDidUpdate(_ aChatroom: AgoraChatroom,
                                   removedMutedMembers aMutes: [String]) {
        let extra = ["aMutes": aMutes.agDescription]
        delegate?.onEasemobLog(content: "users unmuted",
                               extra: extra.agDescription,
                               type: .info)
        
        guard aChatroom.chatroomId == chatRoomId,
              aMutes.count > 0,
              aMutes.contains(userConfig.userName) else {
            return
        }
        delegate?.didLocalMuteStateChanged(false)
    }
        
    func chatroomAllMemberMuteChanged(_ aChatroom: AgoraChatroom,
                                      isAllMemberMuted aMuted: Bool) {
        let extra = ["muted": "\(aMuted)"]
        delegate?.onEasemobLog(content: "users all muted",
                               extra: extra.agDescription,
                               type: .info)
        guard aChatroom.chatroomId == chatRoomId else {
            return
        }
        delegate?.didAllMuteStateChanged(aMuted)
    }
    
    func chatroomAnnouncementDidUpdate(_ aChatroom: AgoraChatroom,
                                       announcement aAnnouncement: String?) {
        let extra = ["announcement": aAnnouncement ?? ""]
        delegate?.onEasemobLog(content: "announcement updated",
                               extra: extra.agDescription,
                               type: .info)
        guard aChatroom.chatroomId == chatRoomId else {
            return
        }
        delegate?.didReceiveAnnouncement(aAnnouncement)
    }
}
