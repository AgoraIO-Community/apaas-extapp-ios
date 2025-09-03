//
//  AgoraChatMessageCells.swift
//  AgoraWidgets
//
//  Created by DoubleCircle on 2022/7/23.
//

import AgoraUIBaseViews
import CoreGraphics

class AgoraChatCommonMessageCell: UITableViewCell, AgoraUIContentContainer {
    static let sendId = "AgoraChatCommonMessageCellSend"
    static let receiveId = "AgoraChatCommonMessageCellReceive"
    private let kRoleLabelHeight: CGFloat = 16
    private let kAvatarHeight: CGFloat = 22
    
    private(set) lazy var avatarView = UIImageView()
    private(set) lazy var nameLabel = UILabel()
    private(set) lazy var roleLabel = UILabel()
    // for text
    private(set) lazy var bubleView = UIView()
    private(set) lazy var messageLabel = UILabel()
    // for image
    private(set) lazy var messageImageView = UIImageView()
    
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
    
    func sizeWithImage(_ image: UIImage?) -> CGSize {
        guard let `image` = image else {
            return .zero
        }
        let minWidth: CGFloat = 50
        let maxWidth: CGFloat = 120
        let maxHeight: CGFloat = 260
        
        let originSize = image.size
        let originScale = image.size.width / image.size.height
        
        let finalWidth = (originSize.width > maxWidth) ? maxWidth : originSize.width
        
        let scaleHeight = finalWidth / originScale
        let finalHeight = (scaleHeight > maxHeight) ? maxHeight : scaleHeight
        return CGSize(width: finalWidth,
                      height: finalHeight)
    }
    
    func updateFrame() {
        let toRight = (reuseIdentifier == AgoraChatCommonMessageCell.sendId)

        guard !messageImageView.size.equalTo(.zero),
              messageImageView.agora_visible else {
            messageImageView.agora_mas_remakeConstraints { make in
                if toRight {
                    make?.right.equalTo()(-25)
                } else {
                    make?.left.equalTo()(25)
                }
                make?.top.equalTo()(avatarView.agora_mas_bottom)?.offset()(17)
                make?.size.equalTo()(0)
            }
            return
        }
        let size = messageImageView.size
        messageImageView.agora_mas_remakeConstraints { make in
            if toRight {
                make?.right.equalTo()(-25)
            } else {
                make?.left.equalTo()(25)
            }
            make?.top.equalTo()(avatarView.agora_mas_bottom)?.offset()(17)
            make?.bottom.equalTo()(contentView)
            make?.size.equalTo()(size)
        }
    }
    
    // MARK: - AgoraUIContentContainer
    func initViews() {
        avatarView.image = UIImage.agora_image("ic_rtm_avatar",
                                               in: "AgoraWidgets")
        avatarView.contentMode = .scaleAspectFill
        messageLabel.numberOfLines = 0
        
        contentView.addSubviews([avatarView,
                                 nameLabel,
                                 roleLabel,
                                 bubleView,
                                 messageLabel,
                                 messageImageView])
    }
    
