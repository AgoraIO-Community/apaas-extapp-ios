//
//  AgoraCloudContentView.swift
//  AgoraWidgets
//
//  Created by ZYP on 2021/10/21.
//

import AgoraUIBaseViews


class FcrCloudDriveFileUploadProcessView: UIView,
                                          AgoraUIContentContainer {
    private let imageView = UIImageView(frame: .zero)
    let label = UILabel(frame: .zero)
    
    private var isRotated = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initViews()
        initViewFrame()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initViews() {
        addSubview(imageView)
        addSubview(label)
        
        label.font = FcrWidgetUIFontGroup.font10
        
        update(process: 0)
    }
    
    func initViewFrame() {
        imageView.agora_mas_makeConstraints { make in
            make?.left.centerY().equalTo()(0)
            make?.width.height().equalTo()(12)
        }
        
        label.agora_mas_makeConstraints { make in
            make?.left.equalTo()(imageView.agora_mas_right)?.offset()(3)
            make?.top.bottom().right().equalTo()(0)
        }
    }
    
    func updateViewProperties() {
        label.textColor = FcrWidgetUIColorGroup.textLevel3Color
        
        imageView.image = UIImage.widgets_image("fcr_cloud_process")
    }
    
    func update(process: Int) {
        let convert = "fcr_cloud_button_label_converting".widgets_localized()
        label.text = "\(convert) \(process)%"
    }
    
    func start() {
        guard isRotated != true else {
            return
        }
        
        isRotated = true
        
        rotateView()
    }
    
    func stop() {
        isRotated = false
    }
    
    private func rotateView() {
        guard isRotated else {
            return
        }
        
        UIView.animate(withDuration: 1,
                       delay: 0,
                       options: .curveLinear) {
            self.imageView.transform = self.imageView.transform.rotated(by: CGFloat(Double.pi))
        } completion: { isFinish in
            self.rotateView()
        }
    }
}

protocol FcrCloudDriveCellDelegate: NSObjectProtocol {
    func onSelected(_ index: IndexPath)
}

class FcrCloudDriveCell: UITableViewCell {
    static let cellId = "FcrCloudDriveCell"
    
    let iconImageView = UIImageView(frame: .zero)
    let nameLabel = UILabel()

    let convertUnsuccessfullyLabel = UILabel()
    
    let uploadProcessView = FcrCloudDriveFileUploadProcessView(frame: .zero)
    let selectedButton = UIButton(frame: .zero)
    var index = IndexPath()
    
    var showType: FcrCloudDriveFileStateType = .notSelectable {
        didSet {
            updateView(with: showType)
        }
    }
    
    weak var delegate: FcrCloudDriveCellDelegate?
    
    override init(style: UITableViewCell.CellStyle,
                  reuseIdentifier: String?) {
        super.init(style: style,
                   reuseIdentifier: reuseIdentifier)
        initViews()
        initViewFrame()
        updateViewProperties()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - AgoraUIContentContainer
extension FcrCloudDriveCell: AgoraUIContentContainer {
    func initViews() {
        contentView.addSubview(nameLabel)
        contentView.addSubview(iconImageView)
        contentView.addSubview(selectedButton)
        contentView.addSubview(convertUnsuccessfullyLabel)
        contentView.addSubview(uploadProcessView)
        
        selectedButton.addTarget(self,
                                 action: #selector(onSeletedButtonPressed(_:)),
                                 for: .touchUpInside)
    }
    
    func initViewFrame() {
        iconImageView.agora_mas_makeConstraints { make in
            make?.height.width().equalTo()(22)
            make?.left.equalTo()(16)
            make?.centerY.equalTo()(self.contentView)
        }
        
        nameLabel.agora_mas_makeConstraints { make in
            make?.left.equalTo()(self.iconImageView.agora_mas_right)?.offset()(9)
            make?.top.bottom().equalTo()(self.contentView)
            make?.right.equalTo()(self.uploadProcessView.agora_mas_left)?.offset()(-10)
        }
        
        selectedButton.agora_mas_makeConstraints { make in
            make?.width.equalTo()(50)
            make?.top.bottom().right().equalTo()(0)
        }
        
        uploadProcessView.agora_mas_makeConstraints { make in
            make?.left.equalTo()(contentView.agora_mas_right)?.offset()(-120)
            make?.bottom.top().equalTo()(0)
            make?.width.equalTo()(12 + 100)
        }
        
        convertUnsuccessfullyLabel.agora_mas_makeConstraints { make in
            make?.left.equalTo()(uploadProcessView.agora_mas_left)
            make?.top.bottom().equalTo()(0)
            make?.right.equalTo()(selectedButton.agora_mas_left)
        }
    }
    
    func updateViewProperties() {
        let config = UIConfig.cloudStorage.cell
        backgroundColor = config.backgroundColor
        
        nameLabel.textColor = config.label.color
        nameLabel.font = config.label.font
        
        uploadProcessView.updateViewProperties()
        
        convertUnsuccessfullyLabel.text = "fcr_cloud_upload_status_failed".widgets_localized()
        
        convertUnsuccessfullyLabel.textColor = UIColor.create(hexString: "#F04C36")
        
        convertUnsuccessfullyLabel.font = FcrWidgetUIFontGroup.font10
        
        updateView(with: showType)
    }
    
    private func updateView(with showType: FcrCloudDriveFileStateType) {
        switch showType {
        case .notSelectable:
            selectedButton.isHidden = true
            uploadProcessView.isHidden = true
            uploadProcessView.stop()
        case .selectable(let convertUnsuccessfully):
            selectedButton.isHidden = false
            uploadProcessView.isHidden = true
            uploadProcessView.stop()
            
            selectedButton.setImage(UIImage.widgets_image("fcr_cloud_selectable"),
                                    for: .normal)
        case .isSelected(let isSelected, let convertUnsuccessfully):
            uploadProcessView.isHidden = true
            uploadProcessView.stop()
            
            selectedButton.isHidden = false
            
            let imageName = (isSelected ? "fcr_choosed" : "fcr_cloud_unselected")
            
            selectedButton.setImage(UIImage.widgets_image(imageName),
                                    for: .normal)
        case .converting(let process):
            selectedButton.isHidden = true
            uploadProcessView.isHidden = false
            uploadProcessView.start()
            uploadProcessView.update(process: process)
        }
        
        convertUnsuccessfullyLabel.isHidden = !showType.hasConvertUnsuccessfully
        nameLabel.textColor = (showType.hasConvertUnsuccessfully ? FcrWidgetUIColorGroup.textDisabledColor : FcrWidgetUIColorGroup.textLevel1Color)
    }
    
    @objc func onSeletedButtonPressed(_ sender: UIButton) {
        delegate?.onSelected(index)
    }
}
