//
//  FcrBoardProtocols.swift
//  AgoraWidgets
//
//  Created by Cavan on 2022/6/8.
//

import Foundation
import Whiteboard

// Public
protocol FcrBoardRoomDelegate: NSObjectProtocol {
    func onConnectionStateUpdated(state: FcrBoardRoomConnectionState)
    func onSlideError(slideError: WhiteSlideErrorType, errorMessage: String, slideId: String, slideIndex: Int)
}

protocol FcrBoardMainWindowDelegate: FcrBoardAudioMixingDelegate {
    func onPageInfoUpdated(info: FcrBoardPageInfo)
    
    func onUndoStateUpdated(enable: Bool)
    
    func onRedoStateUpdated(enable: Bool)
    
    func onWindowBoxStateChanged(state: FcrWindowBoxState)
}

protocol FcrBoardLogTube: NSObjectProtocol {
    func onBoardLog(content: String,
                    extra: String?,
                    type: FcrBoardLogType,
                    fromClass: AnyClass,
                    funcName: String,
                    line: Int)
    
    func onNetlessLog(content: String,
                      extra: String?,
                      type: FcrBoardLogType)
}

extension FcrBoardLogTube {
    func onNetlessLog(content: String,
                      extra: String?,
                      type: FcrBoardLogType) {
        
    }
}

protocol FcrBoardAudioMixingDelegate: NSObjectProtocol {
    func onStartAudioMixing(filePath: String,
                            loopback: Bool,
                            replace: Bool,
                            cycle: Int)
    
    func onPauseAudioMixing()
    
    func onResumeAudioMixing()
    
    func onStopAudioMixing()
    
    func onAudioMixingPositionUpdated(position: Int)
}

// Internal
protocol FcrBoardMainWindowNeedObserve: FcrBoardAudioMixingDelegate {
    func onRoomStateChanged(_ modifyState: WhiteRoomState)
    
    func onCanRedoStepsUpdate(_ canRedoSteps: Int)
    
    func onCanUndoStepsUpdate(_ canUndoSteps: Int)
}

protocol FcrBoardRoomNeedObserve: NSObjectProtocol {
    func onPhaseChanged(_ phase: WhiteRoomPhase)
    
    func onLogger(_ dict: [AnyHashable : Any])
    
    func onThrowError(_ error: Error)
}
