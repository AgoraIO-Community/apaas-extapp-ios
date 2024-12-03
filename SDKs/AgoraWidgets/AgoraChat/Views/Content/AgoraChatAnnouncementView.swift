//
//  AgoraChatAnnouncementView.swift
//  AgoraWidgets
//
//  Created by LYY on 2022/7/29.
//

import AgoraUIBaseViews

protocol AgoraChatAnnouncementViewDelegate: NSObjectProtocol {
    func onSetAnnouncement(_ announcement: String?)
}

class AgoraChatAnnouncementView: UIView {
    // announcement
    private lazy var annoucementLabel = UILabel(frame: .zero)
    private lazy var editButton = UIButton(frame: .zero)
    private lazy var deleteButton = UIButton(frame: .zero)
    // nil
    private lazy var nilTextView = UITextView(frame: .zero)
    private lazy var nilImageView = UIImageView(frame: .zero)
    // input
    private lazy var inputTextView = UITextView(frame: .zero)
    private lazy var cancelButton = UIButton(frame: .zero)
    private lazy var issueButton = UIButton(frame: .zero)
    private lazy var textCountLabel = UILabel(frame: .zero)
    private lazy var warnLabel = UILabel(frame: .zero)
    
    let setAnnoucementUrl = "setAnnoucement"
    
