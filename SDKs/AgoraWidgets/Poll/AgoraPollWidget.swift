//
//  AgoraPollWidget.swift
//  AgoraClassroomSDK_iOS
//
//  Created by LYY on 2022/3/1.
//

import AgoraWidget
import AgoraFoundation
import Masonry

@objcMembers public class AgoraPollWidget: AgoraNativeWidget {
    private var serverAPI: AgoraPollServerAPI?

    // Origin Data
    private var roomData: AgoraPollRoomPropertiesData?
    private var userData: AgoraPollUserPropertiesData?
    private var baseInfo: AgoraWidgetRequestKeys?
    
    // View Data
    private var state: AgoraPollViewState = .unselected {
        didSet {
            receiverView.state = state
            
            if state == .finished {
                updateViewFrame()
                receiverView.tableView.reloadData()
            }
        }
    }
    
    private var selectedMode: AgoraPollViewSelectedMode = .single {
        didSet {
            receiverView.selectedMode = selectedMode
        }
    }
    
    private var title: AgoraPollViewTitle?
    
    private var optionList: AgoraPollViewOptionList? {
        didSet {
            guard state != .finished,
                  let list = optionList  else {
                return
            }
            
            let hasSelected = list.items.contains(where: {$0.isSelected == true})
            
            state = (hasSelected ? .selected : .unselected)
        }
    }
    
    private var resultList: AgoraPollViewResultList?
    
    // View
    private let receiverView = AgoraPollReceiverView()
    
    // MARK: widget callback
    public override func onLoad() {
        super.onLoad()
        initViews()
        initViewFrame()
        updateViewProperties()
        
        updateRoomData()
        updateUserData()
        updateViewData()
    }
    
    public override func onWidgetRoomPropertiesUpdated(_ properties: [String : Any],
                                                       cause: [String : Any]?,
                                                       keyPaths: [String],
                                                       operatorUser: AgoraWidgetUserInfo?) {
        super.onWidgetRoomPropertiesUpdated(properties,
                                            cause: cause,
                                            keyPaths: keyPaths,
                                            operatorUser: operatorUser)
        updateRoomData()
        updateViewData()
    }
    
    public override func onWidgetUserPropertiesUpdated(_ properties: [String : Any],
                                                       cause: [String : Any]?,
                                                       keyPaths: [String],
                                                       operatorUser: AgoraWidgetUserInfo?) {
        super.onWidgetUserPropertiesUpdated(properties,
                                            cause: cause,
                                            keyPaths: keyPaths,
                                            operatorUser: operatorUser)
        updateUserData()
    }

    public override func onMessageReceived(_ message: String) {
        super.onMessageReceived(message)
        
        if let keys = message.toRequestKeys() {
            serverAPI = AgoraPollServerAPI(host: keys.host,
                                           appId: keys.agoraAppId,
                                           token: keys.token,
                                           roomId: info.roomInfo.roomUuid,
                                           userId: info.localUserInfo.userUuid,
                                           logTube: self.logger)
        }
        
        if message == "hideSubmit" {
            receiverView.submitButton.isHidden = true
        }
    }
    
    @objc func doButtonPressed(_ sender: UIButton) {
        submitSelectedList()
    }
}

extension AgoraPollWidget: AgoraUIContentContainer {
    public func initViews() {
        view.addSubview(receiverView)
        
        receiverView.tableView.delegate = self
        receiverView.tableView.dataSource = self
        
        receiverView.submitButton.addTarget(self,
                                            action: #selector(doButtonPressed(_:)),
                                            for: .touchUpInside)
    }
    
    public func initViewFrame() {
        receiverView.mas_makeConstraints { (make) in
            make?.top.bottom()?.right()?.left()?.equalTo()(0)
        }
    }
    
    public func updateViewProperties() {
        let component = UIConfig.poll
        
        view.backgroundColor = .clear
        view.layer.update(with: component.shadow)
        
        receiverView.updateViewProperties()
    }
    
    func updateViewFrame() {
        var tableHeight: CGFloat = 0
        
        if state == .finished,
           let list = resultList {
            tableHeight = list.height
        } else if let list = optionList {
            tableHeight = list.height
        }
        
        guard let titleHeight = title?.titleSize.height else {
            return
        }
        
        receiverView.updateViewFrame(titleHeight: titleHeight,
                                     tableHeight: tableHeight)
        
        let size = ["width": receiverView.neededSize.width,
                    "height": receiverView.neededSize.height]
        
        guard let message = ["size": size].jsonString() else {
            return
        }
        
        sendMessage(message)
    }
}

private extension AgoraPollWidget {
    func updateRoomData() {
        guard let roomProps = info.roomProperties,
           let data = roomProps.toObject(AgoraPollRoomPropertiesData.self) else {
            return
        }
        
        roomData = data
    }
    
    func updateUserData() {
        guard let userProps = info.localUserProperties,
              let userData = userProps.toObject(AgoraPollUserPropertiesData.self),
              let data = roomData,
              userData.pollId == data.pollId else {
            return
        }
        
        self.userData = userData
    }
    
