//
//  FcrBoardWidget.swift
//  AgoraWidgets
//
//  Created by Cavan on 2022/6/8.
//

import AgoraUIBaseViews
import AgoraWidget
import AgoraLog
import Photos
import Armin
import Whiteboard

@objcMembers public class FcrBoardWidget: AgoraNativeWidget {
    // Views
    private lazy var pageControl = FcrBoardPageControlView(frame: .zero)
    
    // Data
    private lazy var snapshotFolder: String = {
        let folderName = "\(info.roomInfo.roomName)_\(String.currentTimeString())"
        let folder = NSSearchPathForDirectoriesInDomains(.cachesDirectory,
                                                         .userDomainMask,
                                                         true)[0].appendingPathComponent(folderName)
        return folder
    }()
    
    private var imageCountToSave: Int = 0
    
    private var canJoin = false
    
    private var retryTime = 0
    // 教师角色加入房间成功时设置，学生角色监听grantedUsers变化设置
    private var hasOperationPrivilege: Bool = false {
        didSet {
            guard pageControl.agora_enable else {
                return
            }
            
            pageControl.agora_visible = hasOperationPrivilege
        }
    }
    
    // Controller
    private var boardRoom: FcrBoardRoom?
    private var mainWindow: FcrBoardMainWindow?
    private var serverAPI: FcrBoardServerAPI?
    
    public override func onWidgetRoomPropertiesUpdated(_ properties: [String : Any],
                                                       cause: [String : Any]?,
                                                       keyPaths: [String],
                                                       operatorUser: AgoraWidgetUserInfo?) {
        super.onWidgetRoomPropertiesUpdated(properties,
                                            cause: cause,
                                            keyPaths: keyPaths,
                                            operatorUser: operatorUser)
        join()

        analyzeGrantedUsersFromRoomProperties()
    }
    
    func retry(slideId:String, slideIndex: Int){
        self.retryTime += 1
        self.boardRoom?.recoverSlide(slideId: slideId, slideIndex: slideIndex)
        showToast("fcr_board_slide_retry".localized() + String(self.retryTime) + "/5",
                     type: .error)
    }
    
    
    public override func onWidgetRoomPropertiesDeleted(_ properties: [String : Any]?,
                                                       cause: [String : Any]?,
                                                       keyPaths: [String],
                                                       operatorUser: AgoraWidgetUserInfo?) {
        super.onWidgetRoomPropertiesDeleted(properties,
                                            cause: cause,
                                            keyPaths: keyPaths,
                                            operatorUser: operatorUser)
        
        analyzeGrantedUsersFromRoomProperties()
    }
    
    public override func onMessageReceived(_ message: String) {
        super.onMessageReceived(message)
        
        if let keys = message.toRequestKeys() {
            initServerAPI(keys: keys)
            return
        }
        
        if let signal = message.toBoardWidgetSignal() {
            switch signal {
            case .joinBoard:
                canJoin = true
                join()
            case .changeAssistantType(let assistantType):
                handleChangeAssistantType(type: assistantType)
            case .audioMixingStateChanged(let audioMixingData):
                handleAudioMixing(data: audioMixingData)
            case .updateGrantedUsers(let type):
                handleBoardGrant(type: type)
            case .boardStepChanged(let changeType):
                handleStepChange(changeType: changeType)
            case .clearBoard:
                mainWindow?.clean()
            case .saveBoard:
                handleSaveBoardImage()
            case .changeRatio:
                updateViewRatio()
            default:
                break
            }
        }
        
        guard let json = message.toDictionary() else {
            return
        }
        
        for key in json.keys {
            guard let json = ValueTransform(value: json[key],
                                            result: [String: Any].self) else {
                continue
            }
            
            switch key {
            case "openFile":
                openFile(json)
            default:
                break
            }
        }
    }
}

// MARK: - Private message handle
private extension FcrBoardWidget {
    func openFile(_ fileJson: [String: Any]) {
        guard let file = FcrCloudDriveFile.decode(fileJson) else {
            return
        }
        
        switch file.ext {
        case "mp3", "mp4":
            let mediaConfig = FcrBoardMediaSubWindowConfig(resourceUrl: file.url,
                                                           title: file.resourceName)
            mainWindow?.createMediaSubWindow(config: mediaConfig)
        case "png", "jpg", "jpeg":
            getImageFrame(url: file.url) { [weak self] (frame) in
                guard let `self` = self else {
                    return
                }
                
                self.mainWindow?.insertImage(resourceUrl: file.url,
                                             frame: frame)
            }
        default:
            if let config = file.createSubWindowConfig() {
                mainWindow?.createSubWindow(config: config)
            } else if let config = file.createSubWindowConfig2() {
                mainWindow?.createSubWindow2(config: config)
            }
        }
    }
    
