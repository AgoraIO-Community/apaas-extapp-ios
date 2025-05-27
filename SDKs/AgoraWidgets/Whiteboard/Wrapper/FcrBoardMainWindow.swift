//
//  FcrBoardMainWindow.swift
//  AgoraWidgets
//
//  Created by Cavan on 2022/6/6.
//

import Foundation
import Whiteboard

class FcrBoardMainWindow: NSObject {
    private weak var whiteSDK: WhiteSDK?
    
    var whiteRoom: WhiteRoom {
        didSet {
            let extra = ["whiteRoom": whiteRoom.description]
            
            log(content: "reset whiteRoom object",
                extra: extra.agDescription,
                type: .info)
            
            setUpNetless()
        }
    }
    
    private var currentScenePath: String?
    
    private var memberState: WhiteMemberState
    
    private(set) var hasOperationPrivilege: Bool
    
    private var isUpdatingPrivilege = false
    
    weak var delegate: FcrBoardMainWindowDelegate?
    
    weak var logTube: FcrBoardLogTube?
    
    let contentView: UIView
    
    init(whiteView: WhiteBoardView,
         whiteSDK: WhiteSDK,
         whiteRoom: WhiteRoom,
         hasOperationPrivilege: Bool) {
        self.contentView = whiteView
        self.whiteRoom = whiteRoom
        self.whiteSDK = whiteSDK
        self.hasOperationPrivilege = hasOperationPrivilege
        
        self.memberState = WhiteMemberState()
        self.memberState.currentApplianceName = WhiteApplianceNameKey.ApplianceClicker

        let defaultColor = FcrColor(red: 0,
                                    green: 115,
                                    blue: 255)
        self.memberState.strokeColor = defaultColor.toNetlessValue
        
        super.init()
        
        let extra = ["whiteView": whiteView.description,
                     "whiteRoom": whiteRoom.description,
                     "hasOperationPrivilege": hasOperationPrivilege.agDescription,
                     "memberState": memberState.agDescription]
        
        log(content: "init mainWindow",
            extra: extra.agDescription,
            type: .info)
        
        setUpNetless()
    }
}

extension FcrBoardMainWindow {
    func getPageInfo() -> FcrBoardPageInfo {
        guard let pageState = whiteRoom.state.pageState else {
            return FcrBoardPageInfo(showIndex: 0,
                                    count: 1)
        }
        
        log(content: "get page state",
            extra: pageState.agDescription,
            type: .info,
            fromClass: WhiteRoom.self,
            funcName: "state.pageState")
        
        let info = FcrBoardPageInfo(showIndex: UInt16(pageState.index),
                                    count: UInt16(pageState.length))
        
        log(content: "get page state",
            extra: info.agDescription,
            type: .info)
        
        return info
    }
    
    /// 获取窗口属性（课件信息）
    func getAttributes(result: @escaping (([AnyHashable: Any]) -> Void)) {
        log(content: "get attributes",
            extra: nil,
            type: .info)
        
        whiteRoom.getWindowManagerAttributes { attributes in
            result(attributes)
        }
    }
    
    /// 设置窗口属性（课件信息）
    func setAttributes(_ attributes: [AnyHashable: Any]) {
        log(content: "set attributes",
            extra: attributes.debugDescription,
            type: .info)
        
        whiteRoom.setWindowManagerWithAttributes(attributes)
        
        log(content: "is writable",
            extra: "isWritable: \(whiteRoom.isWritable)",
            type: .info,
            fromClass: WhiteRoom.self)
        
        log(content: "set attributes",
            extra: attributes.debugDescription,
            type: .info,
            fromClass: WhiteRoom.self)
    }
    
    func setMediaState(stateCode: Int,
                       errorCode: Int) {
        guard let audioMixer = whiteSDK?.audioMixer else {
            return
        }
        
        let extra = ["stateCode: \(stateCode)",
                     "errorCode: \(errorCode)"]
        
        log(content: "set media state",
            extra: extra.agDescription,
            type: .info,
            fromClass: WhiteAudioMixerBridge.self,
            funcName: "setMediaState")
        
        audioMixer.setMediaState(stateCode,
                                 errorCode: errorCode)
    }
    
