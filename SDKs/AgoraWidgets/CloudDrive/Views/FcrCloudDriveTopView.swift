//
//  AgoraCloudTopBarView.swift
//  AgoraWidgets
//
//  Created by ZYP on 2021/10/20.
//

import AgoraUIBaseViews

import UIKit

protocol FcrCloudDriveTopViewDelegate: NSObjectProtocol {
    func onTypeButtonPressed(type: FcrCloudDriveFileViewType)
    func onCloseButtonPressed()
    func onRefreshButtonPressed()
    func onSearched(content: String)
}

class FcrCloudDriveTopView: UIView {
    /// views
    private var contentView1 = UIView()
    private var publicButton = UIButton()
    private var privateButton = UIButton()
    private var closeButton = UIButton()
    private var selectedLine = UIView()
    private var sepLineLayer1 = CALayer()
    
    private var contentView2 = UIView()
    private var refreshButton = UIButton()
    private var pathNameLabel = UILabel()
    private var fileCountLabel = UILabel()
    private(set) var searchBar = UISearchBar()
    private var sepLineLayer2 = CALayer()
    
    private var listHeaderLabel = UILabel()
    private var sepLineLayer3 = CALayer()
    
    // View Size
    let selectedLineSize = CGSize(width: 66,
                                  height: 2)
    
    /// delegate
    weak var delegate: FcrCloudDriveTopViewDelegate?
    
    private(set) var selectedType: FcrCloudDriveFileViewType = .uiPublic
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initViews()
        initViewFrame()
        updateViewProperties()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func updateFileCount(_ count: Int) {
        let sumText = "fcr_cloud_total_item".widgets_localized()
        let final = sumText.replacingOccurrences(of: String.widgets_localized_replacing(),
                                                 with: "\(count)")
        fileCountLabel.text = final
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        sepLineLayer1.frame = CGRect(x: 0,
                                     y: 29,
                                     width: bounds.width,
                                     height: 1)
        
        sepLineLayer2.frame = CGRect(x: 0,
                                     y: 59,
                                     width: bounds.width,
                                     height: 1)
        
        sepLineLayer3.frame = CGRect(x: 0,
                                     y: 90,
                                     width: bounds.width,
                                     height: 1)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>,
                               with event: UIEvent?) {
        super.touchesBegan(touches,
                           with: event)
        
        searchBar.textField?.endEditing(true)
        
        startSearching()
    }
}

// MARK: - AgoraUIContentContainer
extension FcrCloudDriveTopView: AgoraUIContentContainer {
    func initViews() {
        let config = UIConfig.cloudStorage
        /// 上半部分
        publicButton.setTitleForAllStates("fcr_cloud_public_resource".widgets_localized())
        privateButton.setTitleForAllStates("fcr_cloud_private_resource".widgets_localized())

        addSubview(contentView1)
        contentView1.addSubview(publicButton)
        contentView1.addSubview(privateButton)
        contentView1.addSubview(closeButton)
        contentView1.addSubview(selectedLine)
        
        /// 下半部分
        pathNameLabel.textAlignment = .left
        
        fileCountLabel.textAlignment = .right
        
        searchBar.placeholder = "fcr_cloud_search".widgets_localized()
        searchBar.delegate = self
        searchBar.textField?.clearButtonMode = .whileEditing
        searchBar.textField?.delegate = self
        
        addSubview(contentView2)
        contentView2.addSubview(refreshButton)
        contentView2.addSubview(pathNameLabel)
        contentView2.addSubview(fileCountLabel)
        contentView2.addSubview(searchBar)
        
        for button in [publicButton,
                       privateButton,
                       closeButton,
                       refreshButton] {
            button.addTarget(self,
                             action: #selector(onButtonPressed(sender:)),
                             for: .touchUpInside)
        }
        
        // list header view
        listHeaderLabel.text = "fcr_cloud_file_name".widgets_localized()
        
        addSubview(listHeaderLabel)
        
        searchBar.textField?.addTarget(self,
                                       action: #selector(onEditingChanged(sender:)),
                                       for: .editingChanged)
    }
                                       
    @objc func onEditingChanged(sender: UITextField) {
        startSearching()
    }
    
