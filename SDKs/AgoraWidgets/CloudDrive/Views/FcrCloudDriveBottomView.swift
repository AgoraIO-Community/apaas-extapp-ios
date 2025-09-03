//
//  FcrCloudDriveBottomView.swift
//  AgoraWidgets
//
//  Created by Cavan on 2023/10/16.
//

import AgoraUIBaseViews

class FcrCloudDriveBottomButton: UIButton,
                                 AgoraUIContentContainer {
    enum State {
        case normal, uploading
    }
    
    var cusState: State = .normal {
        didSet {
            layoutSubviews()
        }
    }
    
    private let uploadingImageView = UIImageView(frame: .zero)
    
    private var isRotated = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initViews()
        initViewFrame()
        updateViewProperties()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        guard let `imageView` = imageView,
              let label = titleLabel,
              let text = label.text
        else {
            return
        }
        
        layout(with: cusState,
               imageView: imageView,
               titleLabel: label,
               text: text)
    }
    
    func initViews() {
        addSubview(uploadingImageView)
    }
    
    func initViewFrame() {
        
    }
    
    func updateViewProperties() {
        uploadingImageView.image = UIImage.widgets_image("fcr_cloud_process")
    }
    
    private func layout(with state: State,
                        imageView: UIImageView,
                        titleLabel: UILabel,
                        text: String) {
        switch state {
        case .normal:
            stop()
            layoutWithoutUploading(imageView: imageView,
                                   titleLabel: titleLabel,
                                   text: text)
        case .uploading:
            start()
            layoutWithUploading(imageView: imageView,
                                titleLabel: titleLabel,
                                text: text)
        }
    }
    
    private func layoutWithUploading(imageView: UIImageView,
                                     titleLabel: UILabel,
                                     text: String) {
        let imageWidth: CGFloat = 20
        let imageHeight: CGFloat = 20
        
        let horizontalSpace: CGFloat = 6
        
        let uploadingWidth: CGFloat = 12
        let uploadingHeight: CGFloat = 12
        
        let textHeight = bounds.height
        let textWidth = text.agora_size(font: titleLabel.font,
                                        height: textHeight).width
        
        let contentWidth = (imageWidth + horizontalSpace + textWidth + uploadingWidth)
        
        // ImageView
        let imageX = (bounds.width - contentWidth) * 0.5
        let imageY = (bounds.height - imageHeight) * 0.5
        
        let imageFrame = CGRect(x: imageX,
                                y: imageY,
                                width: imageWidth,
                                height: imageHeight)
        
        imageView.frame = imageFrame
        
        // Title Label
        let textX = imageFrame.maxX + horizontalSpace
        let textY: CGFloat = 0
        
        let textFrame = CGRect(x: textX,
                               y: textY,
                               width: textWidth,
                               height: textHeight)
        
        titleLabel.frame = textFrame
        
        // Uploading
        let uploadingX = textFrame.maxX + horizontalSpace
        let uploadingY = (bounds.height - uploadingHeight) * 0.5
        
        let uploadingFrame = CGRect(x: uploadingX,
                                    y: uploadingY,
                                    width: uploadingWidth,
                                    height: uploadingHeight)
        
        uploadingImageView.frame = uploadingFrame
    }
    
    private func layoutWithoutUploading(imageView: UIImageView,
                                        titleLabel: UILabel,
                                        text: String) {
        let imageWidth: CGFloat = 20
        let imageHeight: CGFloat = 20
        
        let horizontalSpace: CGFloat = 6
        
        let textHeight = bounds.height
        let textWidth = text.agora_size(font: titleLabel.font,
                                        height: textHeight).width
        
        let contentWidth = (imageWidth + horizontalSpace + textWidth)
        
        let imageX = (bounds.width - contentWidth) * 0.5
        let imageY = (bounds.height - imageHeight) * 0.5
        
        let imageFrame = CGRect(x: imageX,
                                y: imageY,
                                width: imageWidth,
                                height: imageHeight)
        
        imageView.frame = imageFrame
        
        let textX = imageFrame.maxX + horizontalSpace
        let textY: CGFloat = 0
        
        let textFrame = CGRect(x: textX,
                               y: textY,
                               width: textWidth,
                               height: textHeight)
        
        titleLabel.frame = textFrame
    }
    
    func start() {
        guard isRotated != true else {
            return
        }
        
        isRotated = true
        
        uploadingImageView.isHidden = false
        
        rotateView()
    }
    
    func stop() {
        isRotated = false
        
        uploadingImageView.isHidden = true
    }
    
    private func rotateView() {
        guard isRotated else {
            return
        }
        
        UIView.animate(withDuration: 1,
                       delay: 0,
                       options: .curveLinear) {
            self.uploadingImageView.transform = self.uploadingImageView.transform.rotated(by: CGFloat(Double.pi))
        } completion: { isFinish in
            self.rotateView()
        }
    }
}

