//
//  AgoraChatBottomBar.swift
//  AgoraWidgets
//
//  Created by LYY on 2022/7/17.
//

import MobileCoreServices
import AgoraUIBaseViews
import Photos
import UIKit

protocol AgoraChatBottomBarDelegate: NSObjectProtocol {
    func onClickAllMuted(_ isAllMuted: Bool)
    
    func onPhotoNoAuth()
    
    func onSendChatText(message: String)
    
    func onSelectImage(_ image: UIImage?)
}

class AgoraChatBottomBar: UIView {
    weak var delegate: AgoraChatBottomBarDelegate?
    
    var functions: [AgoraChatBottomBarFunction] = [.input, .emoji, .picture, .mute] {
        didSet {
            updateViewFrame()
        }
    }
    
    private let buttonLength: CGFloat = 24
    
    private lazy var lineLayer = CALayer()
    private lazy var inputBackView = UIView()
    private(set) lazy var inputButton = UIButton()
    private lazy var emojiButton = UIButton()
    private lazy var pictureButton = UIButton()
    private(set) lazy var muteButton = UIButton()
    
    private lazy var chatInputView = AgoraChatInputView(delegate: self)
        
    private override init(frame: CGRect) {
        super.init(frame: frame)
        initViews()
        initViewFrame()
        updateViewProperties()
    }
    
    func updateInputText(_ text: String) {
        inputButton.setTitleForAllStates(text)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        lineLayer.frame = CGRect(x: 0,
                                 y: 0,
                                 width: bounds.width,
                                 height: 1)
    }
}

// MARK: - view delegate
extension AgoraChatBottomBar: AgoraChatEmojiViewDelegate,
                              AgoraChatInputViewDelegate,
                              UIImagePickerControllerDelegate,
                              UINavigationControllerDelegate {
    // MARK: AgoraChatEmojiViewDelegate
    func onEmojiSelected(_ emojiString:String) {
         let originText = chatInputView.inputField.text
        chatInputView.inputField.text = (originText ?? "") + emojiString
    }
    
    func onEmojiDeleted() {
        guard var text = chatInputView.inputField.text,
              text.count > 0 else {
            return
        }
        text.removeLast()
        chatInputView.inputField.text = text
    }
    
    // MARK: AgoraChatInputViewDelegate
    func sendChatText(message: String) {
        delegate?.onSendChatText(message: message)
    }
    
    func didSelectEmoji(_ selected: Bool) {
        if selected {
            onClickInputEmoji()
        } else {
            onClickInputMessage()
        }
    }
    
    func didClickPicture() {
        onClickInputPicture()
    }
    
    // MARK: UIImagePickerControllerDelegate
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.originalImage] as? UIImage else {
            picker.dismiss(animated: true)
            return
        }
        picker.dismiss(animated: true)
        delegate?.onSelectImage(image)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}

// MARK: - Actions
private extension AgoraChatBottomBar {
    @objc func onClickInputMessage() {
        guard let window = UIApplication.shared.keyWindow else {
            return
        }
        chatInputView.selectEmoji(false,
                                  inputView: nil)
        
        window.addSubview(chatInputView)
        chatInputView.agora_mas_makeConstraints { make in
            make?.left.right().top().bottom().equalTo()(0)
        }
        window.layoutIfNeeded()
        chatInputView.inputField.becomeFirstResponder()
    }
    
    @objc func onClickInputEmoji() {
        guard let window = UIApplication.shared.keyWindow else {
            return
        }
        let emojiView = AgoraChatEmojiView(frame: CGRect(x: 0,
                                                         y: 0,
                                                         width: bounds.size.width,
                                                         height: 176))
        emojiView.delegate = self
        
        chatInputView.selectEmoji(true,
                                  inputView: emojiView)
        
        window.addSubview(chatInputView)
        chatInputView.agora_mas_makeConstraints { make in
            make?.left.right().top().bottom().equalTo()(0)
        }
        window.layoutIfNeeded()
        chatInputView.inputField.becomeFirstResponder()
    }
    
    @objc func onClickInputPicture() {
        // photo auth handle
        var photoAuthStatus = PHPhotoLibrary.authorizationStatus()
        
        if #available(iOS 14, *) {
            photoAuthStatus = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        } else {
            // Fallback on earlier versions
            photoAuthStatus = PHPhotoLibrary.authorizationStatus()
        }
        
