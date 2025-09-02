//
//  AgoraPopupQuizWidget.swift
//  AgoraClassroomSDK_iOS
//
//  Created by Cavan on 2022/3/5.
//

import AgoraWidget
import AgoraFoundation
import UIKit

@objcMembers public class AgoraPopupQuizWidget: AgoraNativeWidget {
    private var serverAPI: AgoraPopupQuizServerAPI?
    private var timer: Timer?
    
    // View
    private let contentView = AgoraPopupQuizView() // for mask shadowo
    
    // View Data
    private var optionList = [AgoraPopupQuizOption]() {
        didSet {
            if let _ = optionList.first(where: {$0.isSelected}) {
                quizState = .selected
            } else {
                quizState = .unselected
            }
        }
    }
    
    private var resultList = [AgoraPopupQuizResult]()
    
    private var quizState: AgoraPopupQuizState = .unselected {
        didSet {
            contentView.quizState = quizState
            contentView.optionCollectionView.reloadData()
        }
    }
    
    // Origin Data
    private var requestKeys: AgoraWidgetRequestKeys?
    
    private var roomData: AgoraPopupQuizRoomPropertiesData?
    private var userData: AgoraPopupQuizUserPropertiesData?
    
    private var objectCreateTimestamp: Int64? // millisecond
    
    private var currentTimestamp: Int64 = 0 { // second
        didSet {
            let timeString = currentTimestamp.formatStringHMS
            contentView.topView.update(timeString: timeString)
        }
    }
    
    public override func onLoad() {
        super.onLoad()
        initViews()
        initViewFrame()
        updateViewProperties()
        
        updateRoomData()
        updateUserData()
        initViewData()
        
        updateViewFrame()
        initServerAPI()
    }
    
    public override func onMessageReceived(_ message: String) {
        super.onMessageReceived(message)
        
        if let keys = message.toRequestKeys() {
            requestKeys = keys
            initServerAPI()
        }
        
        if let timestamp = message.toSyncTimestamp() {
            objectCreateTimestamp = timestamp
            initCurrentTimestamp()
            shouldStartTime()
        }
        
        if message == "hideSubmit" {
            contentView.button.isHidden = true
        }
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
        updateViewFrame()
        shouldStartTime()
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
    
    @objc func doButtonPressed(_ sender: UIButton) {
        switch quizState {
        case .selected:
            submitAnswer()
        case .changing:
            quizState = .selected
        default:
            break
        }
    }
    
    deinit {
        stopTimer()
    }
}

// MARK: - View
extension AgoraPopupQuizWidget: AgoraUIContentContainer {
    public func initViews() {
        let component = UIConfig.popupQuiz
        
        quizState = .unselected
        
        view.addSubview(contentView)
       
        contentView.optionCollectionView.dataSource = self
        contentView.optionCollectionView.delegate = self
        
        contentView.resultTableView.dataSource = self
        
        contentView.button.addTarget(self,
                                     action: #selector(doButtonPressed(_:)),
                                     for: .touchUpInside)
    }
    
    public func initViewFrame() {
        contentView.agora_mas_makeConstraints { (make) in
            make?.top.left()?.right()?.bottom()?.equalTo()(0)
        }
    }
    
    public func updateViewProperties() {
        let component = UIConfig.popupQuiz
        
        view.backgroundColor = .clear
        
        view.layer.update(with: component.shadow)
        
        contentView.updateViewProperties()
    }
    
    private func updateViewFrame() {
        var size: [String: Any]
        
        if quizState != .finished {
            contentView.updateUnfinishedViewFrame(optionCount: optionList.count)
            
            size = ["width": contentView.unfinishedNeededSize.width,
                    "height": contentView.unfinishedNeededSize.height]
        } else {
            size = ["width": contentView.finishedNeededSize.width,
                    "height": contentView.finishedNeededSize.height]
        }
        
        guard let message = ["size": size].jsonString() else {
            return
        }
        
        sendMessage(message)
    }
}

// MAKR: - Data
private extension AgoraPopupQuizWidget {
    func updateRoomData() {
        guard let roomProperties = info.roomProperties,
              let data = roomProperties.toObject(AgoraPopupQuizRoomPropertiesData.self) else {
            return
        }

        roomData = data
    }
    
    func updateUserData() {
        guard let userProperties = info.localUserProperties,
              let data = userProperties.toObject(AgoraPopupQuizUserPropertiesData.self) else {
            return
        }
        
        userData = data
    }
    
    func initViewData() {
        guard let data = roomData else {
            return
        }
        
        if let state = data.toViewSelectorState() {
            quizState = state // .end
            initResultList()
        } else {
            initOptionList()
        }
        
        // if 'changing' state
        guard let `userData` = userData else {
            return
        }
        
        guard let leftList = findMyAnswerFromUserData(),
              let rightList = findMyAnswerFromOptionList(),
              leftList == rightList else {
            return
        }
        
        quizState = .changing
    }
    
    func updateViewData() {
        guard let data = roomData else {
            return
        }
        
        guard let state = data.toViewSelectorState() else {
            return
        }
        
        quizState = state // .end
        initResultList()
    }
        
    func initOptionList() {
        guard let data = roomData else {
            return
        }
        
        optionList = data.toViewSelectorOptionList(myAnswer: findMyAnswer())
        contentView.optionCollectionView.reloadData()
    }
    