class FcrCloudDriveBottomView: UIView, AgoraUIContentContainer {
    enum State {
        case upload, delete
    }
    
    private let line = UIView(frame: .zero)
    
    let uploadImageButton = FcrCloudDriveBottomButton(frame: .zero)
    let uploadFileButton = FcrCloudDriveBottomButton(frame: .zero)
    let questionButton = UIButton(frame: .zero)
    let deleteButton = FcrCloudDriveBottomButton(frame: .zero)
    
    var state = State.upload {
        didSet {
            guard oldValue != state else {
                return
            }
            
            updateViews(with: state)
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initViews()
        initViewFrame()
        updateViewProperties()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initViews() {
        addSubview(uploadImageButton)
        addSubview(uploadFileButton)
        addSubview(questionButton)
        addSubview(line)
        addSubview(deleteButton)
        
        layer.shadowColor = FcrWidgetUIColorGroup.containerShadowColor.cgColor
        layer.shadowOpacity = FcrWidgetUIColorGroup.shadowOpacity
        layer.shadowOffset = FcrWidgetUIColorGroup.containerShadowOffset
        
        uploadImageButton.titleLabel?.font = FcrWidgetUIFontGroup.font12
        uploadFileButton.titleLabel?.font = FcrWidgetUIFontGroup.font12
        deleteButton.titleLabel?.font = FcrWidgetUIFontGroup.font12
        
        updateViews(with: state)
    }
    
    func initViewFrame() {
        uploadFileButton.agora_mas_makeConstraints { make in
            make?.right.equalTo()(uploadImageButton.agora_mas_left)
            make?.width.equalTo()(uploadImageButton.agora_mas_width)
            make?.top.left().bottom().equalTo()(0)
        }
        
        uploadImageButton.agora_mas_makeConstraints { make in
            make?.right.top().bottom().equalTo()(0)
        }
        
        questionButton.agora_mas_makeConstraints { make in
            make?.left.top().bottom().equalTo()(0)
            make?.width.equalTo()(questionButton.agora_mas_height)
        }
        
        line.agora_mas_makeConstraints { make in
            make?.centerX.equalTo()(0)
            make?.width.equalTo()(1)
            make?.top.equalTo()(8)
            make?.bottom.equalTo()(-8)
        }
        
        deleteButton.agora_mas_makeConstraints { make in
            make?.left.top().right().bottom().equalTo()(0)
        }
    }
    
    func updateViewProperties() {
        line.backgroundColor = FcrWidgetUIColorGroup.systemDividerColor
        
        questionButton.setImage(UIImage.widgets_image("cloud_question"),
                                for: .normal)
        
        // Upload file
        uploadFileButton.setImage(UIImage.widgets_image("cloud_upload_file"),
                                  for: .normal)
        
        uploadFileButton.setTitle("fcr_cloud_upload_file".widgets_localized(),
                                  for: .normal)
        
        uploadFileButton.setTitleColor(FcrWidgetUIColorGroup.textLevel1Color,
                                       for: .normal)
        
        uploadFileButton.backgroundColor = FcrWidgetUIColorGroup.systemForegroundColor
        
        // Upload image
        uploadImageButton.setImage(UIImage.widgets_image("cloud_upload_image"),
                                   for: .normal)
        
        uploadImageButton.setTitle("fcr_cloud_upload_pictures".widgets_localized(),
                                   for: .normal)
        
        uploadImageButton.setTitleColor(FcrWidgetUIColorGroup.textLevel1Color,
                                        for: .normal)
        
        uploadImageButton.backgroundColor = FcrWidgetUIColorGroup.systemForegroundColor
        
        // Delete
        deleteButton.setImage(UIImage.widgets_image("cloud_delete"),
                              for: .normal)
        
        deleteButton.setTitle("fcr_cloud_button_delete".widgets_localized(),
                              for: .normal)
        
        deleteButton.setTitleColor(FcrWidgetUIColorGroup.textLevel1Color,
                                   for: .normal)
        
        deleteButton.backgroundColor = FcrWidgetUIColorGroup.systemForegroundColor
    }
    
    private func updateViews(with state: State) {
        switch state {
        case .upload: deleteButton.isHidden = true
        case .delete: deleteButton.isHidden = false
        }
    }
}
