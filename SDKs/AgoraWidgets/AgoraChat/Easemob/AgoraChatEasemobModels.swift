//
//  AgoraChatEasemobModels.swift
//  AgoraWidgets
//
//  Created by LYY on 2022/7/19.
//

import Foundation
import AgoraChat
import AgoraLog

typealias EasemobSuccessCompletion = () -> ()
typealias EasemobJoinSuccessCompletion = (_ room:AgoraChatroom?) -> ()
typealias EasemobSendSuccessCompletion = (_ msg:[AgoraChatMessage]) -> ()
typealias EasemobStringCompletion = (String?) -> ()
typealias EasemobMuteStateCompletion = (_ muted: Bool) -> ()
typealias EasemobMessageListCompletion = ([AgoraChatMessage]?) -> ()
typealias EasemobFailureCompletion = (AgoraChatErrorType) -> ()
typealias EasemobSendFailureCompletion = (AgoraChatErrorType) -> ()
typealias EasemobJoinFailureCompletion = (_ roomId:String, _ errType:AgoraChatErrorType) -> ()

protocol AgoraChatEasemobDelegate: NSObjectProtocol {
    func didReceiveMessages(list: [AgoraChatMessage])
    func didSendMessages(list: [AgoraChatMessage])
    func didLocalMuteStateChanged(_ muted: Bool)
    func didAllMuteStateChanged(_ muted: Bool)
    func didReceiveAnnouncement(_ announcement: String?)
    func didConnectionStateChaned(_ state: AgoraChatConnectionState)
    func onEasemobLog(content: String,
                      extra: String?,
                      type: FcrEasemobLogType)
    func didOccurError(type: AgoraChatErrorType)
}


struct AgoraChatEasemoExtraInfo: Convertable {
    var avatarurl: String?
}

struct AgoraChatEasemobRoomProperties: Convertable {
    var chatRoomId: String
    var appName: String
    var appKey: String
    var orgName: String?
}

struct AgoraChatEasemobLaunchConfig {
    var roomId: String
    var userId: String
    var userName: String
    var chatRoomId: String
    var password: String
}

struct AgoraChatEasemobUserConfig {
    var userName: String
    var nickName: String
    var avatarurl: String?
    var fcrRoomId: String
    var password: String
    var role: Int
    var sendRoomIds: Array<String>
    var recvRoomIds: Array<String>
    var chatGroupUuids: Array<String>
    
    init(userName: String,
         nickName: String,
         avatarurl: String?,
         fcrRoomId: String,
         password: String? = "",
         role: Int,
         sendRoomIds: Array<String>? = [],
         recvRoomIds: Array<String>? = [],
         chatGroupUuids: Array<String>? = []) {
        var finalAvatarUrl = "https://download-sdk.oss-cn-beijing.aliyuncs.com/downloads/IMDemo/avatar/Image1.png"
        var finalPassword = userName
        if let avatarurl = avatarurl {
            finalAvatarUrl = avatarurl
        }
        if let password = password {
            finalPassword = password
        }
        self.userName = userName
        self.nickName = nickName
        self.avatarurl = finalAvatarUrl
        self.fcrRoomId = fcrRoomId
        self.password = finalPassword
        self.role = role
        self.sendRoomIds = sendRoomIds ?? []
        self.recvRoomIds = recvRoomIds ?? []
        self.chatGroupUuids = chatGroupUuids ?? []
    }
}

enum AgoraChatEasemobCmdMessageBodyActionType: String {
    case delete = "DEL"
    case setAllMute = "setAllMute"
    case removeAllMute = "removeAllMute"
    case mute = "mute"
    case unmute = "unmute"
}

extension AgoraChatMessage {
    func toViewModel(localUserId: String) -> AgoraChatMessageViewType? {
        let isLocal = (from == localUserId)
        switch body.type {
        case .image:
            return toImageMessageModel(isLocal: isLocal)
        case .text:
            return toTextMessageModel(isLocal: isLocal)
        case .cmd:
            return toCmdMessageModel()
        default:
            return nil
        }
    }
    
    fileprivate func toImageMessageModel(isLocal: Bool) -> AgoraChatMessageViewType {
        var userRole = ""
        var userName = from
        var avatarUrl: String?
        
        let nameKey = "nickName"
        let avatarKey = "avatarUrl"
        let roleKey = "role"
        if let value = ext?[nameKey] as? String {
            userName = value
        }
        if let value = ext?[avatarKey] as? String {
            avatarUrl = value
        }
        if let value = ext?[roleKey] as? Int {
            userRole = value.toRoleName()
        }
        
        var image: UIImage?
        var imageRemoteUrl: String?
        if let imageMessageBody = body as? AgoraChatImageMessageBody {
            let imageInfo = imageMessageBody.toImageInfo()
            image = imageInfo.0
            imageRemoteUrl = imageInfo.1
        }
        let model = AgoraChatImageMessageModel(isLocal: isLocal,
                                               userRole: userRole,
                                               userName: userName,
                                               avatar: avatarUrl,
                                               image: image,
                                               imageRemoteUrl: imageRemoteUrl)
        return AgoraChatMessageViewType.image(model)
    }
    
