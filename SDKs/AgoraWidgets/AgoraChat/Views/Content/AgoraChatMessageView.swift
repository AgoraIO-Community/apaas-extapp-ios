//
//  AgoraChatMessageView.swift
//  AgoraWidgets
//
//  Created by DoubleCircle on 2022/7/30.
//

import AgoraUIBaseViews
import SDWebImage

class AgoraChatMessageView: UIView {
    private lazy var messageListView = UITableView(frame: .zero,
                                                   style: .plain)
    private(set) lazy var annoucementButton = UIButton(type: .custom)
    
    private lazy var nilImageView = UIImageView(frame: .zero)
    private lazy var nilLabel = UILabel(frame: .zero)
    
    private lazy var fullScreenImageView = UIImageView(frame: UIScreen.main.bounds)
    /**data**/
    var messageDataSource = [AgoraChatMessageViewType]() {
        didSet {
            updateVisible()
            updateMessageList()
        }
    }
    
    var announcementText: String?  {
        didSet {
            annoucementButton.setTitle(announcementText,
                                       for: .normal)
            annoucementButton.agora_visible = (announcementText != nil)
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
    
    func updateVisible() {
        guard messageDataSource.count > 0 else {
            nilImageView.agora_visible = true
            nilLabel.agora_visible = true
            
            messageListView.agora_visible = false
            return
        }
        nilImageView.agora_visible = false
        nilLabel.agora_visible = false
        
        messageListView.agora_visible = true
    }
}

extension AgoraChatMessageView: AgoraUIContentContainer {
    func initViews() {
        messageListView.tableFooterView = UIView()
        messageListView.estimatedRowHeight = 60
        messageListView.estimatedSectionHeaderHeight = 0
        messageListView.estimatedSectionFooterHeight = 0
        messageListView.separatorInset = .zero
        messageListView.separatorStyle = .none
        messageListView.allowsMultipleSelection = false
        messageListView.delegate = self
        messageListView.dataSource = self
        messageListView.register(AgoraChatCommonMessageCell.self,
                                 forCellReuseIdentifier: AgoraChatCommonMessageCell.sendId)
        messageListView.register(AgoraChatCommonMessageCell.self,
                                 forCellReuseIdentifier: AgoraChatCommonMessageCell.receiveId)
        messageListView.register(AgoraChatNoticeMessageCell.self,
                                 forCellReuseIdentifier: AgoraChatNoticeMessageCell.id)
        
        nilLabel.textAlignment = .center
        
        annoucementButton.titleLabel?.numberOfLines = 1
        annoucementButton.titleLabel?.lineBreakMode = .byTruncatingTail
        annoucementButton.imageView?.contentMode = .scaleAspectFit
        
        let tap = UITapGestureRecognizer(target: self,
                                         action: #selector(onClickCloseFullScreenImage))
        fullScreenImageView.addGestureRecognizer(tap)
        fullScreenImageView.backgroundColor = .black.withAlphaComponent(0.2)
        fullScreenImageView.contentMode = .scaleAspectFit
        fullScreenImageView.isUserInteractionEnabled = true
        let topVc = UIViewController.agora_top_view_controller()
        topVc.view.addSubview(fullScreenImageView)
        fullScreenImageView.frame = topVc.view.frame
        
        addSubviews([messageListView,
                     nilImageView,
                     nilLabel,
                     annoucementButton])
        
        let config = UIConfig.agoraChat
        messageListView.agora_enable = config.message.enable
        messageListView.agora_visible = false
        
        annoucementButton.agora_enable = config.announcement.enable
        annoucementButton.agora_visible = false
        
        nilImageView.agora_visible = true
        nilLabel.agora_visible = true
        
        fullScreenImageView.agora_visible = false
    }
    
    func initViewFrame() {
        messageListView.mas_makeConstraints { make in
            make?.left.right().top().bottom().equalTo()(self)
        }
        
        nilImageView.mas_makeConstraints { make in
            make?.centerX.centerY().equalTo()(self);
            make?.width.equalTo()(80)
            make?.height.equalTo()(80)
        }
        
        nilLabel.mas_makeConstraints { make in
            make?.centerX.equalTo()(nilImageView)
            make?.top.equalTo()(nilImageView.mas_bottom)
            make?.width.equalTo()(self);
            make?.height.equalTo()(20);
        }
        
        annoucementButton.mas_makeConstraints { make in
            make?.width.left().top().equalTo()(self)
            make?.height.equalTo()(24)
        }
    }
    
    func updateViewProperties() {
        let config = UIConfig.agoraChat
        
        messageListView.backgroundColor = config.backgroundColor
        
        annoucementButton.backgroundColor = config.announcement.buttonBackgroundColor
        annoucementButton.titleLabel?.font = config.announcement.buttonTitleFont
        annoucementButton.setTitleColorForAllStates(config.announcement.buttonTitleColor)
        annoucementButton.setImage(config.announcement.buttonImage,
                                   for: .normal)
        
        nilImageView.image = config.message.nilImage
        
        nilLabel.text = config.message.nilText
        
        nilLabel.font = config.message.nilLabelFont
        nilLabel.textColor = config.message.nilLabelColor
    }
}

// MARK: - table view
extension AgoraChatMessageView: UITableViewDelegate, UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return messageDataSource.count
    }
    
    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let type = messageDataSource[indexPath.row]
        
        switch type {
        case .text(let model):
            let id = (model.isLocal) ? AgoraChatCommonMessageCell.sendId : AgoraChatCommonMessageCell.receiveId
            let cell = tableView.dequeueReusableCell(withIdentifier: id,
                                                     for: indexPath) as! AgoraChatCommonMessageCell
            cell.selectionStyle = .none
            updateMessageCellBaseInfo(cell: cell,
                                      model: model,
                                      isText: true)
            
            cell.messageLabel.text = model.text
            cell.updateFrame()
            return cell
        case .image(let model):
            let id = (model.isLocal) ? AgoraChatCommonMessageCell.sendId : AgoraChatCommonMessageCell.receiveId
            let cell = tableView.dequeueReusableCell(withIdentifier: id,
                                                     for: indexPath) as! AgoraChatCommonMessageCell
            cell.selectionStyle = .none
            updateMessageCellBaseInfo(cell: cell,
                                      model: model,
                                      isText: false)
            
            if let image = model.image {
                cell.messageImageView.image = image
                let size = cell.sizeWithImage(image)
                cell.messageImageView.size = size
                cell.updateFrame()
            } else {
                let urlString = model.imageRemoteUrl
                let url = URL(string: urlString)
                let brokenImage = UIConfig.agoraChat.picture.brokenImage
                
                cell.messageImageView.sd_setImage(with: url,
                                                  placeholderImage: brokenImage) { [weak self] downloadImage, error, cacheType, url in
                    guard let `self` = self else {
                        return
                    }
                    
                    guard self.messageDataSource.count > indexPath.row else {
                        return
                    }
                    
                    let type = self.messageDataSource[indexPath.row]
                    
                    guard case .image(var model) = type else {
                        return
                    }
                    
                    guard model.imageRemoteUrl == urlString else {
                        return
                    }
                    
                    model.image = downloadImage
                    
                    let new = AgoraChatMessageViewType.image(model)
                    
                    self.messageDataSource[indexPath.row] = new
                    
                    tableView.reloadRows(at: [indexPath],
                                         with: .none)
                }
            }
            return cell
        case .notice(let noticeString):
            let cell = tableView.dequeueReusableCell(withIdentifier: AgoraChatNoticeMessageCell.id,
                                                     for: indexPath) as! AgoraChatNoticeMessageCell
            cell.selectionStyle = .none
            updateNoticeMessageCell(cell: cell,
                                    notice: noticeString)
            return cell
        }
    }
    
    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {
        let type = messageDataSource[indexPath.row]
        
        guard case .image(let model) = type else {
            return
        }
        
        guard let image = model.image else {
            return
        }
        
        setFullScreenImage(localImage: image)
    }
}