    func registerH5SubWindow(config: FcrBoardH5RegisterWindowConfig) -> FcrBoardError? {
        guard let whiteSDK = whiteSDK else {
            return FcrBoardError.sdkNil
        }
        
        var appParams: WhiteRegisterAppParams?
        if config.resource.isValidUrl {
            appParams = WhiteRegisterAppParams(url: config.resource,
                                               kind: "Talkative",
                                               appOptions: [:])
        } else if let bundle = Bundle.agora_bundle("AgoraWidgets"),
                  let javascriptPath = bundle.path(forResource: "app-talkative",
                                                   ofType: "js"),
                  let javascriptString = try? String(contentsOfFile: javascriptPath,
                                                     encoding: .utf8) {
            appParams = WhiteRegisterAppParams(javascriptString: javascriptString,
                                                   kind: "Talkative",
                                                   appOptions: [:],
                                                   variable: "NetlessAppTalkative.default")
        }
        
        guard let appParams = appParams else {
            log(content: "register H5 subWindow params error",
                extra: config.agDescription,
                type: .error)
            return FcrBoardError(code: -1,
                                 message: "registerH5SubWindow params error")
        }
        
        whiteSDK.registerApp(with: appParams,
                             completionHandler: { [weak self] error in
            if let `error` = error {
                self?.log(content: "register H5 subWindow error",
                          extra: error.localizedDescription,
                          type: .error)
                return
            }
            self?.log(content: "register H5 subWindow successfully",
                      extra: config.agDescription,
                      type: .info)
        })
        return nil
    }
    
    func insertImage(resourceUrl: String,
                     frame: CGRect) {
        let extra = ["resourceUrl: \(resourceUrl)",
                     "frame: \(frame.debugDescription)"]
        
        log(content: "inser image",
            extra: extra.agDescription,
            type: .info)
        
        let uuid = resourceUrl.agora_md5()
        
        let event = WhitePanEvent()
        event.x = frame.origin.x
        event.y = frame.origin.y
        
        whiteRoom.convertToPoint(inWorld: event) { [weak self] event in
            guard let `self` = self else {
                return
            }
            
            let newFrame = CGRect(x: event.x,
                                  y: event.y,
                                  width: frame.width,
                                  height: frame.height)
            
            let info = WhiteImageInformation(uuid: uuid,
                                             frame: newFrame)
            
            var extra = ["uuid: \(uuid)",
                         "frame: \(frame.debugDescription)"]
            
            self.log(content: "insert image",
                     extra: extra.agDescription,
                     type: .info,
                     fromClass: WhiteRoom.self,
                     funcName: "insertImage")
            
            self.whiteRoom.insertImage(info,
                                       src: resourceUrl)
            
            extra = ["uuid: \(uuid)",
                     "src: \(resourceUrl)"]
            
            self.log(content: "complete image upload",
                     extra: extra.agDescription,
                     type: .info,
                     fromClass: WhiteRoom.self,
                     funcName: "completeImageUpload")
            
            self.whiteRoom.completeImageUpload(withUuid: uuid,
                                               src: resourceUrl)
        }
    }
    
    func getAllWindowsSnapshotImageList(combinedCount: UInt8,
                                        imageFolder: String,
                                        imageListPath: @escaping (([String]) -> Void)) {
        let combined = (Int(combinedCount) > 0) ? Int(combinedCount) : 1
        
        let extra = ["combinedCount": "\(combinedCount)",
                     "imageFolder": imageFolder]
        
        log(content: "get all windows snapshot image list",
            extra: extra.agDescription,
            type: .info)
        
        log(content: "get entire scenes",
            type: .info,
            fromClass: WhiteRoom.self,
            funcName: "getEntireScenes")
        
        // Pre: folder create
        if !FileManager.default.fileExists(atPath: imageFolder,
                                           isDirectory: nil) {
            try? FileManager.default.createDirectory(atPath: imageFolder,
                                                     withIntermediateDirectories: true,
                                                     attributes: nil)
        }
        
        // Step1: 获取所有白板scene的scenePath
        whiteRoom.getEntireScenes({ [weak self] scenesMap in
            let key = "/"
            guard let `self` = self,
                  let sceneList = scenesMap[key],
                  sceneList.count > 0 else {
                return
            }
            
            var paths = [String]()
            
            for scene in sceneList {
                paths.append("\(key)\(scene.name)")
            }
            
            let netlessExtra = ["whiteScenePaths": sceneList.agDescription]
            
            self.log(content: "white scene paths",
                     extra: extra.agDescription,
                     type: .info,
                     fromClass: WhiteRoom.self,
                     funcName: "getEntireScenes")
            
            // Step2: 处理所有paths截图及合并
            self.handleSnaptshotWithScenePaths(paths,
                                               imageFolder: imageFolder,
                                               combinedCount: combined,
                                               combinedPaths: imageListPath)
        })
    }
    