    func updateViewData() {
        guard let data = roomData else {
            return
        }
        
        let itemOption = UIConfig.poll.option
        let itemResult = UIConfig.poll.result
        
        if let state = data.toPollViewState() { // finished
            self.state = state
        } else if let _ = userData { // submited
            self.state = .finished
        }
   
        // title
        let titleFont = FcrWidgetUIFontGroup.font9
        let poll_title_label_horizontal_space: CGFloat = 15
        let limitWidth = receiverView.neededSize.width - poll_title_label_horizontal_space * 2
        
        title = data.toViewTitle(font: titleFont,
                                 limitWidth: limitWidth)
        receiverView.titleLabel.text = title?.title
        
        // option
        let optionLabelFont: UIFont = FcrWidgetUIFontGroup.font9
        let optionWidth = receiverView.neededSize.width
        
        let optionLabelInsets = UIEdgeInsets(top: itemOption.labelVerticalSpace,
                                             left: itemOption.labelLeftSpace,
                                             bottom: itemOption.labelVerticalSpace,
                                             right: itemOption.labelRightSpace)
        
        optionList = data.toPollViewOptionList(optionFont: optionLabelFont,
                                               optionLabelInsets: optionLabelInsets,
                                               optionWidth: optionWidth)
        
        // result
        let resultLabelFont = FcrWidgetUIFontGroup.font9
        let resultWidth = receiverView.neededSize.width
        
        let resultTitleLabelInsetsRight = (itemResult.labelWidth + itemResult.labelHorizontalSpace)
        
        let resultTitleLabelInsets = UIEdgeInsets(top: itemResult.labelVerticalSpace,
                                                  left: itemResult.labelHorizontalSpace,
                                                  bottom: itemResult.labelVerticalSpace,
                                                  right: resultTitleLabelInsetsRight)
        
        resultList = data.toPollViewResultList(resultFont: resultLabelFont,
                                               resultTitleLabelInsets: resultTitleLabelInsets,
                                               resultWidth: resultWidth)
        
        // mode
        selectedMode = data.toPollViewSelectedMode()
        
        updateViewFrame()
        
        receiverView.tableView.reloadData()
    }
    
    func findSelectedList() -> [Int] {
        var array = [Int]()
        
        guard let list = optionList else {
            return array
        }
        
        for index in 0..<list.items.count {
            let option = list.items[index]
            
            guard option.isSelected else {
                continue
            }
            
            array.append(index)
        }
        
        return array
    }
    
    func submitSelectedList() {
        guard let data = roomData,
              let server = serverAPI else {
            return
        }
        
        let list = findSelectedList()
        
        server.submit(pollId: data.pollId,
                      selectList: list) { [weak self] in
            guard let strongSelf = self else {
                return
            }
            
            strongSelf.state = .finished
        }
    }
}

extension AgoraPollWidget: UITableViewDataSource, UITableViewDelegate {
    public func tableView(_ tableView: UITableView,
                          numberOfRowsInSection section: Int) -> Int {
        if state == .finished,
           let list = resultList {
            return list.items.count
        } else if let list = optionList {
            return list.items.count
        } else {
            return 0
        }
    }
    
    public func tableView(_ tableView: UITableView,
                          cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell: UITableViewCell
        
        if state == .finished {
            let cellId = AgoraPollResultCell.cellId
            let resultCell = tableView.dequeueReusableCell(withIdentifier: cellId,
                                                           for: indexPath) as! AgoraPollResultCell
            
            let item = resultList!.items[indexPath.row]
            resultCell.titleLabel.text = item.title
            resultCell.resultLabel.text = item.result
            resultCell.resultProgressView.progress = item.percentage
            
            cell = resultCell
        } else {
            let cellId = AgoraPollOptionCell.cellId
            let optionCell = tableView.dequeueReusableCell(withIdentifier: cellId,
                                                           for: indexPath) as! AgoraPollOptionCell
            
            let item = optionList!.items[indexPath.row]
            optionCell.selectedMode = selectedMode
            optionCell.optionLabel.text = item.title
            optionCell.optionIsSelected = item.isSelected
            
            cell = optionCell
        }
        
        return cell
    }
    
    public func tableView(_ tableView: UITableView,
                          didSelectRowAt indexPath: IndexPath) {
        guard state != .finished,
              var list = optionList else {
            return
        }
        
        var reloadRows = [IndexPath]()
        
        if selectedMode == .single,
           let index = list.items.firstIndex(where: {$0.isSelected == true}) {
            var item = list.items[index]
            item.isSelected.toggle()
            list.items[index] = item
            
            let oldSelected = IndexPath(row: index,
                                        section: 0)
            
            reloadRows.append(oldSelected)
        }
        
        var item = list.items[indexPath.row]
        item.isSelected.toggle()
        list.items[indexPath.row] = item
        
        optionList = list
        
        reloadRows.append(indexPath)
        
        tableView.reloadRows(at: reloadRows,
                             with: .none)
    }
    
    public func tableView(_ tableView: UITableView,
                   heightForRowAt indexPath: IndexPath) -> CGFloat {
        if state == .finished,
           let list = resultList {
            return list.items[indexPath.row].height
        } else if let list = optionList {
            return list.items[indexPath.row].height
        } else {
            return 0
        }
    }
}