    func getImageFrame(url: String,
                       success: @escaping ((CGRect) -> Void)) {
        DispatchQueue.global().async {
            guard let image = UIImage.create(with: url) else {
                return
            }
            
            DispatchQueue.main.async { [weak self] in
                guard let `self` = self else {
                    return
                }
                
                let scale = image.size.width / image.size.height
                
                var width: CGFloat = 400
                var height: CGFloat = (width / scale)
                
                let x = ((self.view.bounds.size.width - width) * 0.5)
                let y = ((self.view.bounds.size.height - height) * 0.5)
                
                let frame = CGRect(x: x,
                                   y: y,
                                   width: width,
                                   height: height)
                
                success(frame)
            }
        }
    }
    
    func handleChangeAssistantType(type: FcrBoardAssistantType) {
        guard let `mainWindow` = mainWindow else {
            return
        }
        
        switch type {
        case .tool(let fcrBoardAidType):
            mainWindow.selectTool(type: fcrBoardAidType.wrapperType)
        case .text(let fcrBoardTextInfo):
            guard let fcrColor = fcrBoardTextInfo.color.wrapperType else {
                return
            }
            mainWindow.inputText(fontSize: UInt16(fcrBoardTextInfo.size),
                                 color: fcrColor)
        case .shape(let fcrBoardShapeInfo):
            guard let fcrColor = fcrBoardShapeInfo.color.wrapperType else {
                return
            }
            mainWindow.drawShape(type: fcrBoardShapeInfo.type.wrapperType,
                                 lineWidth: UInt16(fcrBoardShapeInfo.width),
                                 color: fcrColor)
        }
    }
    
    func handleAudioMixing(data: FcrBoardAudioMixingData) {
        guard let `mainWindow` = mainWindow else {
            return
        }
        mainWindow.setMediaState(stateCode: data.stateCode,
                                 errorCode: data.errorCode)
    }
    
    func handleBoardGrant(type: FcrBoardGrantUsersChangeType) {
        let grantedUsersKey = "grantedUsers"
        
        switch type {
        case .add(let array):
            guard array.count > 0 else {
                return
            }
            
            var granedtUsers = [String: Bool]()
            
            for id in array {
                let key = "\(grantedUsersKey).\(id)"
                granedtUsers[key] = true
            }
            
            updateRoomProperties(granedtUsers,
                                 cause: nil,
                                 success: nil,
                                 failure: nil)
        case .delete(let array):
            guard array.count > 0 else {
                return
            }
            
            var keyPaths = [String]()
            
            for id in array {
                keyPaths.append("\(grantedUsersKey).\(id)")
            }
            
            deleteRoomProperties(keyPaths,
                                 cause: nil,
                                 success: nil,
                                 failure: nil)
        }
    }
    
    func handleStepChange(changeType: FcrBoardStepChangeType) {
        guard let `mainWindow` = mainWindow else {
            return
        }
        switch changeType {
        case .pre(let count):
            for _ in 0 ..< count {
                mainWindow.undo()
            }
        case .next(let count):
            for _ in 0 ..< count {
                mainWindow.redo()
            }
        default:
            break
        }
    }
    
    func handleSaveBoardImage() {
        guard let `mainWindow` = mainWindow else {
            return
        }
        
        // photo auth handle
        var photoAuthStatus = PHPhotoLibrary.authorizationStatus()
        
        if #available(iOS 14, *) {
            photoAuthStatus = PHPhotoLibrary.authorizationStatus(for: .addOnly)
        } else {
            // Fallback on earlier versions
            photoAuthStatus = PHPhotoLibrary.authorizationStatus()
        }
        
