//
//  AgoraWebViewWidget.swift
//  AgoraWidgets
//
//  Created by DoubleCircle on 2022/5/24.
//

import AgoraWidget

@objcMembers public class AgoraWebViewWidget: AgoraBaseWidget, AgoraWidgetLogTube {
    var logger: AgoraWidgetLogger
    
    private(set) lazy var contentView = AgoraWebViewContentView(uiDelegate: self,
                                                                navigationDelegate: self,
                                                                delegate: self)
    
    private var urlString: String? {
        didSet {
            guard let url = urlString,
                  url != oldValue else {
                return
            }
            webViewState = .none
            contentView.openWebUrl(url)
        }
    }
    
    var webViewState: FcrWebViewShowState = .none {
        didSet {
            guard webViewState != oldValue else {
                return
            }
            switch webViewState {
            case .committed:
                NotificationCenter.default.addObserver(self,
                                                       selector: #selector(keyboardWillShow(notification:)),
                                                       name: UIResponder.keyboardWillShowNotification,
                                                       object: nil)
            case .finished:
                NotificationCenter.default.removeObserver(self)
            default:
                break
            }
        }
    }
    
    public override init(widgetInfo: AgoraWidgetInfo) {
        let logger = AgoraWidgetLogger(widgetId: widgetInfo.widgetId,
                                       logId: widgetInfo.localUserInfo.userUuid)
        #if DEBUG
        logger.isPrintOnConsole = true
        #endif
        self.logger = logger
        
        super.init(widgetInfo: widgetInfo)
        
        log(content: "[WebView Widget]: create",
            extra: "widgetId:\(widgetInfo.widgetId)",
            type: .info)
    }
    
    public override func onLoad() {
        super.onLoad()
        
        view.addSubview(contentView)
        
        contentView.tabView.setOperationPrivilege(false)
        
        contentView.mas_makeConstraints { make in
            make?.left.right().top().bottom().equalTo()(0)
        }
        
        handleExtraInit()
    }
    
    public override func onWidgetRoomPropertiesUpdated(_ properties: [String : Any],
                                                       cause: [String : Any]?,
                                                       keyPaths: [String],
                                                       operatorUser: AgoraWidgetUserInfo?) {
        super.onWidgetRoomPropertiesUpdated(properties,
                                            cause: cause,
                                            keyPaths: keyPaths,
                                            operatorUser: operatorUser)
        
        guard operatorUser?.userUuid != info.localUserInfo.userUuid else {
            return
        }
        
        let logContent = "[WebView Widget]: room properties" + (properties.jsonString() ?? "nil")
        log(content: logContent,
            extra: cause?.jsonString(),
            type: .info)
        handleExtraUpdated()
    }
    
    public override func onMessageReceived(_ message: String) {
        guard let signal = message.toWebViewSignal() else {
                  return
        }
        switch signal {
        case .boardAuth(let granted):
            contentView.tabView.setOperationPrivilege(granted)
        case .updateViewZIndex(let zIndex):
            updateRoomPropertiesZIndex(zIndex: zIndex)
        default:
            break
        }
    }
}

// MARK: - private
extension AgoraWebViewWidget {
    func handleExtraInit() {
        guard let props = info.roomProperties,
              let extra = AgoraWebViewExtraModel.decode(props),
              let url = extra.webViewUrl else {
            return
        }
        urlString = url
    }
    
    func handleExtraUpdated() {
        guard let props = info.roomProperties,
              let extra = AgoraWebViewExtraModel.decode(props) else {
            return
        }
        // url?????????
        if let url = extra.webViewUrl {
            urlString = url
        }
        
        // zIndex??????VC??????
        if let zIndex = extra.zIndex {
            sendMessage(signal: .viewZIndexChanged(zIndex))
        }
    }
    
    @objc func keyboardWillShow(notification: Notification) {
        guard webViewState == .committed else {
            return
        }
        UIApplication.shared.keyWindow?.endEditing(true)
    }
    
    func updateRoomPropertiesZIndex(zIndex: Int) {
        let properties = ["zIndex": zIndex]
        
        updateRoomProperties(properties,
                             cause: nil) { [weak self] in
            self?.log(content: "[WebView Widget]: update roomProperties success",
                      extra: properties.jsonString(),
                      type: .info)
        } failure: { [weak self] error in
            self?.log(content: "[WebView Widget]: update roomProperties error",
                      extra: properties.jsonString(),
                      type: .error)
        }
    }
    
    func sendMessage(signal: AgoraWebViewSignal) {
        guard let message = signal.toMessageString() else {
            log(content: "[WebView Widget]: signal encode error!",
                type: .error)
            return
        }
        sendMessage(message)
    }
}
