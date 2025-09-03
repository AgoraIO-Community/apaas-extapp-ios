//
//  AgoraWebViewContentView.swift
//  AgoraWidgets
//
//  Created by DoubleCircle on 2022/5/25.
//

import AgoraUIBaseViews
import WebKit

protocol AgoraWebViewContentViewDelegate: NSObjectProtocol {
    func onClickRefresh()
    func onClickScale()
    func onClickClose()
}

class AgoraWebViewContentView: UIView, AgoraUIContentContainer {
    /**data**/
    private weak var delegate: AgoraWebViewContentViewDelegate?
    private var hitPoint = CGPoint.zero
    /**views**/
    private(set) lazy var headerView = AgoraWebViewHeaderView(frame: .zero)
    private(set) lazy var webView: WKWebView = {
        let config = WKWebViewConfiguration()
        let webView = WKWebView(frame: .zero,
                                configuration: config)
        return webView
    }()
    
    // public functions
    public func openWebUrl(_ urlString: String) {
        guard let url = URL(string: urlString) else {
            return
        }
        webView.load(URLRequest(url: url))
    }
    
    public func refreshWebView() {
        // TODO: 加载动画
        webView.reload()
    }
    
    init(delegate: AgoraWebViewContentViewDelegate?) {
        super.init(frame: .zero)
        
        self.delegate = delegate
        
        initViews()
        initViewFrame()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initViews() {
        layer.masksToBounds = true
        
        headerView.refreshButton.addTarget(self,
                                           action: #selector(onClickRefresh(_:)),
                                           for: .touchUpInside)
        
        headerView.scaleButton.addTarget(self,
                                         action: #selector(onClickScale(_:)),
                                         for: .touchUpInside)
        
        headerView.closeButton.addTarget(self,
                                         action: #selector(onClickClose(_:)),
                                         for: .touchUpInside)
        
        addSubview(headerView)
        addSubview(webView)
    }
    
    func initViewFrame() {
        headerView.agora_mas_makeConstraints { make in
            make?.top.equalTo()(0)
            make?.left.right().equalTo()(0)
            make?.height.equalTo()(26)
        }
        
        webView.agora_mas_makeConstraints { make in
            make?.left.right().equalTo()(0)
            make?.top.equalTo()(headerView.agora_mas_bottom)
            make?.bottom.equalTo()(0)
        }
    }
    
    func updateViewProperties() {
        let component = UIConfig.webView
        
        layer.borderWidth = component.boardWidth
        layer.borderColor = component.boardColor.cgColor
        layer.cornerRadius = component.cornerRadius
        
        backgroundColor = component.backgroundColor
        webView.isOpaque = false
        webView.backgroundColor = component.backgroundColor
        
        agora_all_sub_views_update_view_properties()
    }
}

// MARK: - actions
extension AgoraWebViewContentView {
    @objc func onClickRefresh(_ sender: UIButton) {
        delegate?.onClickRefresh()
    }
    
    @objc func onClickScale(_ sender: UIButton) {
        delegate?.onClickScale()
    }
    
    @objc func onClickClose(_ sender: UIButton) {
        delegate?.onClickClose()
    }
}