    func setContainerSizeRatio(ratio: Float) -> Error? {
        let extra = ["ratio: \(ratio.agDescription)"]
        
        log(content: "set container size ratio",
            extra: extra.agDescription,
            type: .info)
                
        log(content: "set container size ratio",
            extra: extra.agDescription,
            type: .info,
            fromClass: WhiteRoom.self,
            funcName: "setContainerSizeRatio")
        
        // WhiteCameraState
        let camera = whiteRoom.state.cameraState
        
        let number: NSNumber = NSNumber(value: ratio)
        whiteRoom.setContainerSizeRatio(number)
        
        let config = WhiteCameraConfig()
        config.centerX = camera?.centerX
        config.centerY = camera?.centerY
        config.scale = camera?.scale
        
        whiteRoom.moveCamera(config)
        
        return nil
    }
    
    func updateOperationPrivilege(hasPrivilege: Bool,
                                  success: @escaping () -> Void,
                                  failure: @escaping (Error) -> Void) {
        guard !isUpdatingPrivilege else {
            return
        }
        isUpdatingPrivilege = true
        
        let extra = ["hasPrivilege": hasPrivilege.agDescription]
        
        log(content: "update operation privilege",
            extra: extra.agDescription,
            type: .info)
        
        let netlessExtra = ["writable": hasPrivilege.agDescription]
        
        log(content: "set writable",
            extra: extra.agDescription,
            type: .info,
            fromClass: WhiteRoom.self,
            funcName: "setWritable")
        
        whiteRoom.setWritable(hasPrivilege) { [weak self] (isWritable,
                                                           error) in
            self?.isUpdatingPrivilege = false
            // Failure
            guard let `self` = self else {
                let error = NSError.defaultError()
                failure(error)
                return
            }
            
            let netlessExtra = ["isWritable": isWritable.agDescription,
                                "error": StringIsEmpty(error?.localizedDescription)]
            
            let logType: FcrBoardLogType = (error == nil ? .info : .error)
            
            self.log(content: "set writable callback",
                     extra: extra.agDescription,
                     type: logType,
                     fromClass: WhiteRoom.self,
                     funcName: "setWritableCallback")
            
            guard error == nil else {
                
                let `error` = NSError.create(error)
                
                let extra = ["error": error.localizedDescription]
                
                failure(error)
                
                self.log(content: "update operation privilege failure",
                         extra: extra.agDescription,
                         type: .error)
                
                return
            }
            
            // Success
            if isWritable {
                self.whiteRoom.disableSerialization(false)
            }
            let disable = !isWritable
            self.whiteRoom.disableDeviceInputs(disable)
            
            let extra = ["disable": disable.agDescription]
            
            self.log(content: "disable device inputs",
                     extra: extra.agDescription,
                     type: .info,
                     fromClass: WhiteRoom.self,
                     funcName: "disableDeviceInputs")
            
            self.log(content: "update operation privilege success",
                     type: .info)
            
            self.hasOperationPrivilege = hasPrivilege
            
            success()
        }
    }
    
    func addPage(completion: ((Bool) -> ())? = nil) -> FcrBoardError? {
        log(content: "add page",
            type: .info)
        
        log(content: "add page",
            type: .info,
            fromClass: WhiteRoom.self,
            funcName: "addPage")

        whiteRoom.addPage(completion)
        
        return nil
    }
    
