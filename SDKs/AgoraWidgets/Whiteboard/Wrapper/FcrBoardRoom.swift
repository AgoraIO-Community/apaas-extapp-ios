//
//  FcrBoardRoom.swift
//  AgoraWidgets
//
//  Created by Cavan on 2022/6/6.
//

import Foundation
import Whiteboard

class FcrBoardRoom: NSObject, WhiteSlideDelegate {
    private weak var whiteRoom: WhiteRoom?
    private let whiteView: WhiteBoardView
    private let whiteSDK: WhiteSDK
    private let listener: FcrBoardListener
    
    private var hasLeft: Bool = false
    private var connection: FcrBoardRoomConnectionState = .disconnected
    private var joinConfig: FcrBoardRoomJoinConfig?
    private var mainWindow: FcrBoardMainWindow?
    
    weak var delegate: FcrBoardRoomDelegate?
    weak var logTube: FcrBoardLogTube?
    
    init(appId: String,
         region: FcrBoardRegion,
         backgroundColor: UIColor?,
         logTube: FcrBoardLogTube?) {
        let listener = FcrBoardListener()
        
        let whiteView = WhiteBoardView(frame: .zero,
                                       configuration: WKWebViewConfiguration.defaultConfig())
        
        whiteView.backgroundColor = backgroundColor
        
        let sdkConfig = WhiteSdkConfiguration(app: appId)
        sdkConfig.enableIFramePlugin = false
        sdkConfig.region = region.netlessValue
        sdkConfig.useMultiViews = true
        sdkConfig.userCursor = true
        sdkConfig.enableAppliancePlugin = true
        
        let whiteSDK = WhiteSDK(whiteBoardView: whiteView,
                                config: sdkConfig,
                                commonCallbackDelegate: listener,
                                audioMixerBridgeDelegate: listener)
        
        self.whiteView = whiteView
        self.whiteSDK = whiteSDK
        self.listener = listener
        self.logTube = logTube
        
        super.init()
        
        whiteSDK.setSlideDelegate(self)
        listener.roomNeedObserve = self
        
        registerH5App()
        
        // Log
        let extra = ["appId": appId,
                     "region": "\(region.rawValue)"]
        
        log(content: "init boardRoom",
            extra: extra.agDescription,
            type: .info)
        
        let netlessExtra = ["sdkConfig": sdkConfig.agDescription,
                            "whiteView": whiteView.description,
                            "commonCallbackDelegate": listener.description,
                            "audioMixerBridgeDelegate": listener.description]
        
        log(content: "init white sdk",
            extra: netlessExtra.agDescription,
            type: .info,
            fromClass: WhiteSDK.self,
            funcName: "init")
    }
    

    func onSlideError(_ slideError: WhiteSlideErrorType, errorMessage: String, slideId: String, slideIndex: Int) {
        delegate?.onSlideError(slideError: slideError, errorMessage: errorMessage, slideId: slideId, slideIndex: slideIndex)
    }
    
    func recoverSlide(slideId:String, slideIndex:Int) {
        self.whiteSDK.recoverSlide(slideId, slideIndex: slideIndex)
    }
    
    func join(config: FcrBoardRoomJoinConfig,
              superView: UIView,
              success: @escaping (FcrBoardMainWindow) -> Void,
              failure: @escaping (Error) -> Void) {
        hasLeft = false
        joinConfig = config
        
        superView.addSubview(whiteView)
        
        whiteView.mas_makeConstraints { make in
            make?.left.right().top().bottom().equalTo()(superView)
        }
        
        joinRoom { [weak self] (whiteRoom) in
            guard let `self` = self else {
                return
            }
            
            // Success
            let mainWindow = FcrBoardMainWindow(whiteView: self.whiteView,
                                                whiteSDK: self.whiteSDK,
                                                whiteRoom: whiteRoom,
                                                hasOperationPrivilege: config.hasOperationPrivilege)
           
            self.mainWindow = mainWindow
            
            self.listener.mainWindowNeedObserve = mainWindow
            
            success(mainWindow)
        } failure: { (error) in
            failure(error)
        }
    }
    
    func leave() {
        hasLeft = true
        whiteRoom?.disconnect(nil)
        
        let extra = ["hasLeft": hasLeft]
        
        log(content: "leave",
            extra: extra.description,
            type: .info)
        
        log(content: "disconnect",
            type: .info,
            fromClass: WhiteRoom.self,
            funcName: "disconnect")
    }
}

// MARK: - private
private extension FcrBoardRoom {
    func log(content: String,
             extra: String? = nil,
             type: FcrBoardLogType,
             fromClass: AnyClass? = nil,
             funcName: String = #function,
             line: Int = #line) {
        var classType: AnyClass
        
        if let `fromClass` = fromClass {
            classType = fromClass
        } else {
            classType = self.classForCoder
        }
        
        logTube?.onBoardLog(content: content,
                            extra: extra,
                            type: type,
                            fromClass: classType,
                            funcName: funcName,
                            line: line)
    }
    
    func callConnectionStateUpdatedCallback(state: FcrBoardRoomConnectionState) {
        guard state != connection else {
            return
        }
        
        log(content: "on connection state updated",
            extra: state.agDescription,
            type: .info)
        
        connection = state
        
        delegate?.onConnectionStateUpdated(state: state)
    }
    
  
    
