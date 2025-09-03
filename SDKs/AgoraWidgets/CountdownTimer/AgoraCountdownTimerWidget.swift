//
//  AgoraCountdownWidget.swift
//  AgoraWidgets
//
//  Created by LYY on 2022/3/5.
//

import AgoraWidget
import AgoraFoundation


@objcMembers public class AgoraCountdownTimerWidget: AgoraNativeWidget {
    private var timer: Timer?
    
    // View
    private var countdownView = AgoraCountdownView(frame: .zero)

    // Original Data
    private var roomData: AgoraCountdownRoomData?
    // 客户端与服务端时间差(milliseconds)
    private var timeDiff: Int64 = 0 {
        didSet {
            guard timeDiff != oldValue else {
                return
            }
            updateRemainSeconds()
        }
    }
    
    // View Data
    private var countdownState: AgoraCountdownState = .end {
        didSet {
            guard countdownState != oldValue else {
                return
            }
            switch countdownState {
            case .duration:
                view.isHidden = false
                countdownView.timePageColor = .normal
                startTimer()
            case .end:
                view.isHidden = true
                countdownView.timePageColor = .warning
                stopTimer()
            }
        }
    }
    // 计时器剩余秒(second)
    private var remainSeconds: Int64 = 0 {
        didSet {
            if remainSeconds > 3 {
                countdownView.timePageColor = .normal
            } else {
                countdownView.timePageColor = .warning
            }
            
            let timeString = remainSeconds.formatStringMS.replacingOccurrences(of: ":",
                                                                               with: "")
            let array = timeString.map({String($0)})
            
            countdownView.updateTimePages(timeList: array)
        }
    }
    
    public override func onLoad() {
        super.onLoad()
        initViews()
        initConstraints()
        updateData()
        updateViewFrame()
    }
    
    public override func onWidgetRoomPropertiesUpdated(_ properties: [String : Any],
                                                       cause: [String : Any]?,
                                                       keyPaths: [String],
                                                       operatorUser: AgoraWidgetUserInfo?) {
        super.onWidgetRoomPropertiesUpdated(properties,
                                            cause: cause,
                                            keyPaths: keyPaths,
                                            operatorUser: operatorUser)
        updateData()
    }
    
    public override func onMessageReceived(_ message: String) {
        super.onMessageReceived(message)
        
        if let serverTime = message.toSyncTimestamp() {
            timeDiff = serverTime - Int64(Date().timeIntervalSince1970) * 1000
        }
    }
    
    deinit {
        stopTimer()
    }
}

// MARK: - View
private extension AgoraCountdownTimerWidget {
    func initViews() {
        view.addSubview(countdownView)
    }
    
    func initConstraints() {
        countdownView.agora_mas_makeConstraints { (make) in
            make?.left.right()?.bottom()?.top()?.equalTo()(0)
        }
    }
    
    func updateViewFrame() {
        let size = ["width": countdownView.neededSize.width,
                    "height": countdownView.neededSize.height]
        
        guard let message = ["size": size].jsonString() else {
            return
        }
        
        sendMessage(message)
    }
}

// MARK: - Data
private extension AgoraCountdownTimerWidget {
    func updateData() {
        guard let roomProperties = info.roomProperties,
              let data = roomProperties.toObject(AgoraCountdownRoomData.self) else {
            return
        }
        roomData = data
        updateRemainSeconds()
        countdownState = data.state
    }
    
    func updateRemainSeconds() {
        guard let data = roomData else {
            return
        }
        if data.duration == 0 {
            remainSeconds = 0
        } else {
            // 服务端预期结束时间: milliseconds
            let serverEndTime = data.startTime + (data.duration * 1000)
            // 本地预期结束时间: milliseconds
            // equation: serverTime - localtime = serverEndTime - localEndTime
            let localEndTime = serverEndTime - timeDiff
            var remain = (localEndTime / 1000) - Int64(Date().timeIntervalSince1970)
            remainSeconds = (remain < 0) ? 0 : remain
        }
    }
}

private extension AgoraCountdownTimerWidget {
    func startTimer() {
        guard self.timer == nil else {
            return
        }
        
        func fireTimer() {
            let timer = Timer.scheduledTimer(withTimeInterval: 1,
                                             repeats: true,
                                             block: { [weak self] _ in
                guard let strongSelf = self else {
                    return
                }
                
                if strongSelf.remainSeconds <= 0 {
                    strongSelf.stopTimer()
                } else {
                    strongSelf.remainSeconds -= 1
                }
            })
            
            RunLoop.main.add(timer,
                             forMode: .common)
            timer.fire()
            self.timer = timer
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            fireTimer()
        }
    }
    
    func stopTimer() {
        guard timer != nil else {
            return
        }
        timer?.invalidate()
        timer = nil
    }
}