        guard photoAuthStatus == .authorized else {
            if #available(iOS 14, *) {
                PHPhotoLibrary.requestAuthorization(for: .addOnly) { status in
                    guard status != .authorized else {
                        return
                    }
                    self.sendMessage(signal: .onBoardSaveResult(.noAlbumAuth))
                }
            } else {
                // Fallback on earlier versions
                PHPhotoLibrary.requestAuthorization { status in
                    guard status != .authorized else {
                        return
                    }
                    self.sendMessage(signal: .onBoardSaveResult(.noAlbumAuth))
                }
            }
            return
        }
        
        AgoraLoading.loading(in: view)
        
        mainWindow.getAllWindowsSnapshotImageList(combinedCount: 10,
                                                  imageFolder: snapshotFolder) { [weak self] list in
            self?.saveImagesToPhotoLibrary(imagePathList: list)
        }
    }
}

// MARK: - Join
extension FcrBoardWidget {
    func join() {
        guard canJoin else {
            return
        }
        
        guard let config = info.roomProperties?.toObject(FcrBooardConfigOfExtra.self),
              boardRoom == nil
        else {
            return
        }
        
        // init
        let boardRegion = FcrBoardRegion(rawValue: config.boardRegion) ?? .cn
        let backgroundColor = UIConfig.netlessBoard.backgroundColor
        let room = FcrBoardRoom(appId: config.boardAppId,
                                region: boardRegion,
                                backgroundColor: backgroundColor,
                                logTube: self)
        
        room.delegate = self
        
        let ratio = view.ratio()
        
        let joinConfig = FcrBoardRoomJoinConfig(roomId: config.boardId,
                                                roomToken: config.boardToken,
                                                boardRatio: Float(ratio),
                                                hasOperationPrivilege: isTeacher,
                                                userId: info.localUserInfo.userUuid,
                                                userName: info.localUserInfo.userName)
        
        AgoraLoading.loading(in: view)
        
        joinBoardRoom(room,
                      config: joinConfig) { [weak self] mainWindow in
            guard let `self` = self else {
                return
            }
            
            AgoraLoading.hide()
            
            self.log(content: "join successfully",
                     extra: nil,
                     type: .info)
            
            self.mainWindow = mainWindow
            mainWindow.delegate = self
            mainWindow.logTube = self
            
            self.setUpInitialState()
        }
        
        boardRoom = room
    }
    
    func joinBoardRoom(_ room: FcrBoardRoom,
                       config: FcrBoardRoomJoinConfig,
                       success: @escaping (FcrBoardMainWindow) -> Void) {
        room.join(config: config,
                  superView: view,
                  success: success) { [weak room] error in
            guard let `room` = room else {
                return
            }
            
            self.joinBoardRoom(room,
                               config: config,
                               success: success)
            
            self.log(content: "join unsuccessfully",
                      extra: error.localizedDescription,
                      type: .error)
        }
    }
    
    func setUpInitialState() {
        if isTeacher {
            hasOperationPrivilege = true
        }
        
        initViews()
        ifNeedSetWindowAttributes()

        analyzeGrantedUsersFromRoomProperties()
    }
    
    func initViews() {
        guard info.localUserInfo.userRole != "observer" else {
            pageControl.agora_enable = false
            return
        }
        
        view.addSubview(pageControl)
        
        pageControl.addBtn.addTarget(self,
                                     action: #selector(onClickAddPage(_:)),
                                     for: .touchUpInside)
        pageControl.prevBtn.addTarget(self,
                                      action: #selector(onClickPrePage(_:)),
                                      for: .touchUpInside)
        pageControl.nextBtn.addTarget(self,
                                      action: #selector(onClickNextPage(_:)),
                                      for: .touchUpInside)
        
        view.addSubview(pageControl)
        
        pageControl.agora_enable = UIConfig.netlessBoard.pageControl.enable
        pageControl.agora_visible = hasOperationPrivilege
        
        pageControl.mas_makeConstraints { make in
            make?.left.equalTo()(view)?.offset()(UIDevice.current.agora_is_pad ? 15 : 12)
            make?.bottom.equalTo()(view)?.offset()(UIDevice.current.agora_is_pad ? -20 : -15)
            make?.height.equalTo()(UIDevice.current.agora_is_pad ? 34 : 32)
            make?.width.equalTo()(168)
        }
        
        guard let `mainWindow` = mainWindow else {
            return
        }
        
        let info = mainWindow.getPageInfo()
        
        pageControl.updatePage(index: Int(info.showIndex) + 1,
                               pages: Int(info.count))
    }
    