    func getWhiteRoomConfig() -> WhiteRoomConfig? {
        guard let config = joinConfig else {
            log(content: "join config nil",
                type: .error)
            return nil
        }
        
        let length = UIDevice.current.agora_is_pad ? 34 : 32
        let left = UIDevice.current.agora_is_pad ? 15 : 12
        let bottom = UIDevice.current.agora_is_pad ? 20 : 15
        let backgroundColor = UIConfig.netlessBoard.courseware.backgroundColor
        
        let defaultCollectorStyles = ["position":"fixed",
                                      "left":"\(left)px",
                                      "bottom":"\(bottom)px",
                                      "width":"\(length)px",
                                      "height":"\(length)px",
                                      "backgroundColor": "\(backgroundColor.hexString)"]
        
        let params = WhiteWindowParams()
        params.chessboard = false
        params.containerSizeRatio = NSNumber.init(value: config.boardRatio)
        params.collectorStyles = defaultCollectorStyles
        
        let roomConfig = WhiteRoomConfig(uuid: config.roomId,
                                         roomToken: config.roomToken,
                                         uid: config.userId,
                                         userPayload: ["cursorName": config.userName])
        roomConfig.floatBar = true
        roomConfig.isWritable = config.hasOperationPrivilege
        roomConfig.disableNewPencil = false
        roomConfig.windowParams = params
        roomConfig.disableCameraTransform = true
#if DEBUG
        roomConfig.enableWritableAssert = true
#endif
        return roomConfig
    }
    
    func reJoin() {
        callConnectionStateUpdatedCallback(state: .reconnecting)
        
        guard let `mainWindow` = mainWindow else {
            self.log(content: "mainWindow nil",
                     type: .warning)
            return
        }
        
        joinRoom(isRejoin: true) { [weak mainWindow] (whiteRoom) in
            // Success
            guard let `mainWindow` = mainWindow else {
                self.log(content: "rejoin successfully, but mainWindow nil",
                         type: .error)
                return
            }
            
            mainWindow.setValue(whiteRoom,
                                forKey: "whiteRoom")
        } failure: { [weak self] _ in
            self?.reJoin()
        }
    }
    
    func registerH5App() {
        guard let bundle = Bundle.agora_bundle("AgoraWidgets"),
              let javascriptPath = bundle.path(forResource: "app-talkative",
                                               ofType: "js"),
              let javascriptString = try? String(contentsOfFile: javascriptPath,
                                                 encoding: .utf8) else {
            return
        }
        let kind = "Talkative"
        let variable = "NetlessAppTalkative.default"
        let appParams = WhiteRegisterAppParams(javascriptString: javascriptString,
                                               kind: kind,
                                               appOptions: [:],
                                               variable: variable)
        whiteSDK.registerApp(with: appParams) { [weak self] error in
            guard let error = error else {
                self?.log(content: "register H5App ",
                          extra: appParams.description,
                          type: .info)
                return
            }
            self?.log(content: "register H5App",
                      extra: appParams.description,
                      type: .error)
        }
    }
    
    func joinRoom(isRejoin: Bool = false,
                  success: @escaping (WhiteRoom) -> Void,
                  failure: @escaping (Error) -> Void) {
        guard let roomConfig = getWhiteRoomConfig() else {
            return
        }
        
        let extra = ["roomConfig": roomConfig.agDescription,
                     "hasLeft": hasLeft.agDescription]
        
        let joinText = (isRejoin ? "reJoin room" : "join room")
        
        log(content: joinText,
            extra: extra.agDescription,
            type: .info)
        
        log(content: joinText,
            extra: roomConfig.agDescription,
            type: .info,
            fromClass: WhiteSDK.self,
            funcName: "joinRoom")
        
        whiteSDK.joinRoom(with: roomConfig,
                          callbacks: listener) { [weak self] (isSuccess,
                                                              whiteRoom,
                                                              error) in
            // Failure
            guard let `self` = self else {
                return
            }
            
            let netlessExtra = ["isSuccess": isSuccess.agDescription,
                                "whiteRoom": StringIsEmpty(whiteRoom?.description),
                                "error": StringIsEmpty(error?.localizedDescription)]
            
            let logType: FcrBoardLogType = (error == nil ? .info : .error)
            
            self.log(content: joinText + " callback",
                     extra: netlessExtra.agDescription,
                     type: logType,
                     fromClass: WhiteSDK.self,
                     funcName: "joinRoomCallback")
            
            guard isSuccess,
                  let `whiteRoom` = whiteRoom,
                  error == nil else {
                let `error` = NSError.create(error)
                
                let extra = ["error": error.localizedDescription,
                             "whiteRoom": StringIsEmpty(whiteRoom?.debugDescription)]
                
                self.log(content: joinText + " failure",
                         extra: extra.agDescription,
                         type: .error)
                
                failure(error)
                
                return
            }
            
            self.log(content: joinText + " success",
                     extra: roomConfig.agDescription,
                     type: .info)
            
            success(whiteRoom)
        }
    }
}

extension FcrBoardRoom: FcrBoardRoomNeedObserve {
    func onPhaseChanged(_ phase: WhiteRoomPhase) {
        let extra = ["phase": phase.agDescription]
        
        log(content: "on phase changed",
            extra: extra.agDescription,
            type: .info,
            fromClass: WhiteSDK.self,
            funcName: "firePhaseChanged")
        
        let state = phase.fcrType
        
        if state == .disconnected,
            hasLeft == false {
            reJoin()
        } else {
            callConnectionStateUpdatedCallback(state: state)
        }
    }
    
    func onLogger(_ dict: [AnyHashable : Any]) {
        logTube?.onNetlessLog(content: dict.description,
                              extra: nil,
                              type: .info)
    }
    
    func onThrowError(_ error: Error) {
        logTube?.onNetlessLog(content: error.localizedDescription,
                              extra: nil,
                              type: .error)
    }
}
