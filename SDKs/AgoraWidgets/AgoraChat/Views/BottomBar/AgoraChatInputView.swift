//
//  AgoraChatInputView.swift
//  AgoraWidgets
//
//  Created by LYY on 2022/7/18.
//

import AgoraUIBaseViews
import Masonry

protocol AgoraChatInputViewDelegate: NSObjectProtocol {
    func sendChatText(message: String)
    
    func didSelectEmoji(_ selected: Bool)
    
    func didClickPicture()
}

class AgoraChatInputView: UIView {
    let buttonLength: CGFloat = 24
    
    public weak var delegate: AgoraChatInputViewDelegate?
    private(set) lazy var inputField = UITextField()
    
    private lazy var contentView = UIView()
    private(set) lazy var sendButton = UIButton(type: .custom)
    private(set) lazy var emojiButton = UIButton(type: .custom)
    private(set) lazy var imageButton = UIButton(type: .custom)
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    convenience init(delegate: AgoraChatInputViewDelegate?) {
        self.init(frame: .zero)
        self.delegate = delegate
    }
    
    private override init(frame: CGRect) {
        super.init(frame: frame)
        
        initViews()
        initViewFrame()
        updateViewProperties()
        
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillShow(noti:)),
            name: UIResponder.keyboardWillShowNotification,
            object: nil)
        NotificationCenter.default.addObserver(
            self, selector: #selector(keyboardWillHide(noti:)),
            name: UIResponder.keyboardWillHideNotification,
            object: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func selectEmoji(_ selected: Bool,
                     inputView: UIView?) {
        emojiButton.isSelected = selected
        inputField.inputView = inputView
        DispatchQueue.main.async {
            self.inputField.reloadInputViews()
            self.inputField.becomeFirstResponder()
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        self.inputField.resignFirstResponder()
    }
}
// MARK: - UITextFieldDelegate
extension AgoraChatInputView: UITextFieldDelegate {
    // MARK: UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        onClickSendMessage()
        return true
    }
    
    func textField(_ textField: UITextField,
                   shouldChangeCharactersIn range: NSRange,
                   replacementString string: String) -> Bool {
        guard let currentText = textField.text else {
            return true
        }
        
        let newText = currentText.replacingCharacters(in: Range(range, in: currentText)!,
                                                      with: string)
        
        return newText.count <= 300
    }
}
// MARK: - Actions
private extension AgoraChatInputView {
    @objc func keyboardWillShow(noti: Notification) {
        guard let frame = noti.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
            return
        }
        self.contentView.mas_remakeConstraints { make in
            make?.left.right().equalTo()(0)
            make?.bottom.equalTo()(-frame.size.height)
            make?.height.equalTo()(40)
        }
        
        UIView.animate(withDuration: TimeInterval.agora_animation) {
            self.layoutIfNeeded()
        }
    }
    
    @objc func keyboardWillHide(noti: Notification) {
        self.contentView.mas_remakeConstraints { make in
            make?.left.right().equalTo()(0)
            make?.bottom.equalTo()(0)
            make?.height.equalTo()(40)
        }
        UIView.animate(withDuration: TimeInterval.agora_animation) {
            self.removeFromSuperview()
        }
    }
    
    @objc func onClickSendMessage() {
        if let text = inputField.text,
           text.count > 0 {
            delegate?.sendChatText(message: text)
            inputField.text = nil
            inputField.resignFirstResponder()
        }
    }
    
    @objc func onClickEmoji() {
        if inputField.inputView == nil,
           !emojiButton.isSelected {
            delegate?.didSelectEmoji(true)
        } else if emojiButton.isSelected,
                  let input = inputField.inputView as? AgoraChatEmojiView {
            delegate?.didSelectEmoji(false)
        }
    }
    
    @objc func onClickImage() {
        delegate?.didClickPicture()
    }
}
// MARK: - Creations
extension AgoraChatInputView: AgoraUIContentContainer {
    func initViews() {
        let config = UIConfig.agoraChat
        addSubview(contentView)
        
        sendButton.clipsToBounds = true
        sendButton.setTitle("fcr_hyphenate_im_send".widgets_localized(),
                                 for: .normal)
        sendButton.addTarget(self,
                             action: #selector(onClickSendMessage),
                             for: .touchUpInside)
        
        inputField.delegate = self
        inputField.returnKeyType = .send
        inputField.clipsToBounds = true
        inputField.leftView = UIView(frame: CGRect(x: 0,
                                                   y: 0,
                                                   width: 16,
                                                   height: 0))
        inputField.leftView?.isUserInteractionEnabled = false
        inputField.leftViewMode = .always
        
        emojiButton.setImage(config.emoji.normalImage,
                             for: .normal)
        emojiButton.setImage(config.emoji.selectedImage,
                             for: .selected)
        emojiButton.addTarget(self,
                             action: #selector(onClickEmoji),
                             for: .touchUpInside)
        
        imageButton.setImage(config.picture.image,
                             for: .normal)
        imageButton.addTarget(self,
                             action: #selector(onClickImage),
                             for: .touchUpInside)
        
        contentView.addSubviews([sendButton,
                                 inputField,
                                 emojiButton,
                                 imageButton])
    }
    
    func initViewFrame() {
        contentView.mas_makeConstraints { make in
            make?.left.right().equalTo()(0)
            make?.bottom.equalTo()(frame.maxY)
            make?.height.equalTo()(40)
        }
        sendButton.mas_makeConstraints { make in
            make?.height.equalTo()(30)
            make?.width.equalTo()(60)
            make?.centerY.equalTo()(self.contentView)
            if #available(iOS 11.0, *) {
                make?.right.equalTo()(self.mas_safeAreaLayoutGuideRight)?.offset()(-20)
            } else {
                make?.right.equalTo()(20)
            }
        }
        imageButton.mas_makeConstraints { make in
            make?.right.equalTo()(sendButton.mas_left)?.offset()(-10)
            make?.centerY.equalTo()(sendButton)
            make?.width.height().equalTo()(24)
        }
        emojiButton.mas_makeConstraints { make in
            make?.right.equalTo()(imageButton.mas_left)?.offset()(-10)
            make?.centerY.equalTo()(sendButton)
            make?.width.height().equalTo()(24)
        }
        inputField.mas_makeConstraints { make in
            make?.height.equalTo()(34)
            if #available(iOS 11.0, *) {
                make?.left.equalTo()(self.mas_safeAreaLayoutGuideLeft)?.offset()(20)
            } else {
                make?.left.equalTo()(20)
            }
            make?.right.equalTo()(self.emojiButton.mas_left)?.offset()(-10)
            make?.centerY.equalTo()(self.contentView)
            make?.height.equalTo()(sendButton)
        }
    }
    
    func updateViewProperties() {
        let config = UIConfig.agoraChat.message.input
        backgroundColor = .black.withAlphaComponent(0.35)
        
        contentView.backgroundColor = config.backgroundColor
        
        sendButton.setTitleColor(config.sendButtonTitleColor,
                                 for: .normal)
        sendButton.backgroundColor = config.sendButtonBackgroundColor
        sendButton.titleLabel?.font = config.sendButtonTitleFont
        
        inputField.backgroundColor = config.fieldBackgroundColor
        inputField.textColor = config.fieldTextColor
        inputField.layer.borderWidth = config.borderWidth
        inputField.layer.borderColor = config.borderColor.cgColor
        inputField.layer.cornerRadius = config.cornerRadius
        
        sendButton.layer.cornerRadius = config.cornerRadius
    }
}