    /**data*/
    weak var delegate: AgoraChatAnnouncementViewDelegate?
    var editAnnouncementEnabled: Bool = false {
        didSet {
            setNilText()
        }
    }
    var announcementText: String?  {
        didSet {
            annoucementLabel.text = announcementText
            inputTextView.text = announcementText
            let count = announcementText?.count ?? 0
            textCountLabel.text = "\(count)/500"
            updateNilVisible()
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
}

// MARK: - AgoraUIContentContainer
extension AgoraChatAnnouncementView: AgoraUIContentContainer {
    func initViews() {
        annoucementLabel.numberOfLines = 0
        
        nilTextView.isEditable = false
        nilTextView.delegate = self
        nilTextView.textAlignment = .center
        
        inputTextView.delegate = self
        inputTextView.returnKeyType = .done
        inputTextView.clipsToBounds = true
        
        cancelButton.addTarget(self,
                               action: #selector(onClickCancel),
                               for: .touchUpInside)
        issueButton.addTarget(self,
                              action: #selector(onClickIssue),
                              for: .touchUpInside)
        editButton.addTarget(self,
                             action: #selector(onClickEdit),
                             for: .touchUpInside)
        deleteButton.addTarget(self,
                               action: #selector(onClickDelete),
                               for: .touchUpInside)
        
        
        textCountLabel.text = "0/500"
        warnLabel.textAlignment = .left
        addSubview(annoucementLabel)
        addSubview(editButton)
        addSubview(deleteButton)
        addSubview(nilImageView)
        addSubview(nilTextView)
        addSubview(inputTextView)
        addSubview(textCountLabel)
        addSubview(warnLabel)
        addSubview(cancelButton)
        addSubview(issueButton)

        annoucementLabel.agora_visible = false
        editButton.agora_visible = false
        deleteButton.agora_visible = false
        nilImageView.agora_visible = true
        nilTextView.agora_visible = true
        inputTextView.agora_visible = false
        warnLabel.agora_visible = false
        textCountLabel.agora_visible = false
        cancelButton.agora_visible = false
        issueButton.agora_visible = false
    }
    
    func initViewFrame() {
        nilImageView.mas_makeConstraints { make in
            make?.centerX.centerY().equalTo()(self);
            make?.width.equalTo()(80)
            make?.height.equalTo()(80)
        }
        
        nilTextView.mas_makeConstraints { make in
            make?.centerX.equalTo()(nilImageView)
            make?.top.equalTo()(nilImageView.mas_bottom)
            make?.width.equalTo()(self)
            make?.height.equalTo()(25)
        }
        
        annoucementLabel.mas_makeConstraints { make in
            make?.left.equalTo()(13)
            make?.top.equalTo()(13)
            make?.width.height().lessThanOrEqualTo()(self)?.offset()(-14)
            make?.bottom.lessThanOrEqualTo()(self)?.offset()(-34)
        }
        
        deleteButton.mas_makeConstraints { make in
            make?.top.equalTo()(annoucementLabel.mas_bottom)?.offset()(5)
            make?.right.equalTo()(-11)
            make?.width.height().equalTo()(24)
        }
        
        editButton.mas_makeConstraints { make in
            make?.top.equalTo()(deleteButton)
            make?.right.equalTo()(deleteButton.mas_left)?.offset()(-14)
            make?.width.height().equalTo()(24)
        }
        
        warnLabel.mas_makeConstraints { make in
            make?.left.equalTo()(13)
            make?.top.equalTo()(inputTextView.mas_bottom)?.offset()(4)
        }
        
        inputTextView.mas_makeConstraints { make in
            make?.top.left().equalTo()(10)
            make?.right.equalTo()(-10)
            make?.bottom.equalTo()(-63)
        }
        
        textCountLabel.mas_makeConstraints { make in
            make?.right.equalTo()(inputTextView.mas_right)?.offset()(-7)
            make?.width.lessThanOrEqualTo()(inputTextView.mas_width)?.offset()(-3)
            make?.height.equalTo()(20)
            make?.top.equalTo()(inputTextView.mas_bottom)?.offset()(4)
        }
        
        cancelButton.mas_makeConstraints { make in
            make?.width.equalTo()(60)
            make?.height.equalTo()(24)
            make?.left.equalTo()(34)
            make?.bottom.equalTo()(-14)
        }
        
        issueButton.mas_makeConstraints { make in
            make?.width.equalTo()(60)
            make?.height.equalTo()(24)
            make?.right.equalTo()(-30)
            make?.bottom.equalTo()(-14)
        }
    }
    
    func updateViewProperties() {
        let config = UIConfig.agoraChat.announcement
        nilImageView.image = config.nilImage
        
        annoucementLabel.font = config.labelFont
        annoucementLabel.textColor = config.labelColor
        
        editButton.setImage(config.edit.image,
                            for: .normal)
        deleteButton.setImage(config.delete.image,
                              for: .normal)
        
        inputTextView.backgroundColor = config.field.backgroundColor
        inputTextView.layer.cornerRadius = config.field.cornerRadius
        inputTextView.layer.borderColor = config.field.borderColor.cgColor
        inputTextView.layer.borderWidth = config.field.borderWidth
        inputTextView.textColor = config.field.textColor
        inputTextView.font = config.field.textFont
        
        nilTextView.backgroundColor = .clear
        nilTextView.font = config.nilLabelFont
        nilTextView.textColor = config.nilLabelNormalColor
        
        textCountLabel.textColor = config.field.textCountNormalColor
        textCountLabel.font = config.field.textCountFont
        
        warnLabel.text = config.field.warnText
        warnLabel.font = config.field.warnTextFont
        warnLabel.textColor = config.field.textCountWarnColor
        
        cancelButton.layer.borderWidth = config.cancel.borderWidth
        cancelButton.layer.borderColor = config.cancel.borderColor.cgColor
        cancelButton.layer.cornerRadius = config.cancel.cornerRadius
        cancelButton.backgroundColor = config.cancel.backgroundColor
        cancelButton.setTitleForAllStates(config.cancel.title)
        cancelButton.titleLabel?.font = config.cancel.titleFont
        cancelButton.setTitleColorForAllStates(config.cancel.titleColor)
        
        issueButton.layer.borderWidth = config.issue.borderWidth
        issueButton.layer.borderColor = config.issue.borderColor.cgColor
        issueButton.layer.cornerRadius = config.issue.cornerRadius
        issueButton.backgroundColor = config.issue.backgroundColor
        issueButton.setTitleForAllStates(config.issue.title)
        issueButton.titleLabel?.font = config.issue.titleFont
        issueButton.setTitleColorForAllStates(config.issue.titleColor)
        
        setNilText()
    }
}

// MARK: - UITextViewDelegate
extension AgoraChatAnnouncementView: UITextViewDelegate {
    func textView(_ textView: UITextView,
                  shouldInteractWith URL: URL,
                  in characterRange: NSRange,
                  interaction: UITextItemInteraction) -> Bool {
        guard URL.scheme == setAnnoucementUrl else {
            return true
        }
        updateEditFieldVisible(true)
        return false
    }
    
    func textView(_ textView: UITextView,
                  shouldChangeTextIn range: NSRange,
                  replacementText text: String) -> Bool {
        let originCount = inputTextView.text?.count ?? 0
        let finalCount = originCount + text.count
        
        if finalCount <= 500 {
            textCountLabel.text = "\(finalCount)/500"
            textCountLabel.textColor = UIConfig.agoraChat.announcement.field.textCountNormalColor
            warnLabel.agora_visible = false
            return true
        }
        warnLabel.agora_visible = true
        textCountLabel.text = "500/500"
        textCountLabel.textColor = UIConfig.agoraChat.announcement.field.textCountWarnColor
        return false
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        inputTextView.resignFirstResponder()
    }
}

// MARK: - private
private extension AgoraChatAnnouncementView {
    func updateNilVisible() {
        let announcementTextNilFlag = (announcementText == nil)
        
        nilImageView.agora_visible = announcementTextNilFlag
        nilTextView.agora_visible = announcementTextNilFlag
        
        annoucementLabel.agora_visible = !announcementTextNilFlag

        deleteButton.agora_visible = (!announcementTextNilFlag && editAnnouncementEnabled)
        editButton.agora_visible = (!announcementTextNilFlag && editAnnouncementEnabled)
    }
    
    func updateEditFieldVisible(_ visible: Bool) {
        inputTextView.agora_visible = visible
        textCountLabel.agora_visible = visible
        cancelButton.agora_visible = visible
        issueButton.agora_visible = visible
        
        guard visible else {
            updateNilVisible()
            return
        }
        nilImageView.agora_visible = false
        nilTextView.agora_visible = false
        annoucementLabel.agora_visible = false
        editButton.agora_visible = false
        deleteButton.agora_visible = false
    }
    
    func setNilText() {
        let config = UIConfig.agoraChat.announcement
        
        guard editAnnouncementEnabled else {
            nilTextView.font = config.nilLabelFont
            nilTextView.text = config.nilText
            nilTextView.textColor = config.nilLabelNormalColor
            return
        }
        let originString = config.nilAndSetText
        var index = originString.firstIndex(of: ",")
        
        if index == nil {
            index = originString.firstIndex(of: "，")
        }
        guard let commaIndex = index else {
            return
        }
        let targetIndex = originString.index(commaIndex,
                                             offsetBy: 1)
        
        let targetString = String(originString[targetIndex..<originString.endIndex])
        let baseString = String(originString[..<targetIndex])
        
        let contentStr = NSString(string: originString)
        let target = NSMutableAttributedString(string:originString)
         
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineSpacing = 6
        paragraphStyle.alignment = .center

        target.addAttribute(.paragraphStyle,
                             value: paragraphStyle,
                             range: NSMakeRange(0, contentStr.length))
        // base
        let baseRange = contentStr.range(of: baseString,
                                           options: .regularExpression,
                                           range: NSMakeRange(0,contentStr.length))
        target.addAttribute(.font,
                            value: config.nilLabelFont,
                            range: baseRange)
        target.addAttribute(.foregroundColor,
                            value: config.nilLabelNormalColor,
                            range: baseRange)
        // target
        let targetRange = contentStr.range(of: targetString,
                                     options: .regularExpression,
                                     range: NSMakeRange(0,contentStr.length))
        target.addAttribute(.link,
                            value: "\(setAnnoucementUrl)://",
                            range: targetRange)
        target.addAttribute(.font,
                            value: config.nilLabelFont,
                            range: targetRange)
        target.addAttribute(.foregroundColor,
                            value: config.nilLabelLinkColor,
                            range: targetRange)
        
        nilTextView.attributedText = target
    }
    
    @objc func onClickEdit() {
        inputTextView.text = announcementText
        updateEditFieldVisible(true)
    }
    
    @objc func onClickDelete() {
        announcementText = nil

        delegate?.onSetAnnouncement(announcementText)
    }
    
    @objc func onClickCancel() {
        updateEditFieldVisible(false)
    }
    
    @objc func onClickIssue() {
        announcementText = inputTextView.text

        updateEditFieldVisible(false)
        delegate?.onSetAnnouncement(announcementText)
    }
}