    func ifNeedSetWindowAttributes() {
        guard let `serverAPI` = serverAPI,
              let userProperties = info.localUserProperties,
              let isNeedSet = userProperties["initial"] as? Bool,
              isNeedSet == true else {
            return
        }
        
        serverAPI.getWindowAttributes { [weak self] (json) in
            guard let `self` = self,
                  let `mainWindow` = self.mainWindow else {
                return
            }
            
            if mainWindow.hasOperationPrivilege == true {
                mainWindow.setAttributes(json)
            } else {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                    guard let `self` = self else {
                        return
                    }
                    
                    self.ifNeedSetWindowAttributes()
                }
            }
        } failure: { [weak self] error in
            self?.ifNeedSetWindowAttributes()
        }
    }
}

// MARK: - Save images
private extension FcrBoardWidget {
    func saveImagesToPhotoLibrary(imagePathList: [String]) {
        DispatchQueue.main.async { [weak self] in
            guard let `self` = self else {
                return
            }
            self.imageCountToSave = imagePathList.count
            
            for path in imagePathList {
                guard let image = UIImage(contentsOfFile: path) else {
                    continue
                }
                
                UIImageWriteToSavedPhotosAlbum(image,
                                               self,
                                               #selector(self.onFinishSavingImage(image:error:contextInfo:)),
                                               nil)
            }
        }
    }
    
    @objc func onFinishSavingImage(image: UIImage,
                                   error: NSError?,
                                   contextInfo: UnsafeRawPointer?) {
        if let error = error {
          log(content: "save single image error",
              extra: error.description,
              type: .error)
        } else {
            log(content: "save single image successfully",
                extra: snapshotFolder,
                type: .info)
        }
        
        imageCountToSave -= 1
        
        guard imageCountToSave == 0 else {
            return
        }

        try? FileManager.default.removeItem(atPath: snapshotFolder)
        
        AgoraLoading.hide()
        
        sendMessage(signal: .onBoardSaveResult(.savedToAlbum))
      }
}

private extension FcrBoardWidget {
    func initServerAPI(keys: AgoraWidgetRequestKeys) {
        serverAPI = FcrBoardServerAPI(host: keys.host,
                                      appId: keys.agoraAppId,
                                      token: keys.token,
                                      roomId: info.roomInfo.roomUuid,
                                      userId: info.localUserInfo.userUuid,
                                      logTube: self.logger)
    }
    
    func updateViewRatio() {
        guard let `mainWindow` = mainWindow else {
            return
        }
        let ratio = Float(view.ratio())
        mainWindow.setContainerSizeRatio(ratio: ratio)
    }
    
    func sendMessage(signal: FcrBoardInteractionSignal) {
        guard let text = signal.toMessageString() else {
            log(content: "signal encode error!",
                type: .error)
            return
        }
        sendMessage(text)
    }
    
    func analyzeGrantedUsersFromRoomProperties() {
        guard let _ = mainWindow else {
            return
        }
        
        var grantedUsers = [String]()

        if let usageExtra = info.roomProperties?.toObject(FcrBooardUsageOfExtra.self) {
            grantedUsers = Array(usageExtra.grantedUsers.keys)
        }
        
        // 为保证逻辑，若本地为老师，将老师uuid加入grantedUsers中
        if isTeacher,
           !grantedUsers.contains(info.localUserInfo.userUuid) {
            grantedUsers.append(info.localUserInfo.userUuid)
        }
        
        var newLocalPrivilege = true
        
        if !isTeacher,
           !grantedUsers.contains(info.localUserInfo.userUuid) {
            newLocalPrivilege = false
        }
        
        var privilegeNeedChanged = (newLocalPrivilege != hasOperationPrivilege)
        
        guard privilegeNeedChanged else {
            sendMessage(signal: .getBoardGrantedUsers(grantedUsers))
            return
        }
        
        mainWindow?.updateOperationPrivilege(hasPrivilege: newLocalPrivilege,
                                             success: { [weak self] in
            guard let `self` = self else {
                return
            }
            
            self.log(content: "update operation privilege",
                     extra: "\(newLocalPrivilege)",
                     type: .info)
            
            self.hasOperationPrivilege = newLocalPrivilege
            self.sendMessage(signal: .getBoardGrantedUsers(grantedUsers))
        }, failure: { [weak self] error in
            guard let `self` = self else {
                return
            }
            self.log(content: "update operation privilege unsuccessfully",
                     extra: "\(newLocalPrivilege)",
                     type: .error)
        })
    }
}

