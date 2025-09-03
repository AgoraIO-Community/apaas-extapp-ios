//
//  AgoraChatEmojiView.swift
//  AgoraWidgets
//
//  Created by LYY on 2022/7/18.
//

import Foundation
import AgoraUIBaseViews

protocol AgoraChatEmojiViewDelegate: NSObjectProtocol {
    func onEmojiSelected(_ emojiString:String)
    func onEmojiDeleted()
}

class AgoraChatEmojiView: UIView {
    weak var delegate: AgoraChatEmojiViewDelegate?
    private var dataSource = [AgoraChatEmojiType]()
    /**views**/
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .vertical
        return UICollectionView(frame: .zero,
                                collectionViewLayout: layout)
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initData()
        initViews()
        initViewFrame()
        updateViewProperties()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.agora_mas_remakeConstraints { make in
            make?.top.equalTo()(0)
            if #available(iOS 11.0, *) {
                make?.left.equalTo()(agora_mas_safeAreaLayoutGuideLeft)
            } else {
                make?.left.equalTo()(0)
            }
            make?.right.equalTo()(0)
            make?.height.equalTo()(frame.height - 10)
        }
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - collection view
extension AgoraChatEmojiView: UICollectionViewDelegate, UICollectionViewDataSource,
                              UICollectionViewDelegateFlowLayout {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withClass: AgoraChatEmojiCell.self,
                                                      for: indexPath)
        let type = dataSource[indexPath.item]
        
        switch type {
        case .emoji(let name):
            cell.label.agora_visible = true
            cell.imageView.agora_visible = false
            cell.label.text = name
        case .delete(let image):
            cell.label.agora_visible = false
            cell.imageView.agora_visible = true
            cell.imageView.image = image
        default:
            break
        }
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        let type = dataSource[indexPath.item]
        
        switch type {
        case .emoji(let x):
            delegate?.onEmojiSelected(x)
        case .delete(let _):
            delegate?.onEmojiDeleted()
        default:
            return
        }
    }
    
    // MARK: UICollectionViewDelegateFlowLayout
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (frame.width - 8) / 13 - 8,
                      height: 40)
    }
}

// MARK: - AgoraUIContentContainer
extension AgoraChatEmojiView: AgoraUIContentContainer {
    func initViews() {
        collectionView.register(cellWithClass: AgoraChatEmojiCell.self)
        collectionView.delegate = self;
        collectionView.dataSource = self;
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceVertical = true
        collectionView.isScrollEnabled = true
        addSubview(collectionView)
    }
    
    func initViewFrame() {

    }
    
    func updateViewProperties() {
        collectionView.backgroundColor = .clear
    }
}

// MARK: - private
private extension AgoraChatEmojiView{
    func initData() {
        let emojiList = ["0x1F60a","0x1F603","0x1F609","0x1F62e","0x1F60b","0x1F60e","0x1F621","0x1F616","0x1F633","0x1F61e","0x1F62d","0x1F610","0x1F607","0x1F62c","0x1F606","0x1F631","0x1F385","0x1F634","0x1F615","0x1F637","0x1F62f","0x1F60f","0x1F611","0x1F496","0x1F494","0x1F319","0x1f31f","0x1f31e","0x1F308","0x1F60d","0x1F61a","0x1F48b","0x1F339","0x1F342","0x1F44d"]
        
        for item in emojiList {
            guard let str = item.toEmojiString() else {
                continue
            }
            let type = AgoraChatEmojiType.emoji(name: str)
            dataSource.append(type)
        }
        let deleteImage = UIConfig.agoraChat.emoji.deleteEmoji
        let deleteType = AgoraChatEmojiType.delete(image: deleteImage)
        dataSource.append(deleteType)
    }
}

class AgoraChatEmojiCell: UICollectionViewCell, AgoraUIContentContainer {
    lazy var label = UILabel()
    
    lazy var imageView = UIImageView()
    
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
        imageView.contentMode = .scaleAspectFit
        contentView.addSubview(imageView)
        contentView.addSubview(label)

    }
    
    func initViewFrame() {
        imageView.agora_mas_makeConstraints { make in
            make?.centerX.centerY().equalTo()(0)
            make?.width.height().equalTo()(40)
        }
        
        label.agora_mas_makeConstraints { make in
            make?.top.equalTo()(5)
            make?.centerX.bottom().equalTo()(0)
            make?.height.equalTo()(14)
        }
    }
    
    func updateViewProperties() {
        let config = UIConfig.agoraChat.emoji
        backgroundColor = .clear
        
        label.textColor = config.textColor
        label.font = config.textFont
    }
}