    func removePage() -> FcrBoardError? {
        let extra = ["currentPage": getPageInfo().agDescription]
        
        let content = "remove page"
        
        log(content: content,
            extra: extra.agDescription,
            type: .info)
        
        log(content: content,
            extra: extra.agDescription,
            type: .info,
            fromClass: WhiteRoom.self,
            funcName: "removePage")
        
        whiteRoom.removePage { [weak self] isSuccess in
            var logType: FcrBoardLogType
            var text: String
            
            if isSuccess {
                logType = .info
                text = content
            } else {
                logType = .error
                text = content + " failure"
            }
            
            self?.log(content: text,
                      extra: extra.agDescription,
                      type: logType)
        }
        
        return nil
    }
    
    func setPageIndex(index: UInt16) {
        var extra = ["index": index.agDescription]
        
        log(content: "set page index",
            extra: extra.agDescription,
            type: .info)
        
        log(content: "set page index",
            extra: extra.agDescription,
            type: .info,
            fromClass: WhiteRoom.self,
            funcName: "setSceneIndex")
        
        whiteRoom.setSceneIndex(UInt(index)) { [weak self] (isSuccess,
                                                            error) in
            guard let `self` = self else {
                return
            }
            
            if let `error` = error {
                extra["error"] = error.localizedDescription
            }
            
            let isResult = (isSuccess ? "success" : "failure")
            let content = ("set scene index " + isResult)
            
            let logType: FcrBoardLogType = (isSuccess ? .info : .error)
            
            self.log(content: content,
                     extra: extra.agDescription,
                     type:  logType,
                     fromClass: WhiteRoom.self,
                     funcName: "setSceneIndexCallback")
        }
    }
    
    func undo() -> FcrBoardError? {
        log(content: "undo",
            type: .info)
        
        log(content: "undo",
            type: .info,
            fromClass: WhiteRoom.self,
            funcName: "undo")
        
        whiteRoom.undo()
        
        return nil
    }
    
    func redo() -> FcrBoardError? {
        log(content: "redo",
            type: .info)
        
        log(content: "redo",
            type: .info,
            fromClass: WhiteRoom.self,
            funcName: "undo")
        
        whiteRoom.redo()
        return nil
    }
    
    func clean() -> FcrBoardError? {
        log(content: "clean",
            type: .info)
        
        let retain = true
        whiteRoom.cleanScene(retain)
        
        let extra = ["retain": retain.agDescription]
        
        log(content: "clean",
            extra: extra.agDescription,
            type: .info,
            fromClass: WhiteRoom.self,
            funcName: "undo")
        return nil
    }
    
    func createSubWindow(config: FcrBoardSubWindowConfig) {
        var extra = ["config": config.agDescription]
        
        log(content: "create sub window",
            extra: extra.agDescription,
            type: .info)
        
        let scenes = config.pageList.toNetlessValue
        
        var whiteParam: WhiteAppParam
        
        if config.resourceHasAnimation {
            whiteParam = WhiteAppParam.createSlideApp("/\(config.resourceUuid)",
                                                      scenes: scenes,
                                                      title: config.title)
        } else {
            whiteParam = WhiteAppParam.createDocsViewerApp("/\(config.resourceUuid)",
                                                           scenes: scenes,
                                                           title: config.title)
        }
        
        whiteRoom.addApp(whiteParam) { [weak self] (subWindowId) in
            let extra = ["subWindowId": subWindowId]
            
            self?.log(content: "addAppCallback",
                      extra: extra.agDescription,
                      type: .info)
        }
        
        let appParams = ["dir": config.resourceUuid,
                         "scenes": scenes.agDescription,
                         "title": config.title]
        
        extra = ["appParams": appParams.agDescription]
        
        log(content: "add app",
            extra: extra.agDescription,
            type: .info,
            fromClass: WhiteRoom.self,
            funcName: "addApp")
    }
    
