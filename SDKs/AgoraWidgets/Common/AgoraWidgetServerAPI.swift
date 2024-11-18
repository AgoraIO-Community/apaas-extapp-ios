//
//  AgoraWidgetServerAPI.swift
//  AgoraWidgets
//
//  Created by Cavan on 2022/5/6.
//

import Foundation
import Armin

public typealias SuccessCompletion = () -> ()
public typealias StringCompletion = (String) -> ()
public typealias JsonCompletion = ([String: Any]) -> ()
public typealias JsonListCompletion = ([Dictionary<String, Any>]) -> ()
public typealias FailureCompletion = (Error) -> ()

public class AgoraWidgetServerAPI: NSObject {
    private(set) var host: String
    private(set) var appId: String
    private(set) var token: String
    private(set) var roomId: String
    private(set) var userId: String
    private(set) var armin: Armin
    
    init(host: String,
         appId: String,
         token: String,
         roomId: String,
         userId: String,
         logTube: ArLogTube) {
        self.host = host
        self.appId = appId
        self.token = token
        self.roomId = roomId
        self.userId = userId
        self.armin = Armin(delegate: nil,
                           logTube: logTube)
    }
        
    func request(event: String,
                 url: String,
                 method: ArHttpMethod,
                 header: [String: String]? = nil,
                 parameters: [String: Any]? = nil,
                 isRetry: Bool = false,
                 success: JsonCompletion? = nil,
                 failure: FailureCompletion? = nil) {
        var tHeader = ["x-agora-token": token,
                       "x-agora-uid": userId,
                       "Authorization": "agora token=\"\(token)\""]
        
        if let `header` = header {
            tHeader.merge(header) { _, new in
                new
            }
        }
        
        let event = ArRequestEvent(name: event)
        
        let requestType: ArRequestType = .http(method,
                                               url: url)
        
        let task = ArRequestTask(event: event,
                                 type: requestType,
                                 timeout: .medium,
                                 header: tHeader,
                                 parameters: parameters)
        
        let response = ArResponse.json { [weak self] (json) in
            success?(json)
        }
        
        let failureRetry: ArErrorRetryCompletion = { [weak self] (error) -> ArRetryOptions in
            failure?(error)
            return (isRetry ? .retry(after: 1) : .resign)
        }
        
        armin.request(task: task,
                      responseOnMainQueue: true,
                      success: response,
                      failRetry: failureRetry)
    }
    
    func request(event: String,
                 url: String,
                 method: ArHttpMethod,
                 header: [String: String]? = nil,
                 anyParameters: Any,
                 success: JsonCompletion? = nil,
                 failure: FailureCompletion? = nil) {
        var extra: [String: Any] = ["event": event]
        
        if let `header` = header {
            extra["header"] = header.description
        }
        
        extra["parameters"] = anyParameters
        
        self.armin.logTube?.log(info: "http request",
                                extra: extra.description)
        
        // 创建一个 URL 对象
        let urlObj = URL(string: url)!

        // 创建一个 URLRequest 对象
        var request = URLRequest(url: urlObj)
        
        switch method {
        case .post:   request.httpMethod = "POST"
        case .delete: request.httpMethod = "DELETE"
        default:      fatalError()
        }
        
        // Parameters
        let jsonData = try? JSONSerialization.data(withJSONObject: anyParameters)
        request.httpBody = jsonData
        
        request.allHTTPHeaderFields = ["x-agora-token": token,
                                       "x-agora-uid": userId,
                                       "Authorization": "agora token=\"\(token)\"",
                                       "Content-Type": "application/json"]
        
        // 创建一个 URLsession 对象
        let session = URLSession.shared

        // 发送请求（异步）
        let task = session.dataTask(with: request) { [weak self] (data, response, error) in
            if let error = error {
                let nsError = error as NSError
                let arError = ArError.fail("response code error",
                                           code: nsError.code)
                
                self?.armin.logTube?.log(error: arError,
                                         extra: "event: \(event), message: \(error.localizedDescription)")
                
                
                DispatchQueue.main.async {
                    failure?(error)
                }
                
                return
            }
            
            guard let data = data else {
                let error = NSError(domain: "http request",
                                    code: -1,
                                    userInfo: ["message": "http data is nil"])
                
                let arError = ArError.fail("http request error",
                                           code: error.code)
                
                self?.armin.logTube?.log(error: arError,
                                         extra: "event: \(event), message: \(error.localizedDescription)")
                
                DispatchQueue.main.async {
                    failure?(error)
                }
                
                return
            }
            
            do {
                let responseData = try JSONSerialization.jsonObject(with: data,
                                                                    options: [])
                
                let json = responseData as! [String: Any]
                
                self?.armin.logTube?.log(info: "request success",
                                         extra: "event: \(event), message: \(json)")
                
                DispatchQueue.main.async {
                    success?(json)
                }
            } catch let error {
                let error = NSError(domain: "http request",
                                    code: -1,
                                    userInfo: ["message": "invalid json"])
                
                let arError = ArError.fail("http request error",
                                           code: error.code)
                
                self?.armin.logTube?.log(error: arError,
                                         extra: "event: \(event), message: \(error.localizedDescription)")
                
                DispatchQueue.main.async {
                    failure?(error)
                }
            }
        }

        // 启动任务
        task.resume()
    }
    
    func uploadFileStream(to url: String,
                          fileUrl: URL,
                          event: String,
                          success: SuccessCompletion? = nil,
                          failure: FailureCompletion? = nil) {
        let urlObj = URL(string: url)!
        
        var request = URLRequest(url: urlObj)
        request.httpMethod = "PUT"
//        request.value(forHTTPHeaderField: "Content-Type") = "application/octet-stream"
        
        let session = URLSession.shared
        
        let task = session.uploadTask(with: request,
                                      fromFile: fileUrl) { [weak self] (data, response, error) in
            if let error = error {
                let nsError = error as NSError
                let arError = ArError.fail("response code error",
                                           code: nsError.code)
                
                self?.armin.logTube?.log(error: arError,
                                         extra: "event: \(event), message: \(error.localizedDescription)")
                
                DispatchQueue.main.async {
                    failure?(error)
                }
                
                return
            }
            
            guard let response = response as? HTTPURLResponse else {
                let error = NSError(domain: "Invalid response",
                                    code: -1)
                
                let arError = ArError.fail("Invalid response",
                                           code: -1)
                
                self?.armin.logTube?.log(error: arError,
                                         extra: "event: \(event)")
                
                DispatchQueue.main.async {
                    failure?(error)
                }
                
                return
            }
            
            if response.statusCode == 200 {
                self?.armin.logTube?.log(info: "request success",
                                         extra: "event: \(event)")
                
                DispatchQueue.main.async {
                    success?()
                }
            } else {
                let error = NSError(domain: "http request",
                                    code: -1,
                                    userInfo: ["message": "upload stream file failled with code: \(response.statusCode)"])
                
                let arError = ArError.fail("http request",
                                           code: -1)
                
                self?.armin.logTube?.log(error: arError,
                                         extra: "event: \(event), message: upload stream file failled with code: \(response.statusCode)")
                
                DispatchQueue.main.async {
                    failure?(error)
                }
            }
        }

        task.resume()
    }
}