// MARK: - Page control
extension FcrBoardWidget {
    func movePageControl(isRight: Bool) {
        UIView.animate(withDuration: TimeInterval.agora_animation,
                       delay: 0,
                       options: .curveEaseInOut,
                       animations: { [weak self] in
            guard let `self` = self else {
                return
            }
            let move: CGFloat = UIDevice.current.agora_is_pad ? 49 : 44
            self.pageControl.transform = CGAffineTransform(translationX: isRight ? move : 0,
                                                           y: 0)
        }, completion: nil)
    }
    
    @objc func onClickAddPage(_ sender: UIButton) {
        guard let `mainWindow` = mainWindow else {
            return
        }
        
        mainWindow.addPage { [weak mainWindow] finished in
            guard let window = mainWindow else {
                return
            }
            
            let info = window.getPageInfo()
            let index = (info.count)
            window.setPageIndex(index: index)
        }
    }
    
    @objc func onClickPrePage(_ sender: UIButton) {
        guard let `mainWindow` = mainWindow else {
            return
        }
        let showIndex: UInt16 = mainWindow.getPageInfo().showIndex
        let finalIndex: UInt16 = (showIndex > 1) ? (showIndex - 1) : 0
        mainWindow.setPageIndex(index: finalIndex)
    }
    
    @objc func onClickNextPage(_ sender: UIButton) {
        guard let `mainWindow` = mainWindow else {
            return
        }
        let index = mainWindow.getPageInfo().showIndex + 1
        mainWindow.setPageIndex(index: index)
    }
}

// MARK: - FcrBoardRoomDelegate
extension FcrBoardWidget: FcrBoardRoomDelegate {
    func onConnectionStateUpdated(state: FcrBoardRoomConnectionState) {
        let extra = state.agDescription
        
        switch state {
        case .connected:
            AgoraLoading.hide()
        case .reconnecting:
            AgoraLoading.loading(in: view)
        default:
            break
        }
    }
    func onSlideError(slideError: WhiteSlideErrorType, errorMessage: String, slideId: String, slideIndex: Int) {
        if(slideError == WhiteSlideErrorType.resourceError || slideError == WhiteSlideErrorType.canvasCrash){
            if(self.retryTime == 0){
                self.retry(slideId: slideId, slideIndex: slideIndex)
            }else if(self.retryTime < 5){
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                    self.retry(slideId: slideId, slideIndex: slideIndex)
                }
            }else{
                showToast("fcr_board_slide_retry_failure".localized(),
                             type: .error)
            }
        } else if(slideError == WhiteSlideErrorType.runtimeError){
            self.boardRoom?.recoverSlide(slideId: slideId, slideIndex: slideIndex + 1)
        } else if(slideError == WhiteSlideErrorType.runtimeWarn) {
            let slideExtra = ["slideId": slideId,
                                "slideIndex": slideIndex.agDescription]
            log(content: "slide page error",
                extra: slideExtra.agDescription, type: .warning,
                fromClass: WhiteSDK.self,
                funcName: "onSlideError")
        }
    }
}

// MARK: - FcrBoardMainWindowDelegate
extension FcrBoardWidget: FcrBoardMainWindowDelegate {
    func onPageInfoUpdated(info: FcrBoardPageInfo) {
        pageControl.updatePage(index: Int(info.showIndex) + 1,
                               pages: Int(info.count))
    }
    
    func onUndoStateUpdated(enable: Bool) {
        sendMessage(signal: .boardStepChanged(.undoAble(enable)))
    }
    
    func onRedoStateUpdated(enable: Bool) {
        sendMessage(signal: .boardStepChanged(.redoAble(enable)))
    }
    
    func onWindowBoxStateChanged(state: FcrWindowBoxState) {
        sendMessage(signal: .windowStateChanged(state.toWidget))
        movePageControl(isRight: (state == .mini))
    }
    
    func onStartAudioMixing(filePath: String,
                            loopback: Bool,
                            replace: Bool,
                            cycle: Int) {
        let data = FcrBoardAudioMixingStartData(filePath: filePath,
                                                loopback: loopback,
                                                replace: replace,
                                                cycle: cycle)
        let type = FcrBoardAudioMixingRequestType.start(data)
        sendMessage(signal: .boardAudioMixingRequest(type))
    }
    
    func onPauseAudioMixing() {
        let type = FcrBoardAudioMixingRequestType.pause
        sendMessage(signal:.boardAudioMixingRequest(type))
    }
    
    func onResumeAudioMixing() {
        let type = FcrBoardAudioMixingRequestType.resume
        sendMessage(signal:.boardAudioMixingRequest(type))
    }
    