    fileprivate func toTextMessageModel(isLocal: Bool) -> AgoraChatMessageViewType {
        var userRole = ""
        var userName = from
        var avatarUrl: String?
        
        let nameKey = "nickName"
        let avatarKey = "avatarUrl"
        let roleKey = "role"
        if let value = ext?[nameKey] as? String {
            userName = value
        }
        if let value = ext?[avatarKey] as? String {
            avatarUrl = value
        }
        if let value = ext?[roleKey] as? Int {
            userRole = value.toRoleName()
        }
        
        var text = ""
        if let textBody = body as? AgoraChatTextMessageBody {
            text = textBody.text
        }
        let model = AgoraChatTextMessageModel(isLocal: isLocal,
                                              userRole: userRole,
                                              userName: userName,
                                              avatar: avatarUrl,
                                              text: text)
        return AgoraChatMessageViewType.text(model)
    }
    
    fileprivate func toCmdMessageModel() -> AgoraChatMessageViewType? {
        guard let cmdBody = body as? AgoraChatCmdMessageBody,
              let actionType = AgoraChatEasemobCmdMessageBodyActionType(rawValue: cmdBody.action) else {
            return nil
        }
        let config = UIConfig.agoraChat
        let operatorNameKey = "nickName"
        var notice: String?
        switch actionType {
        case .delete:
            break
        case .setAllMute:
            notice = config.muteAll.muteText
        case .removeAllMute:
            notice = config.muteAll.unmuteText
        case .mute:
            var operatorName = ""
            if let name = ext?[operatorNameKey] as? String {
                operatorName = name
            }
            let originText = config.mute.muteTextWithName
            notice = originText.replacingOccurrences(of: String.widgets_localized_replacing(),
                                                     with: operatorName)
        case .unmute:
            var operatorName = ""
            if let name = ext?[operatorNameKey] as? String {
                operatorName = name
            }
            let originText = config.mute.unmuteTextWithName
            notice = originText.replacingOccurrences(of: String.widgets_localized_replacing(),
                                                     with: operatorName)
        }
        guard let noticeString = notice else {
            return nil
        }
        return AgoraChatMessageViewType.notice(noticeString)
    }
}

extension String {
    func userRoleToInt() -> Int {
        if self == "teacher" {
            return 1
        } else {
            return 2
        }
    }
}

extension AgoraChatError {
    func toNSError() -> NSError {
        let error = NSError(domain: errorDescription,
                            code: code.rawValue)
        return error
    }
}

extension AgoraChatImageMessageBody {
    func toImageInfo() -> (UIImage?,String?) {
        if let localImage = UIImage(contentsOfFile: thumbnailLocalPath) {
            return (localImage,nil)
        } else if let localImage = UIImage(contentsOfFile: localPath) {
            return (localImage,nil)
        }
        
        guard AgoraChatClient.shared().options.autoDownloadThumbnail else {
            return (UIConfig.agoraChat.picture.brokenImage, nil)
        }
        
        return (nil,thumbnailRemotePath)
    }
}

// MARK: - Log
enum FcrEasemobLogType: Int {
    case info    = 1
    case warning = 2
    case error   = 3
    
    var agoraType: AgoraLogType {
        switch self {
        case .info:     return .info
        case .warning:  return .warning
        case .error:    return .error
        }
    }
}

extension AgoraChatConnectionState: AgoraWidgetDescription {
    var agDescription: String {
        switch self {
        case .connected:    return "connected"
        case .disconnected: return "disconnected"
        }
    }
}

extension AgoraChatType: AgoraWidgetDescription {
    var agDescription: String {
        switch self {
        case .chat:      return "chat"
        case .chatRoom:  return "chatRoom"
        case .groupChat: return "groupChat"
        }
    }
}

extension AgoraChatMessageBodyType: AgoraWidgetDescription {
    var agDescription: String {
        switch self {
        case .text:     return "text"
        case .image:    return "image"
        case .video:    return "video"
        case .location: return "location"
        case .voice:    return "voice"
        case .file:     return "file"
        case .cmd:      return "cmd"
        case .custom:   return "custom"
        }
    }
}

extension AgoraChatMessage: AgoraWidgetDescription {
    var agDescription: String {
        let array = ["from: \(from)",
                     "to: \(to)",
                     "chatType: \(chatType.agDescription)",
                     "bodyType: \(body.type.agDescription)",
                     "roomType: \(messageId)"]
        
        return array.agDescription
    }
}