    func initViewFrame() {
        if reuseIdentifier == AgoraChatCommonMessageCell.sendId {
            avatarView.agora_mas_makeConstraints { make in
                make?.top.equalTo()(5)
                make?.right.equalTo()(-14)
                make?.width.height().equalTo()(kAvatarHeight)
            }
            nameLabel.agora_mas_makeConstraints { make in
                make?.centerY.equalTo()(avatarView)
                make?.right.equalTo()(avatarView.agora_mas_left)?.offset()(-6)
            }
            roleLabel.agora_mas_makeConstraints { make in
                make?.height.equalTo()(kRoleLabelHeight)
                make?.right.equalTo()(nameLabel.agora_mas_left)?.offset()(-6)
                make?.centerY.equalTo()(nameLabel)
            }
            messageLabel.agora_mas_makeConstraints { make in
                make?.right.equalTo()(-25)
                make?.top.equalTo()(avatarView.agora_mas_bottom)?.offset()(17)
                make?.left.greaterThanOrEqualTo()(25)
                make?.bottom.equalTo()(self.contentView)?.offset()(-15)
            }
            bubleView.agora_mas_makeConstraints { make in
                make?.left.equalTo()(messageLabel)?.offset()(-10)
                make?.right.equalTo()(messageLabel)?.offset()(10)
                make?.top.equalTo()(messageLabel)?.offset()(-9)
                make?.bottom.equalTo()(messageLabel)?.offset()(9)
            }
            messageImageView.agora_mas_makeConstraints { make in
                make?.right.equalTo()(-25)
                make?.top.equalTo()(avatarView.agora_mas_bottom)?.offset()(17)
            }
        } else if reuseIdentifier == AgoraChatCommonMessageCell.receiveId {
            avatarView.agora_mas_makeConstraints { make in
                make?.top.equalTo()(5)
                make?.left.equalTo()(14)
                make?.width.height().equalTo()(kAvatarHeight)
            }
            nameLabel.agora_mas_makeConstraints { make in
                make?.centerY.equalTo()(avatarView)
                make?.left.equalTo()(avatarView.agora_mas_right)?.offset()(6)
            }
            roleLabel.agora_mas_makeConstraints { make in
                make?.height.equalTo()(kRoleLabelHeight)
                make?.left.equalTo()(nameLabel.agora_mas_right)?.offset()(6)
                make?.centerY.equalTo()(nameLabel)
            }
            messageLabel.agora_mas_makeConstraints { make in
                make?.left.equalTo()(25)
                make?.top.equalTo()(avatarView.agora_mas_bottom)?.offset()(17)
                make?.right.lessThanOrEqualTo()(-25)
                make?.bottom.equalTo()(self.contentView)?.offset()(-15)
            }
            bubleView.agora_mas_makeConstraints { make in
                make?.left.equalTo()(messageLabel)?.offset()(-10)
                make?.right.equalTo()(messageLabel)?.offset()(10)
                make?.top.equalTo()(messageLabel)?.offset()(-9)
                make?.bottom.equalTo()(messageLabel)?.offset()(9)
            }
            
            messageImageView.agora_mas_makeConstraints { make in
                make?.left.equalTo()(25)
                make?.top.equalTo()(avatarView.agora_mas_bottom)?.offset()(17)
            }
        }
        
        guard !messageImageView.size.equalTo(.zero) else {
            return
        }
        let size = messageImageView.size
        messageImageView.agora_mas_updateConstraints { make in
            make?.size.equalTo()(size)
            make?.bottom.equalTo()(contentView)
        }
    }
    
    func updateViewProperties() {
        let config = UIConfig.agoraChat.message.cell
        backgroundColor = .clear
        
        avatarView.layer.cornerRadius = config.avatarCornerRadius
        
        nameLabel.textColor = config.nameColor
        nameLabel.font = config.nameFont
        
        roleLabel.textColor = config.roleColor
        roleLabel.font = config.roleFont
        roleLabel.layer.borderWidth = config.roleBorderWidth
        roleLabel.layer.cornerRadius = config.roleCornerRadius
        roleLabel.layer.borderColor = config.roleBorderColor.cgColor
        
        bubleView.backgroundColor = config.backgroundColor
        bubleView.layer.borderColor = config.borderColor.cgColor
        bubleView.layer.cornerRadius = config.messageCornerRadius
        
        messageLabel.textColor = config.messageColor
        messageLabel.font = config.messageFont
        
        messageImageView.layer.cornerRadius = UIConfig.agoraChat.picture.cornerRadius
    }
}

class AgoraChatNoticeMessageCell: UITableViewCell, AgoraUIContentContainer {
    static let id = "AgoraChatNoticeMessageCell"
    
    private lazy var noticeImageView = UIImageView()
    private(set) lazy var noticeLabel = UILabel()
    
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
    
    // MARK: - AgoraUIContentContainer
    func initViews() {
        noticeLabel.textAlignment = .left
        noticeLabel.numberOfLines = 0
        contentView.addSubviews([noticeImageView,
                                 noticeLabel])
    }
    
    func initViewFrame() {
        noticeLabel.agora_mas_makeConstraints { make in
            make?.center.equalTo()(contentView)
            make?.width.lessThanOrEqualTo()(contentView)?.offset()(-50)
            make?.top.equalTo()(10)
            make?.bottom.equalTo()(-10)
        }
        noticeImageView.agora_mas_makeConstraints { make in
            make?.centerY.equalTo()(contentView)
            make?.width.equalTo()(18)
            make?.height.equalTo()(20)
            make?.right.equalTo()(noticeLabel.agora_mas_left)?.offset()(-5);
        }
    }
    
    func updateViewProperties() {
        let config = UIConfig.agoraChat.message.notice
        backgroundColor = config.backgroundColor
        noticeImageView.image = config.image
        
        noticeLabel.textColor = config.labelColor
        noticeLabel.font = config.labelFont
    }
}
