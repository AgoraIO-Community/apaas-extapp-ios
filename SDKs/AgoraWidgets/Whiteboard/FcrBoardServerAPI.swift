//
//  FcrWhiteBoardServerAPI.swift
//  AgoraWidgets
//
//  Created by Cavan on 2022/5/6.
//

import Foundation
import AgoraFoundation

class FcrBoardServerAPI: AgoraWidgetServerAPI {
    func getWindowAttributes(success: JsonCompletion? = nil,
                             failure: FailureCompletion? = nil) {
        guard let roomId = roomId.split(separator: "-").first else {
            failure?(NSError(domain: "roomId error: \(roomId)",
                             code: -1))
            return
        }
        
        let url = host + "/edu/apps/\(appId)/v2/rooms/\(roomId)/widgets/netlessBoard/windowManager"
        
        request(event: "get-window-attributes",
                url: url,
                method: .get,
                isRetry: true) { (json) in
            guard let data = json["data"] as? [String: Any] else {
                failure?(NSError(domain: "data nil",
                                 code: -1,
                                 userInfo: nil))
                return
            }
            
            success?(data)
        } failure: { (error) in
            failure?(error)
        }
    }
}
