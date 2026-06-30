//
//  AgoraCloudView.swift
//  AgoraWidgets
//
//  Created by ZYP on 2021/10/20.
//

import AgoraUIBaseViews

class FcrCloudDriveView: UIView {
    private(set) var topView = FcrCloudDriveTopView(frame: .zero)
    private(set) var listView = UITableView(frame: .zero)
    private(set) var bottomView = FcrCloudDriveBottomView(frame: .zero)
    private let formatView = FcrCloudDriveFileFormatView(frame: .zero)
        
    override init(frame: CGRect) {
        super.init(frame: frame)
        initViews()
        initViewFrame()
        updateViewProperties()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - AgoraUIContentContainer
extension FcrCloudDriveView: AgoraUIContentContainer {
    func initViews() {
        listView.contentInset = .zero
        listView.tableFooterView = UIView()
        listView.separatorInset = .zero
        listView.rowHeight = 43
        
        listView.register(FcrCloudDriveCell.self,
                          forCellReuseIdentifier: FcrCloudDriveCell.cellId)
        addSubview(topView)
        addSubview(listView)
        addSubview(bottomView)
                
        bottomView.isHidden = true
        formatView.isHidden = true
        
        layer.masksToBounds = true
        
        bottomView.questionButton.addTarget(self,
                                            action: #selector(showFormatView),
                                            for: .touchUpInside)
        
        formatView.closeButton.addTarget(self,
                                         action: #selector(hideFormatView),
                                         for: .touchUpInside)
    }
    
    func initViewFrame() {
        topView.agora_mas_makeConstraints { make in
            make?.left.and().right().and().top().equalTo()(self)
            make?.height.equalTo()(90)
        }
        
        bottomView.agora_mas_makeConstraints { make in
            make?.left.right().bottom().equalTo()(0)
            make?.height.equalTo()(38)
        }
        
        hideBottomView(true)
    }
    
    func hideBottomView(_ isHidden: Bool) {
        bottomView.isHidden = isHidden
        
        if isHidden {
            listView.agora_mas_remakeConstraints { make in
                make?.left.right().bottom().equalTo()(0)
                make?.top.equalTo()(self.topView.agora_mas_bottom)
            }
        } else {
            listView.agora_mas_remakeConstraints { make in
                make?.left.right().equalTo()(self)
                make?.top.equalTo()(self.topView.agora_mas_bottom)
                make?.bottom.equalTo()(self.bottomView.agora_mas_top)
            }
        }
    }
    
    func updateViewProperties() {
        let config = UIConfig.cloudStorage
        backgroundColor = config.backgroundColor
        listView.backgroundColor = config.cell.backgroundColor
        layer.cornerRadius = config.cornerRadius
        layer.masksToBounds = true
        
        bottomView.backgroundColor = FcrWidgetUIColorGroup.systemForegroundColor
        
        formatView.updateViewProperties()
        formatView.backgroundColor = UIColor(red: 0,
                                             green: 0,
                                             blue: 0,
                                             alpha: 0.5)
    }
    
    @objc func showFormatView() {
        guard let window = UIWindow.agora_top_window() else {
            return
        }
        formatView.frame = window.bounds
        window.addSubview(formatView)
        formatView.isHidden = false
    }
    
    @objc func hideFormatView() {
        formatView.removeFromSuperview()
        formatView.isHidden = true
    }
}