    func initResultList() {
        guard let data = roomData else {
            return
        }
        
        let font = AgoraPopupQuizResultCell.font
        resultList = data.toViewSelectorResultList(font: font,
                                                   fontHeight: contentView.resultTableView.rowHeight,
                                                   myAnswer: findMyAnswer())
        contentView.resultTableView.reloadData()
    }
        
    func findMyAnswer() -> [String]? {
        var selectedItems: [String]?
        
        if let list = findMyAnswerFromOptionList() {
            selectedItems = list
        } else if let list = findMyAnswerFromUserData() {
            selectedItems = list
        }
        
        return selectedItems
    }
    
    func findMyAnswerFromOptionList() -> [String]? {
        var selectedItems = [String]()
        
        for item in optionList where item.isSelected {
            selectedItems.append(item.title)
        }
        
        if selectedItems.count == 0 {
            return nil
        } else {
            return selectedItems
        }
    }
    
    func findMyAnswerFromUserData() -> [String]? {
        var selectedItems = [String]()
        
        if selectedItems.count == 0,
           let `roomData` = roomData,
           let `userData` = userData,
           roomData.popupQuizId == userData.popupQuizId {
            for item in userData.selectedItems {
                selectedItems.append(item)
            }
        }
        
        if selectedItems.count == 0 {
            return nil
        } else {
            return selectedItems
        }
    }
    
    func initCurrentTimestamp() {
        guard let data = roomData,
              let objectCreate = objectCreateTimestamp else {
            return
        }
        
        // init timer
        let start = data.receiveQuestionTime
        let diff = objectCreate - start
        let msTimestamp = (diff < 0) ? 0 : diff                    // millisecond
        currentTimestamp = Int64(TimeInterval(msTimestamp) / 1000) // second
    }
}

private extension AgoraPopupQuizWidget {
    func initServerAPI() {
        guard let keys = requestKeys,
              let data = roomData,
              serverAPI == nil else {
            return
        }
        
        serverAPI = AgoraPopupQuizServerAPI(host: keys.host,
                                            appId: keys.agoraAppId,
                                            token: keys.token,
                                            roomId: info.roomInfo.roomUuid,
                                            userId: info.localUserInfo.userUuid,
                                            logTube: self.logger)
    }
    
    func shouldStartTime() {
        if quizState != .finished {
            startTimer()
        } else {
            stopTimer()
        }
    }
    
    func startTimer() {
        guard self.timer == nil else {
            return
        }
        
        let timer = Timer.scheduledTimer(withTimeInterval: 1,
                                         repeats: true,
                                         block: { [weak self] _ in
                                            guard let strongSelf = self else {
                                                return
                                            }
                                            
                                            strongSelf.currentTimestamp += 1
        })
        
        RunLoop.main.add(timer,
                         forMode: .common)
        timer.fire()
        self.timer = timer
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

private extension AgoraPopupQuizWidget {
    func submitAnswer() {
        guard let api = serverAPI,
              let data = roomData,
              let myAnswer = findMyAnswer() else {
            return
        }
        
        api.submitAnswer(myAnswer,
                         selectorId: data.popupQuizId) { [weak self] in
            guard let `self` = self else {
                return
            }
            self.quizState = .changing
        }
    }
}

extension AgoraPopupQuizWidget: UICollectionViewDataSource, UICollectionViewDelegate {
    public func collectionView(_ collectionView: UICollectionView,
                               numberOfItemsInSection section: Int) -> Int {
        return optionList.count
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                               cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let option = optionList[indexPath.item]
        let cell = collectionView.dequeueReusableCell(withClass: AgoraPopupQuizOptionCell.self,
                                                      for: indexPath)
        cell.optionLabel.text = option.title
        cell.optionIsSelected = option.isSelected
        cell.isEnable = !(quizState == .changing)
        return cell
    }
    
    public func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        var option = optionList[indexPath.item]
        option.isSelected.toggle()
        optionList[indexPath.item] = option
        collectionView.reloadItems(at: [indexPath])
    }
}

extension AgoraPopupQuizWidget: UITableViewDataSource {
    public func tableView(_ tableView: UITableView,
                          numberOfRowsInSection section: Int) -> Int {
        return resultList.count
    }
    
    public func tableView(_ tableView: UITableView,
                          cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let result = resultList[indexPath.row]
        
        let cell = tableView.dequeueReusableCell(withIdentifier: AgoraPopupQuizResultCell.cellId,
                                                 for: indexPath) as! AgoraPopupQuizResultCell
        let labelHeight = tableView.rowHeight
        
        cell.titleLabel.text = result.title
        cell.resultLabel.text = result.result
        cell.titleLabel.frame = CGRect(x: 40,
                                       y: 0,
                                       width: result.titleSize.width,
                                       height: labelHeight)
        
        cell.resultLabel.frame = CGRect(x: cell.titleLabel.frame.maxX,
                                        y: 0,
                                        width: 100,
                                        height: labelHeight)
        
        if let color = result.resultColor {
            cell.resultLabel.textColor = color
        }
        
        return cell
    }
}

fileprivate extension Array where Element == String {
    static func==(left: [String],
                  right: [String]) -> Bool {
        let leftString = left.joined(separator: "")
        let rightString = right.joined(separator: "")
        
        return (leftString == rightString)
    }
}
