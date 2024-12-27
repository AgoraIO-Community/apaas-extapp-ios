//
//  AgoraPollServerAPI.swift
//  AgoraWidgets
//
//  Created by LYY on 2022/3/5.
//


import AgoraFoundation

class AgoraPollServerAPI: AgoraWidgetServerAPI {
    func submit(pollId: String,
                selectList: [Int],
                success: SuccessCompletion? = nil,
                failure: FailureCompletion? = nil) {
        let path = "/edu/apps/\(appId)/v2/rooms/\(roomId)/widgets/polls/\(pollId)/users/\(userId)"
        let urlString = host + path
        
        let parameters: [String: Any] = ["selectIndex": selectList]
       
        
        request(event: "widget-poll-submit",
                url: urlString,
                method: .post,
                parameters: parameters) { _ in
            success?()
        } failure: { error in
            failure?(error)
        }
    }
    
    func start() {
        
    }
    
    func stop() {
        
    }
}