// MARK: - private
private extension AgoraChatMessageView {
    func updateMessageList() {
        if messageDataSource.count >= 150 {
            messageDataSource.removeSubrange(0..<50)
        }
        
        self.messageListView.reloadData { [weak self] in
            guard let `self` = self else {
                return
            }
            
            let contentHeight = self.messageListView.contentSize.height
            let height = self.messageListView.bounds.size.height
            let y = contentHeight - height
            
            guard y > 0 else {
                return
            }
             
            let bottomOffset = CGPoint(x: 0,
                                       y: y)
            self.messageListView.setContentOffset(bottomOffset,
                                                  animated: true)
        }
    }

    func updateMessageCellBaseInfo(cell: AgoraChatCommonMessageCell,
                                   model: AgoraChatMessageModel,
                                   isText: Bool) {
        cell.nameLabel.text = model.userName
        
        if model.userRole.count > 0 {
            cell.roleLabel.agora_visible = true
            cell.roleLabel.text = model.userRole
        } else {
            cell.roleLabel.agora_visible = false
        }
        
        if let avatarUrl = model.avatar,
           let url = URL(string: avatarUrl) {
            cell.avatarView.sd_setImage(with: url)
        }
        
        cell.messageLabel.agora_visible = isText
        cell.bubleView.agora_visible = isText
        cell.messageImageView.agora_visible = !isText
    }
    
    func updateNoticeMessageCell(cell: AgoraChatNoticeMessageCell,
                                 notice: String) {
        cell.noticeLabel.text = notice
    }
    
    func setFullScreenImage(localImage: UIImage) {
        let topVc = UIViewController.agora_top_view_controller()
        
        topVc.view.bringSubviewToFront(fullScreenImageView)
        fullScreenImageView.agora_visible = true
        fullScreenImageView.image = localImage
    }
    
    @objc func onClickCloseFullScreenImage() {
        fullScreenImageView.agora_visible = false
    }
}
