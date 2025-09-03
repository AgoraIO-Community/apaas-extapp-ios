//
//  AgoraPopupQuizViews.swift
//  AgoraClassroomSDK_iOS
//
//  Created by Cavan on 2022/3/5.
//

import AgoraUIBaseViews
import SwifterSwift

import UIKit

// MAKR: - Top View
class AgoraPopupQuizTopView: UIView, AgoraUIContentContainer {
    private let titleLabel = UILabel()
    private let timeLabel = UILabel()
    private let lineLayer = CALayer()
    
    let defaultHeight: CGFloat = 17
    
    var quizState: AgoraPopupQuizState = .unselected {
        didSet {
            let component = UIConfig.popupQuiz
            let itemTime = component.time
            
            if quizState == .unselected {
                timeLabel.textColor = itemTime.unselectedTextColor
            } else {
                timeLabel.textColor = itemTime.selectedTextColor
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initViews()
        initViewFrame()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initViews() {
        let component = UIConfig.popupQuiz
        let itemName = component.name
        let itemTime = component.time
        let itemLine = component.sepLine
        
        // TitleLabel
        titleLabel.text = itemName.text
        titleLabel.font = itemName.font
        titleLabel.textAlignment = itemName.textAlignment
        titleLabel.agora_enable = itemName.enable
        
        addSubview(titleLabel)
        
        // TimeLabel
        timeLabel.font = itemTime.font
        timeLabel.textAlignment = itemTime.textAlignment
        titleLabel.agora_enable = itemTime.enable
        
        update(timeString: "00:00:00")
        
        addSubview(timeLabel)
        
        // LineLayer
        lineLayer.agora_enable = itemLine.enable
        layer.addSublayer(lineLayer)
    }
    
    func initViewFrame() {
        let selector = titleLabel.text!
        
        let titleSize = selector.agora_size(font: titleLabel.font,
                                            height: defaultHeight)
        
        titleLabel.agora_mas_makeConstraints { (make) in
            make?.left.equalTo()(10)
            make?.top.bottom()?.equalTo()(0)
            make?.width.equalTo()(titleSize.width + 2)
        }
     
        timeLabel.agora_mas_makeConstraints { (make) in
            make?.left.equalTo()(titleLabel.agora_mas_right)?.offset()(5)
            make?.top.right().bottom()?.equalTo()(0)
        }
    }
    
    func updateViewProperties() {
        let component = UIConfig.popupQuiz
        let itemName = component.name
        let itemTime = component.time
        let itemLine = component.sepLine
        
        backgroundColor = component.headerBackgroundColor
        
        titleLabel.textColor = itemName.textColor
        timeLabel.textColor = itemTime.unselectedTextColor
        lineLayer.backgroundColor = itemLine.backgroundColor.cgColor
    }
    
    func update(timeString: String) {
        timeLabel.text = timeString
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        lineLayer.frame = CGRect(x: 0,
                                 y: bounds.height,
                                 width: bounds.width,
                                 height: 1)
    }
}

// MAKR: - Option Collection View
class AgoraPopupQuizOptionCell: UICollectionViewCell, AgoraUIContentContainer {
    var optionIsSelected: Bool = false {
        didSet {
            let component = UIConfig.popupQuiz
            let itemOption = component.option
            
            if optionIsSelected {
                optionLabel.backgroundColor = itemOption.selectedBackgroundColor
                optionLabel.textColor = itemOption.selectedTextColor
                layer.borderColor = itemOption.selectedBoardColor.cgColor
            } else {
                optionLabel.backgroundColor = itemOption.unselectedBackgroundColor
                optionLabel.textColor = itemOption.unselectedTextColor
                layer.borderColor = itemOption.unselectedBoardColor.cgColor
            }
        }
    }
    
    // after 'optionIsSelected
    var isEnable: Bool = true {
        didSet {
            isUserInteractionEnabled = isEnable
            
            guard optionIsSelected else {
                return
            }
            
            let component = UIConfig.popupQuiz
            let itemOption = component.option
            
            if isEnable {
                optionLabel.backgroundColor = itemOption.selectedBackgroundColor
                layer.borderColor = itemOption.selectedBoardColor.cgColor
            } else {
                optionLabel.backgroundColor = itemOption.disableBackgroundColor
                layer.borderColor = itemOption.disableBoardColor.cgColor
            }
        }
    }
    
    let optionLabel = UILabel()
    
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
        optionLabel.frame = bounds
    }
    
    func initViews() {
        let component = UIConfig.popupQuiz
        let itemOption = component.option
        
        contentView.addSubview(optionLabel)
        
        optionLabel.font = itemOption.font
        optionLabel.textAlignment = itemOption.textAlignment
        
        layer.borderWidth = itemOption.boardWidth
        layer.cornerRadius = itemOption.cornerRadius
        layer.masksToBounds = true
    }
    
    func initViewFrame() {
        
    }
    
    func updateViewProperties() {
        let selected = optionIsSelected
        let enable = isEnable
        
        optionIsSelected = selected
        isEnable = enable
    }
}

class AgoraPopupQuizOptionCollectionView: UICollectionView, AgoraUIContentContainer {
    init() {
        let layout = UICollectionViewFlowLayout()
        
        super.init(frame: .zero,
                   collectionViewLayout: layout)
        
        initViews()
        initViewFrame()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initViews() {
        showsHorizontalScrollIndicator = false
        showsVerticalScrollIndicator = false
        isScrollEnabled = false
        bounces = false
        
        register(cellWithClass: AgoraPopupQuizOptionCell.self)
    }
    
    func initViewFrame() {
        
    }
    
    func updateViewProperties() {
        let component = UIConfig.popupQuiz
        backgroundColor = component.backgroundColor
    }
}

// MAKR: - Result Table View
class AgoraPopupQuizResultCell: UITableViewCell, AgoraUIContentContainer {
    static let cellId = NSStringFromClass(AgoraPopupQuizResultCell.self)
    static let font = UIConfig.popupQuiz.result.font
    
    let titleLabel = UILabel()
    let resultLabel = UILabel()
    
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
    
    func initViews() {
        let itemResult = UIConfig.popupQuiz.result
        
        contentView.addSubview(titleLabel)
        contentView.addSubview(resultLabel)
        
        titleLabel.font = AgoraPopupQuizResultCell.font
        resultLabel.font = AgoraPopupQuizResultCell.font
        
        titleLabel.textAlignment = itemResult.textAlignment
        resultLabel.textAlignment = itemResult.textAlignment
        
        selectionStyle = .none
    }
    
    func initViewFrame() {
        
    }
    
    func updateViewProperties() {
        let itemResult = UIConfig.popupQuiz.result
        
        titleLabel.textColor = itemResult.titleTextColor
        resultLabel.textColor = itemResult.resultNormalTextColor
    }
}

class AgoraPopupQuizResultTableView: UITableView, AgoraUIContentContainer {
    override init(frame: CGRect,
                  style: UITableView.Style) {
        super.init(frame: frame,
                   style: style)
        initViews()
        initViewFrame()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initViews() {
        separatorStyle = .none
        isScrollEnabled = false
        register(AgoraPopupQuizResultCell.self,
                 forCellReuseIdentifier: AgoraPopupQuizResultCell.cellId)
    }
    
    func initViewFrame() {
        let itemResult = UIConfig.popupQuiz.result
        rowHeight = itemResult.rowHeight
    }
    
    func updateViewProperties() {
        let component = UIConfig.popupQuiz
        backgroundColor = component.backgroundColor
    }
}

// MAKR: - Button
class AgoraPopupQuizButton: UIButton, AgoraUIContentContainer {
    private let blueColor = UIColor(hexString: "#357BF6")
    private let lightBlueColor = UIColor(hexString: "#C0D6FF")
    
    var quizState: AgoraPopupQuizState = .unselected {
        didSet {
            let itemSubmit = UIConfig.popupQuiz.submit
            
            switch quizState {
            case .selected:
                let post = itemSubmit.postText
                setTitle(post,
                         for: .normal)
                setTitleColor(itemSubmit.selectedTextColor,
                              for: .normal)
                isEnabled = true
                backgroundColor = itemSubmit.selectedBackgroundColor
                layer.borderColor = itemSubmit.selectedBoardColor.cgColor
            case .changing:
                let change = itemSubmit.changeText
                setTitle(change,
                         for: .normal)
                setTitleColor(itemSubmit.changingTextColor,
                              for: .normal)
                isEnabled = true
                backgroundColor = itemSubmit.changingBackgroundColor
                layer.borderColor = itemSubmit.changingBoardColor.cgColor
            case .unselected:
                let post = itemSubmit.postText
                setTitle(post,
                         for: .disabled)
                setTitleColor(itemSubmit.unselectedTextColor,
                              for: .disabled)
                isEnabled = false
                backgroundColor = itemSubmit.unselectedBackgroundColor
                layer.borderColor = itemSubmit.unselectedBoardColor.cgColor
            default:
                break
            }
            
            layoutIfNeeded()
        }
    }
    
    override func layoutIfNeeded() {
        super.layoutIfNeeded()
        
        guard let label = titleLabel,
              let text = label.text else {
                  return
              }
        let textWidth = text.agora_size(font: label.font).width
        
        width = (textWidth > width) ? textWidth : width
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initViews()
        initViewFrame()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initViews() {
        let itemSubmit = UIConfig.popupQuiz.submit
        titleLabel?.font = itemSubmit.font
    }
    
    func initViewFrame() {
        let itemSubmit = UIConfig.popupQuiz.submit
        layer.borderWidth = itemSubmit.boardWidth
        layer.cornerRadius = itemSubmit.cornerRadius
    }
    
    func updateViewProperties() {
        let state = quizState
        quizState = state
    }
}

class AgoraPopupQuizView: UIView, AgoraUIContentContainer {
    // View
    let optionCollectionView = AgoraPopupQuizOptionCollectionView()
    let topView = AgoraPopupQuizTopView()
    let button = AgoraPopupQuizButton()
    let resultTableView = AgoraPopupQuizResultTableView()
    
    // Frame
    private(set) var unfinishedNeededSize = CGSize(width: 180,
                                                   height: 106)
    
    let finishedNeededSize = CGSize(width: 180,
                                    height: 142)
    
    private let optionCollectionViewHorizontalSpace: CGFloat = 16
    private let optionCollectionItemSize = CGSize(width: 26,
                                                  height: 26)
    
    var quizState: AgoraPopupQuizState = .unselected {
        didSet {
            button.quizState = quizState
            topView.quizState = quizState
            
            guard quizState == .finished else {
                return
            }
            
            optionCollectionView.isHidden = true
            button.isHidden = true
            resultTableView.isHidden = false
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        initViews()
        initViewFrame()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func collectionViewLayout() {
        let rowCount: CGFloat = 4
        
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        
        let totalSpace = unfinishedNeededSize.width - (optionCollectionViewHorizontalSpace * 2) - (optionCollectionItemSize.width * rowCount)
        let minSpace = totalSpace / (rowCount - 1)
        
        layout.itemSize = optionCollectionItemSize
        
        layout.minimumLineSpacing = minSpace
        
        optionCollectionView.setCollectionViewLayout(layout,
                                                     animated: false)
    }
    
    func initViews() {
        quizState = .unselected
        
        addSubview(topView)
        addSubview(optionCollectionView)
        addSubview(button)
        addSubview(resultTableView)
        
        resultTableView.isHidden = true
        
        layer.borderWidth = 1
        layer.cornerRadius = 6
        layer.masksToBounds = true
    }
    
    func initViewFrame() {
        let topViewWidth = unfinishedNeededSize.width
        let topViewHeight = topView.defaultHeight
        
        topView.frame = CGRect(x: 0,
                               y: 0,
                               width: topViewWidth,
                               height: topViewHeight)
        
        let resultTableViewY: CGFloat = topView.frame.maxY + 20
        let resultTableViewWidth: CGFloat = finishedNeededSize.width
        let resultTableViewHeight: CGFloat = finishedNeededSize.height
        
        resultTableView.frame = CGRect(x: 0,
                                       y: resultTableViewY,
                                       width: resultTableViewWidth,
                                       height: resultTableViewHeight)
        
        collectionViewLayout()
    }
    
    func updateViewProperties() {
        let component = UIConfig.popupQuiz
        
        backgroundColor = component.backgroundColor
        layer.borderColor = component.boardColor.cgColor
        
        agora_all_sub_views_update_view_properties()
    }
    
    func updateUnfinishedViewFrame(optionCount: Int) {
        let optionCollectionViewX = optionCollectionViewHorizontalSpace
        let optionCollectionViewY = topView.frame.maxY + 15
        let optionCollectionViewWidth = unfinishedNeededSize.width - (optionCollectionViewHorizontalSpace * 2)
        let optionCollectionViewHeight = (optionCount > 4 ? (optionCollectionItemSize.height * 2 + 10) : optionCollectionItemSize.height)
        
        optionCollectionView.frame = CGRect(x: optionCollectionViewX,
                                            y: optionCollectionViewY,
                                            width: optionCollectionViewWidth,
                                            height: optionCollectionViewHeight)
        
        let buttonWidth: CGFloat = 70
        let buttonHeight: CGFloat = 22
        
        let buttonX = (unfinishedNeededSize.width - buttonWidth) * 0.5
        let buttonY = optionCollectionView.frame.maxY + 15
        
        button.frame = CGRect(x: buttonX,
                              y: buttonY,
                              width: buttonWidth,
                              height: buttonHeight)
        button.layoutIfNeeded()
        
        let buttonBottomSpace: CGFloat = 10
        let newHeight: CGFloat = button.frame.maxY + buttonBottomSpace
        let newWidth: CGFloat = unfinishedNeededSize.width
        
        let newSize = CGSize(width: newWidth,
                             height: newHeight)
        
        unfinishedNeededSize = newSize
    }
}