    func onStopAudioMixing() {
        let type = FcrBoardAudioMixingRequestType.stop
        sendMessage(signal: .boardAudioMixingRequest(type))
    }
    
    func onAudioMixingPositionUpdated(position: Int) {
        let type = FcrBoardAudioMixingRequestType.setPosition(position)
        sendMessage(signal: .boardAudioMixingRequest(type))
    }
}

extension FcrBoardWidget: FcrBoardLogTube {
    func onBoardLog(content: String,
                    extra: String?,
                    type: FcrBoardLogType,
                    fromClass: AnyClass,
                    funcName: String,
                    line: Int) {
        log(content: content,
            extra: extra,
            type: type.toAgoraType,
            fromClass: fromClass,
            funcName: funcName,
            line: line)
    }
    
    func onNetlessLog(content: String,
                      extra: String?,
                      type: FcrBoardLogType) {
        log(content: content,
            extra: extra,
            type: type.toAgoraType)
    }
}

fileprivate extension String {
    static func currentTimeString() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd_HHmmss"
        return dateFormatter.string(from: Date())
    }
}

fileprivate extension UIView {
    func ratio() -> CGFloat {
        superview?.layoutIfNeeded()
        
        let width = bounds.width
        let height = bounds.height
        
        var ratio: CGFloat
        
        if width < 1 || height < 1 {
            ratio = (16.0 / 9.0)
        } else {
            ratio = height / width
        }
        
        return ratio
    }
}

fileprivate extension UIImage {
    static func create(with url: String) -> UIImage? {
        guard let urlObject = URL(string: url) else {
            return nil
        }
        
        guard let data = try? Data(contentsOf: urlObject) else {
            return nil
        }
        
        guard let image = UIImage(data: data) else {
            return nil
        }
        
        return image
    }
}

fileprivate extension FcrBoardLogType {
    var toAgoraType: AgoraLogType {
        switch self {
        case .info:     return .info
        case .warning:  return .warning
        case .error:    return .error
        }
    }
}

fileprivate extension Array where Element == FcrCloudDriveFile.TaskProgress.TaskProgressConvertedFile {
    func createPageList() -> [FcrBoardPage] {
        var list = [FcrBoardPage]()
        
        for item in self {
            list.append(item.createPage())
        }
        
        return list
    }
}

fileprivate extension Dictionary where Key == String, Value == FcrCloudDriveFile.TaskProgress.TaskProgressImage {
    func createPageList() -> [FcrBoardPage] {
        var list = [FcrBoardPage]()

        for (key, value) in self {
            let page = FcrBoardPage(name: key,
                                    contentUrl: value.url,
                                    contentWidth: value.width,
                                    contentHeight: value.height)
            list.append(page)
        }
        
        return list
    }
}

fileprivate extension FcrCloudDriveFile.TaskProgress.TaskProgressConvertedFile {
    func createPage() -> FcrBoardPage {
        let page = FcrBoardPage(name: name,
                                contentUrl: ppt.src,
                                previewUrl: ppt.preview,
                                contentWidth: ppt.width,
                                contentHeight: ppt.height)
        
        return page
    }
}

fileprivate extension FcrCloudDriveFile {
    func createSubWindowConfig() -> FcrBoardSubWindowConfig? {
        var resourceHasAnimation = false
        
        if let canvasVersion = conversion?.canvasVersion,
           canvasVersion == true {
            resourceHasAnimation = true
        }
        
        var pageList: [FcrBoardPage]
        
        if let list = taskProgress?.convertedFileList?.createPageList(),
           list.count > 0 {
            
            pageList = list
        } else if let list = taskProgress?.images?.createPageList(),
                  list.count > 0 {
            
            pageList = list
        } else {
            return nil
        }
        
        let config = FcrBoardSubWindowConfig(resourceUuid: resourceUuid,
                                             resourceHasAnimation: resourceHasAnimation,
                                             title: resourceName,
                                             pageList: pageList)
        
        return config
    }
    
    func createSubWindowConfig2() -> FcrBoardSubWindowConfig2? {
        guard let prefix = taskProgress?.prefix,
              let `taskUuid` = taskUuid
        else {
            return nil
        }
        
        let config = FcrBoardSubWindowConfig2(resourceUuid: resourceUuid,
                                              taskUuid: taskUuid,
                                              title: resourceName,
                                              prefix: prefix)
        
        return config
    }
}
