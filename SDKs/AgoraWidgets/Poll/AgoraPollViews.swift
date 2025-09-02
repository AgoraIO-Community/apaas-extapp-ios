//
//  AgoraPollViews.swift
//  AgoraWidgets
//
//  Created by Cavan on 2022/3/11.
//

import AgoraUIBaseViews

import UIKit

class AgoraPollHeaderView: UIView, AgoraUIContentContainer {
    private let label = UILabel()
    private let lineLayer = CALayer()
    
    var selectedMode: AgoraPollViewSelectedMode = .single {
        didSet {
            updateTitle()
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
    
    override func layoutSubviews() {
        super.layoutSubviews()
        lineLayer.frame = CGRect(x: 0,
                                 y: bounds.height,
                                 width: bounds.width,
                                 height: 1)
    }
    
    func initViews() {
        let itemName = UIConfig.poll.name
        label.font = itemName.font
        
        addSubview(label)
        layer.addSublayer(lineLayer)
        
        updateTitle()
    }
    
    func initViewFrame() {
        label.agora_mas_makeConstraints { (make) in
            make?.left.equalTo()(8)
            make?.top.bottom()?.right().equalTo()(0)
        }
    }
    
    func updateViewProperties() {
        let itemLine = UIConfig.poll.sepLine
        let itemName = UIConfig.poll.name
        
        label.textColor = itemName.textColor
        
        lineLayer.backgroundColor = itemLine.backgroundColor.cgColor
    }
    
    private func updateTitle() {
        let itemName = UIConfig.poll.name
        
        let title = itemName.text
        
        let isSingle = (selectedMode == .single)
        
        let mode = (isSingle ? itemName.singleMode : itemName.multiMode)
        
        let fullTitle = title + "  " + "(\(mode))"
        
        label.text = fullTitle
    }
}

class AgoraPollTitleLabel: UILabel, AgoraUIContentContainer {
    override init(frame: CGRect) {
        super.init(frame: frame)
        initViews()
        initViewFrame()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initViews() {
        let itemTitle = UIConfig.poll.title
        font = itemTitle.font
        numberOfLines = 0
    }
    
    func initViewFrame() {
        
    }
    
    func updateViewProperties() {
        let itemTitle = UIConfig.poll.title
        textColor = itemTitle.textColor
    }
}

class AgoraPollOptionCell: UITableViewCell, AgoraUIContentContainer {
    static let cellId = NSStringFromClass(AgoraPollOptionCell.self)
    
    private let optionImageView = UIImageView()
    private let sepLine = UIView()
    
    let optionLabel = UILabel()
    
    // set 'selectedMode' before 'optionIsSelected'
    var selectedMode: AgoraPollViewSelectedMode = .single
    
    var optionIsSelected: Bool = false {
        didSet {
            setOptionImage()
        }
    }
    
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
    
    private func setOptionImage() {
        let itemOption = UIConfig.poll.option
        
        var image: UIImage?
        
        switch selectedMode {
        case .single:
            image = (optionIsSelected ? itemOption.selectedSingleModeImage : itemOption.unselectedSingleModeImage)
        case .multi:
            image = (optionIsSelected ? itemOption.selectedMultiModeImage : itemOption.unselectedMultiModeImage)
        default:
            fatalError()
        }
        
        optionImageView.image = image
    }
    
    func initViews() {
        let itemLine = UIConfig.poll.sepLine
        let itemOption = UIConfig.poll.option
        
        selectionStyle = .none
        
        optionLabel.font = itemOption.font
        optionLabel.numberOfLines = 0
        
        addSubviews([optionImageView,
                     optionLabel,
                     sepLine])
    }
    
    func initViewFrame() {
        let itemOption = UIConfig.poll.option
        
        let horizontalSpace: CGFloat = 15
        
        optionImageView.agora_mas_makeConstraints { make in
            make?.left.equalTo()(horizontalSpace)
            make?.top.equalTo()(5)
            make?.width.height().equalTo()(12)
        }
        
        let labelTop: CGFloat = itemOption.labelVerticalSpace
        let labelBottom: CGFloat = itemOption.labelVerticalSpace
        let labelLeft: CGFloat = itemOption.labelLeftSpace
        let labelRight: CGFloat = itemOption.labelRightSpace

        optionLabel.agora_mas_makeConstraints { make in
            make?.top.equalTo()(0)
            make?.left.equalTo()(labelLeft)
            make?.right.equalTo()(-labelRight)
            make?.bottom.equalTo()(-0)
        }
        
        sepLine.agora_mas_makeConstraints { make in
            make?.left.equalTo()(horizontalSpace)
            make?.right.equalTo()(-horizontalSpace)
            make?.height.equalTo()(1)
            make?.bottom.equalTo()(0)
        }
    }
    
    func updateViewProperties() {
        let itemLine = UIConfig.poll.sepLine
        sepLine.backgroundColor = itemLine.backgroundColor
    }
}

class AgoraPollResultCell: UITableViewCell, AgoraUIContentContainer {
    static let cellId = NSStringFromClass(AgoraPollResultCell.self)
    
    /**Views**/
    let titleLabel = UILabel()
    let resultLabel = UILabel()
    let resultProgressView = UIProgressView()
    
    override init(style: UITableViewCell.CellStyle,
                  reuseIdentifier: String?) {
        super.init(style: style,
                   reuseIdentifier: reuseIdentifier)
        initViews()
        initViewFrame()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initViews() {
        let itemResult = UIConfig.poll.result
        
        selectionStyle = .none
        
        titleLabel.font = itemResult.font
        titleLabel.textAlignment = itemResult.titleTextAlignment
        titleLabel.numberOfLines = 0
        
        resultLabel.font = itemResult.font
        resultLabel.textAlignment = itemResult.resultTextAlignment
        resultLabel.adjustsFontSizeToFitWidth = true
        resultLabel.sizeToFit()
        
        resultProgressView.layer.cornerRadius = 1.5
        
        addSubviews([titleLabel,
                     resultLabel,
                     resultProgressView])
    }
    
    func initViewFrame() {
        let itemResult = UIConfig.poll.result
        
        resultLabel.agora_mas_makeConstraints { (make) in
            make?.top.equalTo()(0)
            make?.right.equalTo()(-itemResult.labelHorizontalSpace)
            make?.width.equalTo()(itemResult.labelWidth)
            make?.bottom.equalTo()(0)
        }
        
        titleLabel.agora_mas_makeConstraints { make in
            make?.top.equalTo()(0)
            make?.left.equalTo()(itemResult.labelHorizontalSpace)
            make?.right.equalTo()(resultLabel.agora_mas_left)
            make?.bottom.equalTo()(0)
        }
        
        resultProgressView.agora_mas_makeConstraints { make in
            make?.left.equalTo()(itemResult.labelHorizontalSpace)
            make?.right.equalTo()(-itemResult.labelHorizontalSpace)
            make?.bottom.equalTo()(0)
            make?.height.equalTo()(1)
        }
    }
    
    func updateViewProperties() {
        let itemResult = UIConfig.poll.result
        
        titleLabel.textColor = itemResult.textColor
        resultLabel.textColor = itemResult.textColor
        
        resultProgressView.trackTintColor = itemResult.progressTrackTintColor
        resultProgressView.progressTintColor = itemResult.progressTintColor
    }
}

class AgoraPollTableView: UITableView, AgoraUIContentContainer {
    var state: AgoraPollViewState = .unselected {
        didSet {
            switch state {
            case .finished:
                register(AgoraPollResultCell.self,
                         forCellReuseIdentifier: AgoraPollResultCell.cellId)
            default:
                break
            }
        }
    }
    
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
        register(AgoraPollOptionCell.self,
                 forCellReuseIdentifier: AgoraPollOptionCell.cellId)
    }
    
    func initViewFrame() {
        rowHeight = 22
    }
    
    func updateViewProperties() {
        let cells = visibleCells
        
        for cell in cells {
            guard let item = cell as? AgoraUIContentContainer else {
                continue
            }
            
            item.updateViewProperties()
        }
    }
}

class AgoraPollSubmitButton: UIButton, AgoraUIContentContainer {
    var pollState: AgoraPollViewState = .unselected {
        didSet {
            switch pollState {
            case .unselected:
                isEnabled = false
                backgroundColor = UIColor(hexString: "#C0D6FF")
            case .selected:
                isEnabled = true
                backgroundColor = UIColor(hexString: "#357BF6")
            case .finished:
                isHidden = true
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
        let itemSubmit = UIConfig.poll.submit
        
        titleLabel?.font = itemSubmit.font
        
        setTitle(itemSubmit.text,
                 for: .normal)
        setTitle(itemSubmit.text,
                 for: .disabled)
    }
    
    func initViewFrame() {
        let itemSubmit = UIConfig.poll.submit
        layer.cornerRadius = itemSubmit.cornerRadius
    }
    
    func updateViewProperties() {
        let itemSubmit = UIConfig.poll.submit
        
        setTitleColor(itemSubmit.textColor,
                      for: .normal)
        setTitleColor(itemSubmit.textColor,
                      for: .disabled)
        
        let state = pollState
        pollState = state
    }
}
