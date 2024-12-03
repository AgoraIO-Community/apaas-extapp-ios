//
//  FcrBoardListener.swift
//  AgoraWidgets
//
//  Created by Cavan on 2022/6/8.
//

import AgoraRtcKit
import Foundation
import Whiteboard

class FcrBoardListener: NSObject {
    weak var roomNeedObserve: FcrBoardRoomNeedObserve?
    weak var mainWindowNeedObserve: FcrBoardMainWindowNeedObserve?
    weak var rtc: AgoraRtcEngineKit!
    weak var effectMixer: WhiteAudioEffectMixerBridge?
    weak var logTube: FcrBoardLogTube?
    
    override init() {
        super.init()
        let getRtc = Notification.Name(rawValue: "rtc.engine.object")
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(getRtcObject(_:)),
                                               name: getRtc,
                                               object: nil)
        
        let audioFileInfo = Notification.Name(rawValue: "rtc.engine.audio.file.info")
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(rtcAudioFileInfo(_:)),
                                               name: audioFileInfo,
                                               object: nil)
        
        let audioEffectFinish = Notification.Name(rawValue: "rtc.engine.audio.effect.finish")
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(rtcAudioEffectFinish(_:)),
                                               name: audioEffectFinish,
                                               object: nil)
        
        let audioEffectState = Notification.Name(rawValue: "rtc.engine.audio.effect.state")
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(rtcAudioEffectStateChanged(_:)),
                                               name: audioEffectState,
                                               object: nil)
        
        let needRtc = Notification(name: Notification.Name(rawValue: "need.rtc.engine.object"))
        
        NotificationCenter.default.post(needRtc)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        
        _ = stopAllEffects()
    }
    
    @objc func getRtcObject(_ notification: Notification) {
        rtc = notification.object as? AgoraRtcEngineKit
    }
    
    @objc func rtcAudioFileInfo(_ notification: Notification) {
        guard let object = notification.object as? [String: Any],
              let info = object["info"] as? AgoraRtcAudioFileInfo else {
            return
        }
        
        log(content: #function,
            extra: "filePath: \(info.filePath), durationMs: \(info.durationMs)",
            type: .info)
        
        effectMixer?.setEffectDurationUpdate(info.filePath,
                                             duration: Int(info.durationMs))
    }
    
    @objc func rtcAudioEffectFinish(_ notification: Notification) {
        guard let object = notification.object as? [String: Any],
              let soundId = object["soundId"] as? Int else {
            return
        }
        
        log(content: #function,
            extra: "soundId: \(soundId)",
            type: .info)
        
        effectMixer?.setEffectFinished(soundId)
    }
    
    @objc func rtcAudioEffectStateChanged(_ notification: Notification) {
        guard let object = notification.object as? [String: Any],
              let soundId = object["soundId"] as? Int,
              let state = object["state"] as? Int else {
            return
        }
        
        log(content: #function,
            extra: "soundId: \(soundId), state: \(state)",
            type: .info)
        
        effectMixer?.setEffectSoundId(soundId,
                                      stateChanged: state)
    }
    
    func log(content: String,
             extra: String? = nil,
             type: FcrBoardLogType,
             fromClass: AnyClass? = nil,
             funcName: String = #function,
             line: Int = #line) {
        var classType: AnyClass
        
        if let `fromClass` = fromClass {
            classType = fromClass
        } else {
            classType = self.classForCoder
        }
        
        logTube?.onBoardLog(content: content,
                            extra: extra,
                            type: type,
                            fromClass: classType,
                            funcName: funcName,
                            line: line)
    }
}

extension FcrBoardListener: WhiteCommonCallbackDelegate {
    func throwError(_ error: Error) {
        roomNeedObserve?.onThrowError(error)
    }
    
    func logger(_ dict: [AnyHashable : Any]) {
        roomNeedObserve?.onLogger(dict)
    }
}

extension FcrBoardListener: WhiteRoomCallbackDelegate {
    func firePhaseChanged(_ phase: WhiteRoomPhase) {
        roomNeedObserve?.onPhaseChanged(phase)
    }
    
    func fireRoomStateChanged(_ modifyState: WhiteRoomState!) {
        guard let state = modifyState else {
            return
        }
        
        mainWindowNeedObserve?.onRoomStateChanged(state)
    }
    
    func fireCanUndoStepsUpdate(_ canUndoSteps: Int) {
        mainWindowNeedObserve?.onCanUndoStepsUpdate(canUndoSteps)
    }
    
    func fireCanRedoStepsUpdate(_ canRedoSteps: Int) {
        mainWindowNeedObserve?.onCanRedoStepsUpdate(canRedoSteps)
    }
}

extension FcrBoardListener: WhiteAudioMixerBridgeDelegate {
    func startAudioMixing(_ filePath: String,
                          loopback: Bool,
                          replace: Bool,
                          cycle: Int) {
        mainWindowNeedObserve?.onStartAudioMixing(filePath: filePath,
                                                  loopback: loopback,
                                                  replace: replace,
                                                  cycle: cycle)
    }
    
    func stopAudioMixing() {
        mainWindowNeedObserve?.onStopAudioMixing()
    }
    
    func pauseAudioMixing() {
        mainWindowNeedObserve?.onPauseAudioMixing()
    }
    
    func resumeAudioMixing() {
        mainWindowNeedObserve?.onResumeAudioMixing()
    }
    
    func setAudioMixingPosition(_ position: Int) {
        mainWindowNeedObserve?.onAudioMixingPositionUpdated(position: position)
    }
}