    func createSubWindow2(config: FcrBoardSubWindowConfig2) {
        var extra = ["config": config.agDescription]
        
        log(content: "create sub window 2",
            extra: extra.agDescription,
            type: .info)
        
        let whiteParam = WhiteAppParam.createSlideApp("/\(config.resourceUuid)",
                                                      taskId: config.taskUuid,
                                                      url: config.prefix,
                                                      title: config.title)
        
        whiteRoom.addApp(whiteParam) { [weak self] (subWindowId) in
            let extra = ["subWindowId": subWindowId]
            
            self?.log(content: "addAppCallback",
                      extra: extra.agDescription,
                      type: .info)
        }
        
        let appParams = ["dir": config.resourceUuid,
                         "taskId": config.taskUuid,
                         "url": config.prefix,
                         "title": config.title]
        
        extra = ["appParams": appParams.agDescription]
        
        log(content: "add app",
            extra: extra.agDescription,
            type: .info,
            fromClass: WhiteRoom.self,
            funcName: "addApp")
    }
    
    func createMediaSubWindow(config: FcrBoardMediaSubWindowConfig) {
        var extra = ["config": config.agDescription]
        
        log(content: "create media sub window",
            extra: extra.agDescription,
            type: .info)
        
        let whiteParam = WhiteAppParam.createMediaPlayerApp(config.resourceUrl,
                                                            title: config.title)
        
        whiteRoom.addApp(whiteParam) { [weak self] (subWindowId) in
            let extra = ["subWindowId": subWindowId]
            
            self?.log(content: "addAppCallback",
                      extra: extra.agDescription,
                      type: .info)
        }
        
        let appParams = ["src": config.resourceUrl,
                         "title": config.title]
        
        extra = ["appParams": appParams.agDescription]
        
        log(content: "add app",
            extra: extra.agDescription,
            type: .info,
            fromClass: WhiteRoom.self,
            funcName: "addApp")
    }
    
    func createH5SubWindow(config: FcrBoardH5SubWindowConfig) {
        var extra = ["config": config.agDescription]
        
        log(content: "create H5 sub window",
            extra: extra.agDescription,
            type: .info)
        
        let options = WhiteAppOptions()
        options.title = config.title
        let attrs = ["src": config.resourceUrl]
        let whiteParam = WhiteAppParam(kind: "Talkative",
                                       options: options,
                                       attrs: attrs)
        
        whiteRoom.addApp(whiteParam) { [weak self] (subWindowId) in
            let extra = ["subWindowId": subWindowId]
            
            self?.log(content: "addAppCallback",
                      extra: extra.agDescription,
                      type: .info)
        }
        
        let appParams = ["src": config.resourceUrl,
                         "title": config.title]
        
        extra = ["appParams": appParams.agDescription]
        
        log(content: "add app",
            extra: extra.agDescription,
            type: .info,
            fromClass: WhiteRoom.self,
            funcName: "addApp")
        
    }
    
    func selectTool(type: FcrBoardToolType) {
        var extra = ["type": type.agDescription]
        
        log(content: "select tool",
            extra: extra.agDescription,
            type: .info)
        
        memberState.currentApplianceName = type.toNetlessValue
        whiteRoom.setMemberState(memberState)
        
        extra = ["memberState": memberState.agDescription]
        
        log(content: "set member state",
            extra: extra.agDescription,
            type: .info,
            fromClass: WhiteRoom.self,
            funcName: "setMemberState")
    }
    
    func inputText(fontSize: UInt16,
                   color: FcrColor) {
        var extra = ["fontSize": fontSize.agDescription,
                     "color": color.agDescription]
        
        log(content: "input text",
            extra: extra.agDescription,
            type: .info)
        
        memberState.currentApplianceName = .ApplianceText
        memberState.strokeColor = color.toNetlessValue
        memberState.textSize = NSNumber.init(value: fontSize)
        whiteRoom.setMemberState(memberState)
        
        extra = ["memberState": memberState.agDescription]
        
        log(content: "set member state",
            extra: extra.agDescription,
            type: .info,
            fromClass: WhiteRoom.self,
            funcName: "setMemberState")
    }
    