    func initViewFrame() {
        /// 上半部分
        contentView1.agora_mas_makeConstraints { make in
            make?.left.right().top().equalTo()(self)
            make?.height.equalTo()(29)
        }
        
        publicButton.agora_mas_makeConstraints { make in
            make?.centerY.equalTo()(self.contentView1)
            make?.left.equalTo()(19)
        }
        
        privateButton.agora_mas_makeConstraints { make in
            make?.centerY.equalTo()(self.contentView1)
            make?.left.equalTo()(publicButton.agora_mas_right)?.offset()(40)
        }
        
        selectedLine.agora_mas_makeConstraints { make in
            make?.width.equalTo()(self.selectedLineSize.width)
            make?.height.equalTo()(self.selectedLineSize.height)
            make?.bottom.equalTo()(self.contentView1)
            make?.centerX.equalTo()(publicButton.agora_mas_centerX)
        }
        
        closeButton.agora_mas_makeConstraints { make in
            make?.centerY.equalTo()(self.contentView1)
            make?.width.height().equalTo()(24)
            make?.right.equalTo()(self.contentView1.agora_mas_right)?.offset()(-10)
        }
        /// 下半部分
        contentView2.agora_mas_makeConstraints { make in
            make?.top.equalTo()(contentView1.agora_mas_bottom)?.offset()(1)
            make?.left.right().equalTo()(self)
            make?.height.equalTo()(30)
        }
        
        refreshButton.agora_mas_makeConstraints { make in
            make?.centerY.equalTo()(self.contentView2)
            make?.left.equalTo()(self.contentView2)?.offset()(15)
            make?.height.equalTo()(26)
            make?.width.equalTo()(26)
        }
        
        pathNameLabel.agora_mas_makeConstraints { make in
            make?.left.equalTo()(refreshButton.agora_mas_right)?.offset()(4)
            make?.centerY.equalTo()(self.contentView2)
        }
        
        searchBar.agora_mas_makeConstraints { make in
            make?.width.equalTo()(160)
            make?.height.equalTo()(22)
            make?.right.equalTo()(self)?.offset()(-15)
            make?.centerY.equalTo()(self.contentView2.agora_mas_centerY)
        }
        
        fileCountLabel.agora_mas_makeConstraints { make in
            make?.right.equalTo()(self.searchBar.agora_mas_left)?.offset()(-10)
            make?.centerY.equalTo()(self.contentView2)
        }
        
        listHeaderLabel.agora_mas_makeConstraints { make in
            make?.top.equalTo()(contentView2.agora_mas_bottom)
            make?.left.equalTo()(self)?.offset()(14)
            make?.height.equalTo()(30)
        }
    }
    
    func updateViewProperties() {
        let config = UIConfig.cloudStorage

        contentView1.backgroundColor = config.backgroundColor
        
        for button in [publicButton,
                       privateButton] {
            button.titleLabel?.font = config.titleLabel.font
            button.setTitleColor(config.titleLabel.normalColor,
                                 for: .normal)
        }
        
        selectedLine.backgroundColor = config.selectedColor

        closeButton.setImage(config.close.image,
                             for: .normal)
        
        refreshButton.setImage(config.refresh.image,
                               for: .normal)
        let search = config.search
        let pix = CGSize(width: 1,
                         height: 1)
        searchBar.backgroundImage = UIImage.init(color: .clear,
                                                 size: pix)
        searchBar.backgroundColor = search.backgroundColor
        searchBar.cornerRadius = 11
        searchBar.layer.borderColor = search.borderColor.cgColor
        searchBar.layer.borderWidth = search.borderWidth
        searchBar.textField?.backgroundColor = search.backgroundColor
        searchBar.textField?.font = search.font
        
        pathNameLabel.textColor = FcrWidgetUIColorGroup.textLevel1Color
        pathNameLabel.font = config.titleLabel.font
        fileCountLabel.textColor = FcrWidgetUIColorGroup.textLevel1Color
        fileCountLabel.font = config.titleLabel.font
        
        contentView2.backgroundColor = config.titleBackgroundColor
        
        listHeaderLabel.textColor = config.titleLabel.normalColor
        listHeaderLabel.font = config.titleLabel.font
        
        for sepLayer in [sepLineLayer1,
                         sepLineLayer2,
                         sepLineLayer3] {
            sepLayer.backgroundColor = config.sepLine.backgroundColor.cgColor
            layer.addSublayer(sepLayer)
        }
    }
}

// MARK: - private
private extension FcrCloudDriveTopView {
    @objc func onButtonPressed(sender: UIButton) {
        if sender == closeButton {
            delegate?.onCloseButtonPressed()
        } else if sender == publicButton {
            update(selectedType: .uiPublic)
        } else if sender == privateButton {
            update(selectedType: .uiPrivate)
        } else if sender == refreshButton {
            delegate?.onRefreshButtonPressed()
        }
    }
    
    private func update(selectedType: FcrCloudDriveFileViewType) {
        var constraints: ((AgoraMASConstraintMaker?) -> Void)
        
        switch selectedType {
        case .uiPublic:
            pathNameLabel.text = "fcr_cloud_public_resource".widgets_localized()
            
            constraints = { make in
                make?.width.equalTo()(self.selectedLineSize.width)
                make?.height.equalTo()(self.selectedLineSize.height)
                make?.bottom.equalTo()(self.contentView1)
                make?.centerX.equalTo()(self.publicButton.agora_mas_centerX)
            }
        case .uiPrivate:
            pathNameLabel.text = "fcr_cloud_private_resource".widgets_localized()
            
            constraints = { make in
                make?.width.equalTo()(self.selectedLineSize.width)
                make?.height.equalTo()(self.selectedLineSize.height)
                make?.bottom.equalTo()(self.contentView1)
                make?.centerX.equalTo()(self.privateButton.agora_mas_centerX)
            }
        }
        
        privateButton.isSelected = !selectedType.isPublic
        publicButton.isSelected = selectedType.isPublic
        
        selectedLine.agora_mas_remakeConstraints(constraints)
        
        UIView.animate(withDuration: TimeInterval.agora_animation) {
            self.contentView1.layoutIfNeeded()
        }
        
        self.selectedType = selectedType
        
        delegate?.onTypeButtonPressed(type: selectedType)
    }
    
    func startSearching() {
        guard let text = searchBar.text else {
            delegate?.onSearched(content: "")
            return
        }
        
        delegate?.onSearched(content: text)
    }
}

// MARK: - UISearchBarDelegate
extension FcrCloudDriveTopView: UISearchBarDelegate, UITextFieldDelegate {
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchBar.textField?.endEditing(true)
        
        startSearching()
    }
}