        let handler: (PHAuthorizationStatus) -> () = { [weak self] (status) in
            guard let `self` = self else {
                return
            }
            guard status == .authorized else {
                self.delegate?.onPhotoNoAuth()
                return
            }
            self.showImagePicker()
        }
        guard photoAuthStatus == .authorized else {
            if #available(iOS 14, *) {
                PHPhotoLibrary.requestAuthorization(for: .readWrite,
                                                    handler: handler)
            } else {
                PHPhotoLibrary.requestAuthorization(handler)
            }
            return
        }
        self.showImagePicker()
    }
    
    @objc func onClickMuteAll() {
        delegate?.onClickAllMuted(!muteButton.isSelected)
        muteButton.isSelected = !muteButton.isSelected
    }
    
    func updateViewFrame() {
        let muteVisible = functions.contains(.mute)
        let inputVisible = functions.contains(.input)
        let emojiVisible = functions.contains(.emoji)
        let pictureVisible = functions.contains(.picture)
        
        muteButton.agora_visible = muteVisible
        emojiButton.agora_visible = emojiVisible
        pictureButton.agora_visible = pictureVisible
        
        muteButton.agora_mas_updateConstraints { make in
            make?.width.equalTo()(muteVisible ? buttonLength : 0)
        }

        emojiButton.agora_mas_updateConstraints { make in
            make?.width.equalTo()(emojiVisible ? buttonLength : 0)
        }
        chatInputView.emojiButton.agora_mas_updateConstraints { make in
            make?.width.equalTo()(emojiVisible ? chatInputView.buttonLength : 0)
        }
        
        pictureButton.agora_mas_updateConstraints { make in
            make?.width.equalTo()(pictureVisible ? buttonLength : 0)
        }
        chatInputView.imageButton.agora_mas_updateConstraints { make in
            make?.width.equalTo()(pictureVisible ? chatInputView.buttonLength : 0)
        }
    }
}

// MARK: - Creations
extension AgoraChatBottomBar: AgoraUIContentContainer {
    func initViews() {
        let config = UIConfig.agoraChat
        
        addSubview(inputBackView)
        inputButton.addTarget(self,
                              action: #selector(onClickInputMessage),
                              for: .touchUpInside)
        inputBackView.addSubview(inputButton)
        
        emojiButton.setImage(config.emoji.normalImage,
                             for: .normal)
        
        emojiButton.setImage(config.emoji.selectedImage,
                             for: .selected)
        
        pictureButton.setImage(config.picture.image,
                             for: .normal)
        
        muteButton.setImage(config.muteAll.muteImage,
                             for: .normal)
        muteButton.setImage(config.muteAll.unmuteImage,
                             for: .selected)
        
        emojiButton.addTarget(self,
                              action: #selector(onClickInputEmoji),
                              for: .touchUpInside)
        
        pictureButton.addTarget(self,
                              action: #selector(onClickInputPicture),
                              for: .touchUpInside)
        
        muteButton.addTarget(self,
                              action: #selector(onClickMuteAll),
                              for: .touchUpInside)
        inputBackView.addSubview(emojiButton)
        inputBackView.addSubview(pictureButton)
        addSubview(muteButton)
        layer.addSublayer(lineLayer)
        
        muteButton.agora_enable = config.muteAll.enable
        muteButton.agora_visible = config.muteAll.visible
        
        emojiButton.agora_enable = config.emoji.enable
        emojiButton.agora_visible = config.emoji.visible
        
        pictureButton.agora_enable = config.picture.enable
        pictureButton.agora_visible = config.picture.visible
    }
    
    func initViewFrame() {
        muteButton.agora_mas_makeConstraints { make in
            make?.right.equalTo()(-5)
            make?.centerY.equalTo()(0)
            make?.width.height().equalTo()(buttonLength)
        }
        
        inputBackView.agora_mas_makeConstraints { make in
            make?.left.equalTo()(5)
            make?.top.bottom().equalTo()(0)
            make?.right.equalTo()(muteButton.agora_mas_left)?.offset()(-5)
        }
        pictureButton.agora_mas_makeConstraints { make in
            make?.right.equalTo()(-5)
            make?.centerY.equalTo()(0)
            make?.width.height().equalTo()(buttonLength)
        }
        emojiButton.agora_mas_makeConstraints { make in
            make?.right.equalTo()(pictureButton.agora_mas_left)
            make?.centerY.equalTo()(0)
            make?.width.height().equalTo()(buttonLength)
        }
        inputButton.agora_mas_makeConstraints { make in
            make?.left.equalTo()(5)
            make?.right.equalTo()(emojiButton.agora_mas_left)
            make?.top.bottom().equalTo()(0)
        }
    }
    
    func updateViewProperties() {
        let config = UIConfig.agoraChat.message.sendBar
        backgroundColor = config.backgroundColor
        
        lineLayer.backgroundColor = config.sepLineColor.cgColor
        
        inputBackView.backgroundColor = config.inputBackgroundColor
        inputBackView.layer.cornerRadius = config.cornerRadius
        
        inputButton.setTitleColorForAllStates(config.inputButtonTitleColor)
        inputButton.titleLabel?.font = config.inputButtonTitleFont
    }
}

// MARK: - private
private extension AgoraChatBottomBar {
    func showImagePicker() {
        DispatchQueue.main.async { [weak self] in
            let topVc = UIViewController.agora_top_view_controller()
            
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.sourceType = .photoLibrary
            imagePicker.mediaTypes = [String(kUTTypeImage)]
            
            topVc.present(imagePicker,
                          animated: true)
        }
    }
}