    func drawShape(type: FcrBoardDrawShape,
                   lineWidth: UInt16,
                   color: FcrColor) {
        var extra = ["lineWidth": lineWidth.agDescription,
                     "color": color.agDescription,
                     "type": type.agDescription]
        
        log(content: "draw shape",
            extra: extra.agDescription,
            type: .info)
        
        if let value = type.toNetlessValue {
            memberState.currentApplianceName = value
        }
        
        if let value = type.toNetlessType {
            memberState.shapeType = value
        }
        
        memberState.strokeColor = color.toNetlessValue
        memberState.strokeWidth = NSNumber.init(value: lineWidth)
        whiteRoom.setMemberState(memberState)
        
        extra = ["memberState": memberState.agDescription]
        
        log(content: "set member state",
            extra: extra.agDescription,
            type: .info,
            fromClass: WhiteRoom.self,
            funcName: "setMemberState")
    }
}

// MARK: - private
private extension FcrBoardMainWindow {
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
    
    func setUpNetless() {
        let viewMode: WhiteViewMode = .broadcaster
        whiteRoom.setViewMode(viewMode)
        
        log(content: "set view mode",
            extra: memberState.agDescription,
            type: .info,
            fromClass: WhiteRoom.self,
            funcName: "setViewMode")
        
        guard whiteRoom.isWritable else {
            return
        }
        let disableSerialization = false
        let disableCamera = true
        
        whiteRoom.setMemberState(memberState)
        whiteRoom.disableSerialization(false)
        
        log(content: "set member state",
            extra: memberState.agDescription,
            type: .info,
            fromClass: WhiteRoom.self,
            funcName: "setMemberState")
        
        log(content: "disable serialization",
            extra: disableSerialization.agDescription,
            type: .info,
            fromClass: WhiteRoom.self,
            funcName: "disableSerialization")
        
        log(content: "disable camera transform",
            extra: disableCamera.agDescription,
            type: .info,
            fromClass: WhiteRoom.self,
            funcName: "disableCameraTransform")
    }
    
    func handleSnaptshotWithScenePaths(_ paths: [String],
                                       imageFolder: String,
                                       combinedCount: Int,
                                       combinedPaths: @escaping (([String]) -> Void)) {
        var pathsToSnapshot = paths
        var snapshotImages = [UIImage]()
        var combinedSnapshotImages = [UIImage]()
        
        let completion = { [weak self] in
            guard let self = self else {
                return
            }
            var finalPaths = [String]()
            for (index,image) in combinedSnapshotImages.enumerated() {
                let filePath = imageFolder.appendingPathComponent("\(index)")
                guard let combinedfilePath = self.saveImage(filePath: filePath,
                                                            image: image) else {
                    continue
                }
                finalPaths.append(combinedfilePath)
            }
            combinedSnapshotImages.removeAll()
            combinedPaths(finalPaths)
        }
        
        func getSingleSnapshot(combinedCount: Int,
                               completion: @escaping (()-> Void)) {
            guard let scenePath = pathsToSnapshot.first else {
                if let combinedImage = self.combineSnapshotImages(snapshotImages) {
                    combinedSnapshotImages.append(combinedImage)
                }
                snapshotImages.removeAll()
                // 出递归
                completion()
                return
            }
            whiteRoom.getSceneSnapshotImage(scenePath) { [weak self] image in
                guard let `self` = self else {
                    return
                }
                // actually execute
                pathsToSnapshot.removeFirst()
                
                if let img = image {
                    snapshotImages.append(img)
                }
                
                if snapshotImages.count == combinedCount,
                   let combinedImage = self.combineSnapshotImages(snapshotImages) {
                    combinedSnapshotImages.append(combinedImage)
                    snapshotImages.removeAll()
                }
                
                getSingleSnapshot(combinedCount: combinedCount,
                                       completion: completion)
            }
        }
        // 递归
        getSingleSnapshot(combinedCount: combinedCount,
                          completion: completion)
    }
    
    func combineSnapshotImages(_ snapshotImages: [UIImage]) -> UIImage? {
        guard snapshotImages.count > 0 else {
            return nil
        }
        var width: CGFloat = 0
        var height: CGFloat = 0
        
        for image in snapshotImages {
            width = (image.size.width > width) ? image.size.width : width
            height += image.size.height
        }
        
        UIGraphicsBeginImageContext(CGSize(width: width,
                                           height: height))
        var imageY: CGFloat = 0
        
        for image in snapshotImages {
            image.draw(at: CGPoint(x: 0,
                                   y: imageY))
            imageY += image.size.height
        }
        
        let drawImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return drawImage
    }
    
