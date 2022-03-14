//
//  AgoraCountdownWidget.swift
//  AgoraWidgets
//
//  Created by LYY on 2022/3/5.
//

import Armin
import Masonry
import AgoraLog
import AgoraWidget

@objcMembers public class AgoraCountdownTimerWidget: AgoraBaseWidget {
    /**Data**/
    private var logger: AgoraLogger
    
    /**View**/
    private var countdownView: AgoraCountdownView!

    private var curExtra: AgoraCountdownExtraModel? {
        didSet {
            handleRoomProperties()
        }
    }
    
    public override init(widgetInfo: AgoraWidgetInfo) {
        let cachesFolder = NSSearchPathForDirectoriesInDomains(.cachesDirectory,
                                                               .userDomainMask,
                                                               true)[0]
        let logFolder = cachesFolder.appending("/AgoraLog")
        let manager = FileManager.default
        
        if !manager.fileExists(atPath: logFolder,
                               isDirectory: nil) {
            try? manager.createDirectory(atPath: logFolder,
                                         withIntermediateDirectories: true,
                                         attributes: nil)
        }
        self.logger = AgoraLogger(folderPath: logFolder,
                                  filePrefix: widgetInfo.widgetId,
                                  maximumNumberOfFiles: 5)
        
        super.init(widgetInfo: widgetInfo)
    }
    
    // MARK: widget callback
    public override func onWidgetDidLoad() {
        countdownView = AgoraCountdownView(frame: .zero)
        
        if isTeacher {
            
        } else {
            view.addSubview(countdownView)
            countdownView.mas_makeConstraints { make in
                make?.left.right()?.top()?.bottom().equalTo()(0)
            }
        }
        
        if let roomProps = info.roomProperties,
           let countdownExtraModel = roomProps.toObj(AgoraCountdownExtraModel.self) {
            curExtra = countdownExtraModel
        }
        
        initViews()
        updateViewFrame()
    }
    
    public override func onWidgetRoomPropertiesUpdated(_ properties: [String : Any],
                                                       cause: [String : Any]?,
                                                       keyPaths: [String]) {
        if let countdownExtraModel = properties.toObj(AgoraCountdownExtraModel.self) {
            curExtra = countdownExtraModel
        }
    }
    
    public override func onMessageReceived(_ message: String) {
        logInfo("onMessageReceived:\(message)")
        
        if let tsDic = message.toDic() ,
           let syncTimestamp = tsDic["syncTimestamp"] as? Int64 {
            countdownView.invokeCountDown(duration: calculateCountdown(curTs: syncTimestamp))
        }
        
        if let signal = message.toCountdownSignal() {
            // TODO: 教师更新frame，需要updateRoomProps
            switch signal {
            case .sendTimestamp(let ts):
                countdownView.invokeCountDown(duration: calculateCountdown(curTs: ts))
            default:
                break
            }
        }
    }
    
    deinit {
        countdownView.cancelCountDown()
    }
}

// MARK: - private
private extension AgoraCountdownTimerWidget {
    func initViews() {
        view.layer.shadowColor = UIColor(hexString: "#2F4192")?.cgColor
        view.layer.shadowOffset = CGSize(width: 0,
                                         height: 2)
        view.layer.shadowOpacity = 0.15
        view.layer.shadowRadius = 6
        view.isHidden = true
    }
    
    func updateViewFrame() {
        let size = ["width": countdownView.neededSize.width,
                    "height": countdownView.neededSize.height]
        
        guard let message = ["size": size].jsonString() else {
            return
        }
        
        sendMessage(message)
        
        DispatchQueue.main.async {
            self.countdownView.afterLayout()
            self.view.isHidden = false
        }
    }
    
    func handleRoomProperties() {
        guard let extra = curExtra else {
            return
        }
        if isTeacher {
            
        } else {
            switch extra.state {
            case .during:
                sendMessage(.getTimestamp)
                break
            case .initial:
                countdownView.cancelCountDown()
            default:
                break
            }
        }
    }
    
    // 根据服务端ts，extra的startTime及duration，计算出UI开始的倒计时
    func calculateCountdown(curTs: Int64) -> Int64 {
        guard let extra = curExtra else {
            return 0
        }
        let timeGap = (curTs - extra.startTime) / 1000
        let gap = (timeGap < 0) ? 0 : timeGap
        let duration = extra.duration - gap
        return (duration < 0) ? 0 : duration
    }
    
    func sendMessage(_ signal: AgoraCountdownInteractionSignal) {
        guard let text = signal.toMessageString() else {
            logError("signal encode error!")
            return
        }
        sendMessage(text)
    }
    
    func logInfo(_ log: String) {
        logger.log("[CountdownTimer Widget \(info.widgetId)] \(log)",
                   type: .info)
    }
    
    func logError(_ log: String) {
        logger.log("[CountdownTimer Widget \(info.widgetId)] \(log)",
                   type: .error)
    }
}
