//
//  AgoraPopupQuizServerAPI.swift
//  AgoraWidgets
//
//  Created by Cavan on 2022/3/7.
//

import Foundation
import AgoraFoundation

class AgoraPopupQuizServerAPI: AgoraWidgetServerAPI {
    func submitAnswer(_ answerList: [String],
                      selectorId: String,
                      success: SuccessCompletion? = nil,
                      failure: FailureCompletion? = nil) {
//        let event = ArRequestEvent(name: "pop-up-quiz-submit")
        let url = host + "/edu/apps/\(appId)/v2/rooms/\(roomId)/widgets/popupQuizs/\(selectorId)/users/\(userId)"
        let parameters = ["selectedItems": answerList]
        
        request(event: "pop-up-quiz-submit",
                url: url,
                method: .put,
                parameters: parameters) { _ in
            success?()
        } failure: { (error) in
            failure?(error)
        }
    }
}
