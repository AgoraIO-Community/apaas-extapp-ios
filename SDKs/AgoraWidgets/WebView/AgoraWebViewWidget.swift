//
//  AgoraWebViewWidget.swift
//  AgoraWidgets
//
//  Created by DoubleCircle on 2022/5/24.
//

import AgoraWidget

@objcMembers public class AgoraWebViewWidget: AgoraNativeWidget {
    private(set) lazy var contentView = AgoraWebViewContentView(delegate: self)
    
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
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    public override func onLoad() {
        super.onLoad()
        initViews()
        initViewFrame()
        updateViewProperties()
        
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
        
        handleExtraUpdated()
    }
    
    public override func onMessageReceived(_ message: String) {
        guard let signal = message.toWebViewSignal() else {
                  return
        }
        switch signal {
        case .boardAuth(let granted):
            contentView.headerView.setOperationPrivilege(granted)
        case .updateViewZIndex(let zIndex):
            updateRoomPropertiesZIndex(zIndex: zIndex)
        default:
            break
        }
    }
}

extension AgoraWebViewWidget: AgoraUIContentContainer {
    public func initViews() {
        view.addSubview(contentView)
        
        contentView.headerView.setOperationPrivilege(false)
        contentView.webView.uiDelegate = self
        contentView.webView.navigationDelegate = self
    }
    
    public func initViewFrame() {
        contentView.agora_mas_makeConstraints { make in
            make?.left.right().top().bottom().equalTo()(0)
        }
    }
    
    public func updateViewProperties() {
        let component = UIConfig.webView
        
        contentView.updateViewProperties()
        
        view.layer.update(with: component.shadow)
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
        // url自处理
        if let url = extra.webViewUrl {
            urlString = url
        }
        
        // zIndex交给VC处理
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
                             cause: nil,
                             success: nil,
                             failure: nil)
    }
    
    func sendMessage(signal: AgoraWebViewSignal) {
        guard let message = signal.toMessageString() else {
            log(content: "signal encode error!",
                type: .error)
            return
        }
        sendMessage(message)
    }
}