    func saveImage(filePath: String,
                   image: UIImage?) -> String? {
        guard let image = image,
              let data = image.jpegData(compressionQuality: 0.5) else {
            return nil
        }
        let extra = ["filePath": filePath]
        log(content: "save snapshot combined image",
            extra: extra.agDescription,
            type: .info)
        
        let fileUrl = URL(fileURLWithPath: filePath)
        try? data.write(to: fileUrl)
        return filePath
    }
}

// MARK: - FcrBoardMainWindowNeedObserve
extension FcrBoardMainWindow: FcrBoardMainWindowNeedObserve {
    func onRoomStateChanged(_ modifyState: WhiteRoomState) {
        var extra = [String: String]()
        
        if let scenePath = modifyState.sceneState?.scenePath {
            extra["scenePath"] = scenePath
            log(content: "on room state changed",
                extra: extra.agDescription,
                type: .info)
            
            currentScenePath = scenePath
        }
        
        if let pageState = modifyState.pageState {
            extra["pageState"] = pageState.agDescription
            
            delegate?.onPageInfoUpdated(info: pageState.toFcr)
        }
        
        if let windowBoxState = modifyState.windowBoxState {
            extra["windowBoxState"] = windowBoxState.agDescription
            
            delegate?.onWindowBoxStateChanged(state: windowBoxState.toFcr)
        }
        
        if let cameraState = modifyState.cameraState {
            extra["cameraState"] = cameraState.agDescription
        }
        
        log(content: "on room state changed",
            extra: extra.agDescription,
            type: .info)
    }
    
    func onCanRedoStepsUpdate(_ canRedoSteps: Int) {
        var extra = ["canRedoSteps": canRedoSteps.agDescription]
        
        log(content: "on can redo steps update",
            extra: extra.agDescription,
            type: .info,
            fromClass: WhiteSDK.self,
            funcName: "fireCanRedoStepsUpdate")
        
        let enable = (canRedoSteps > 0)
        
        extra = ["enable": enable.agDescription]
        
        log(content: "on redo state updated",
            extra: extra.agDescription,
            type: .info)
        
        delegate?.onRedoStateUpdated(enable: enable)
    }
    
    func onCanUndoStepsUpdate(_ canUndoSteps: Int) {
        var extra = ["canUndoSteps": canUndoSteps.agDescription]
        
        log(content: "on can undo steps update",
            extra: extra.agDescription,
            type: .info,
            fromClass: WhiteSDK.self,
            funcName: "fireCanUndoStepsUpdate")
        
        let enable = (canUndoSteps > 0)
        
        extra = ["enable": enable.agDescription]
        
        log(content: "on undo state updated",
            extra: extra.agDescription,
            type: .info)
        
        delegate?.onUndoStateUpdated(enable: enable)
    }
    
    func onStartAudioMixing(filePath: String,
                            loopback: Bool,
                            replace: Bool,
                            cycle: Int) {
        let extra = ["filePath": filePath,
                     "loopback": loopback.agDescription,
                     "replace": replace.agDescription,
                     "cycle": cycle.agDescription]
        
        log(content: "on start audio mixing",
            extra: extra.agDescription,
            type: .info)
        
        delegate?.onStartAudioMixing(filePath: filePath,
                                     loopback: loopback,
                                     replace: replace,
                                     cycle: cycle)
    }
    
    func onPauseAudioMixing() {
        log(content: "on pause audio mixing",
            type: .info)
        
        delegate?.onPauseAudioMixing()
    }
    
    func onResumeAudioMixing() {
        log(content: "on resume audio mixing",
            type: .info)
        
        delegate?.onResumeAudioMixing()
    }
    
    func onStopAudioMixing() {
        log(content: "on stop audio mixing",
            type: .info)
        
        delegate?.onStopAudioMixing()
    }
    
    func onAudioMixingPositionUpdated(position: Int) {
        let extra = ["position": position.agDescription]
        
        log(content: "on audio mixing position updated",
            extra: extra.agDescription,
            type: .info)
        
        delegate?.onAudioMixingPositionUpdated(position: position)
    }
}