extension FcrBoardListener: WhiteAudioEffectMixerBridgeDelegate {
    func getEffectsVolume() -> Double {
        let result = rtc.getEffectsVolume()
        
        log(content: #function,
            extra: "result: \(result)",
            type: .info,
            fromClass: FcrBoardListener.self)
        
        return result
    }
    
    func setEffectsVolume(_ volume: Double) -> Int32 {
        let result = rtc.setEffectsVolume(volume)
        
        log(content: #function,
            extra: "volume: \(volume), result: \(result)",
            type: .info,
            fromClass: FcrBoardListener.self)
        
        return result
    }
    
    func setVolumeOfEffect(_ soundId: Int32,
                           withVolume volume: Double) -> Int32 {
        let result = rtc.setVolumeOfEffect(soundId,
                                           withVolume: volume)
        
        log(content: #function,
            extra: "soundId: \(soundId), volume: \(volume), result: \(result)",
            type: .info,
            fromClass: WhiteSDK.self)
        
        return result
    }
    
    func playEffect(_ soundId: Int32,
                    filePath: String?,
                    loopCount: Int32,
                    pitch: Double,
                    pan: Double,
                    gain: Double,
                    publish: Bool,
                    startPos: Int32,
                    identifier: String) -> Int32 {
        var extra = "soundId: \(soundId), filePath: \(filePath ?? "nil"), loopCount: \(loopCount), pitch: \(pitch), pan: \(pan), gain: \(gain) publish: \(publish), startPos: \(startPos), identifier: \(identifier)"
        
        if identifier == "mediaPlayer" {
            let tGain: Double = 300
            
            extra += ", mediaPlayer final gain: \(tGain)"
            
            let result = rtc.playEffect(soundId,
                                        filePath: filePath,
                                        loopCount: loopCount,
                                        pitch: pitch,
                                        pan: pan,
                                        gain: tGain,
                                        publish: publish)
            
            extra += ", result: \(result)"
            
            log(content: #function,
                extra: extra,
                type: .info,
                fromClass: FcrBoardListener.self)
            
            return result
        } else {
            let tGain: Double = 300
            
            extra += ", ppt final gain: \(tGain)"
            
            let result = rtc.playEffect(soundId,
                                        filePath: filePath,
                                        loopCount: loopCount,
                                        pitch: pitch,
                                        pan: pan,
                                        gain: tGain,
                                        publish: publish,
                                        startPos: startPos)
            
            extra += ", result: \(result)"
            
            log(content: #function,
                extra: extra,
                type: .info,
                fromClass: FcrBoardListener.self)
            
            return result
        }
    }
    
    func stopEffect(_ soundId: Int32) -> Int32 {
        let result = rtc.stopEffect(soundId)
        
        log(content: #function,
            extra: "soundId: \(soundId), result: \(result)",
            type: .info,
            fromClass: FcrBoardListener.self)
        
        return result
    }
    
    func stopAllEffects() -> Int32 {
        let result = rtc.stopAllEffects()
        
        log(content: #function,
            extra: "result: \(result)",
            type: .info,
            fromClass: WhiteSDK.self)
        
        return result
    }
    
    func preloadEffect(_ soundId: Int32,
                       filePath: String?) -> Int32 {
        let result = rtc.preloadEffect(soundId,
                                       filePath: filePath)
        
        log(content: #function,
            extra: "soundId: \(soundId), filePath: \(filePath ?? ""), result: \(result)",
            type: .info,
            fromClass: FcrBoardListener.self)
        
        return result
    }
    
    func unloadEffect(_ soundId: Int32) -> Int32 {
        let result = rtc.unloadEffect(soundId)
        
        log(content: #function,
            extra: "soundId: \(soundId), result: \(result)",
            type: .info,
            fromClass: FcrBoardListener.self)
        
        return result
    }
    
    func pauseEffect(_ soundId: Int32) -> Int32 {
        let result = rtc.pauseEffect(soundId)
        
        log(content: #function,
            extra: "soundId: \(soundId), result: \(result)",
            type: .info,
            fromClass: FcrBoardListener.self)
        
        return result
    }
    
    func pauseAllEffects() -> Int32 {
        let result = rtc.pauseAllEffects()
        
        log(content: #function,
            extra: "result: \(result)",
            type: .info,
            fromClass: FcrBoardListener.self)
        
        return result
    }
    
    func resumeEffect(_ soundId: Int32) -> Int32 {
        let result = rtc.resumeEffect(soundId)
        
        log(content: #function,
            extra: "result: \(result)",
            type: .info,
            fromClass: FcrBoardListener.self)
        
        return result
    }
    
    func resumeAllEffects() -> Int32 {
        let result = rtc.resumeAllEffects()
        
        log(content: #function,
            extra: "result: \(result)",
            type: .info,
            fromClass: FcrBoardListener.self)
        
        return result
    }
    
    func setEffectPosition(_ soundId: Int32,
                           pos: Int) -> Int32 {
        let result = rtc.setEffectPosition(soundId,
                                           pos: pos)
        
        log(content: #function,
            extra: "soundId: \(soundId), pos: \(pos), result: \(result)",
            type: .info,
            fromClass: FcrBoardListener.self)
        
        return result
    }
    
    func getEffectCurrentPosition(_ soundId: Int32) -> Int32 {
        //        log(content: #function,
        //            extra: "soundId: \(soundId)",
        //            type: .info,
        //            fromClass: WhiteSDK.self)
        
        return rtc.getEffectCurrentPosition(soundId)
    }
    
    func getEffectDuration(_ filePath: String) -> Int32 {
        let result = rtc.getEffectDuration(filePath)
        
        log(content: #function,
            extra: "filePath: \(filePath), result: \(result)",
            type: .info,
            fromClass: FcrBoardListener.self)
        
        return result
    }
}
