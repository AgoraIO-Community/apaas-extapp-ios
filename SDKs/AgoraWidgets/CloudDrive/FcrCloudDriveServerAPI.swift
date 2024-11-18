//
//  FcrCloudDriveServerAPI.swift
//  AgoraWidgets
//
//  Created by ZYP on 2021/10/21.
//

import Armin

class FcrCloudDriveServerAPI: AgoraWidgetServerAPI {
    typealias SuccessBlock<FcrCloudDriveFileListServerObject> = (FcrCloudDriveFileListServerObject) -> ()
    
    func requestResourceInUser(pageNo: Int,
                               pageSize: Int,
                               resourceName: String? = nil,
                               success: @escaping SuccessBlock<FcrCloudDriveFileListServerObject>,
                               failure: @escaping FailureCompletion) {
        let path = "/edu/apps/\(appId)/v3/users/\(userId)/resources/page"
        let urlString = host + path
        
        var parameters: [String : Any] = ["pageNo" : pageNo,
                                          "pageSize" : pageSize]
        
        if let `resourceName` = resourceName {
            parameters["resourceName"] = resourceName
        }
        
        request(event: "cloud-drive-file-list",
                url: urlString,
                method: .get,
                parameters: parameters) { json in
            if let dataDic = json["data"] as? [String: Any],
               let source = dataDic.toObject(FcrCloudDriveFileListServerObject.self) {
                success(source)
            } else {
                failure(NSError(domain: "decode",
                                code: -1))
            }
        } failure: { error in
            failure(error)
        }
    }
    
    func deleteResourceInUser(resourceUuid: String,
                              success: @escaping StringCompletion,
                              failure: @escaping FailureCompletion) {
        let path = "/edu/apps/\(appId)/v3/users/\(userId)/resources"
        let urlString = host + path
        
        let parameters: [String : Any] = ["resourceUuid" : resourceUuid]
        
        let list = [parameters]
        
        request(event: "cloud-drive-delete-file",
                url: urlString,
                method: .delete,
                anyParameters: list) { json in
            success(resourceUuid)
        } failure: { error in
            failure(error)
        }
    }
    
    func uploadResourceInUser(fileURL: URL,
                              success: @escaping SuccessCompletion,
                              failure: @escaping FailureCompletion) {
        guard let fileSize = getFileSize(at: fileURL) else {
            return
        }
        
        let fileURLString = fileURL.absoluteString
        
        guard let name = fileURLString.split(separator: "/").last?.removingPercentEncoding?.lowercased() else {
            return
        }
        
        guard let ext = name.split(separator: ".").last else {
            return
        }
        
        getSignedFileURL(ext: String(ext), success: { [weak self] json in
            if let preSignedUrl = json["preSignedUrl"] as? String,
               let resourceUuid = json["resourceUuid"] as? String,
                let url = json["url"] as? String {
                self?.uploadFileStream(to: preSignedUrl,
                                       fileUrl: fileURL,
                                       event: "cloud-drive-upload-file",
                                       success: { [weak self] in
                    self?.addResourceToUser(resourceUuid: resourceUuid,
                                            resourceName: String(name),
                                            size: fileSize,
                                            ext: String(ext),
                                            url: url,
                                            success: success,
                                            failure: failure)
                }, failure: failure)
            } else {
                let error = NSError(domain: "http request",
                                    code: -1,
                                    userInfo: ["message": "invalid json"])
                failure(error)
            }
        }, failure: failure)
    }
    
    private func getSignedFileURL(ext: String,
                                  success: @escaping JsonCompletion,
                                  failure: @escaping FailureCompletion) {
        let path = "/edu/apps/\(appId)/v3/users/\(userId)/presignedUrls"
        let urlString = host + path
        
        let object = ["contentType": "application/octet-stream",
                      "ext": ext]
        
        let parameters = [object]
        
        request(event: "cloud-drive",
                url: urlString,
                method: .post,
                anyParameters: parameters) { json in
            if let data = (json["data"] as? [[String: Any]])?.first {
                success(data)
            } else {
                let error = NSError(domain: "http request",
                                    code: -1,
                                    userInfo: ["message": "invalid data"])
                failure(error)
            }
        } failure: { error in
            failure(error)
        }
    }
    
    private func addResourceToUser(resourceUuid: String,
                                   resourceName: String,
                                   size: Int64,
                                   ext: String,
                                   url: String,
                                   success: @escaping SuccessCompletion,
                                   failure: @escaping FailureCompletion) {
        let path = "/edu/apps/\(appId)/v4/users/\(userId)/resources/\(resourceUuid)"
        let urlString = host + path
        
        let fileType = 1
        
        var parameters: [String: Any] = ["resourceName": resourceName,
                                         "size": size,
                                         "url": url,
                                         "ext": ext,
                                         "parentResourceUuid": "root",
                                         "type": "\(fileType)"]
        
        if ifNeedConverting(ext: ext) {
            let type = (ifSupportDynamicConverting(ext: ext) ? "dynamic" : "static")
            
            let conversion: [String: Any] = ["type": type,
                                             "preview": true,
                                             "scale": 1.2,
                                             "outputFormat": "png"]
            
            parameters["conversion"] = conversion
        }
        
        request(event: "cloud-drive-add-resource",
                url: urlString,
                method: .post,
                parameters: parameters,
                isRetry: false,
                success: { json in
            success()
        }, failure: failure)
    }
    
    private func ifNeedConverting(ext: String) -> Bool {
        switch ext {
        case "ppt", "pptx", "doc", "docx", "pdf":
            return true
        default:
            return false
        }
    }
    
    private func ifSupportDynamicConverting(ext: String) -> Bool {
        switch ext {
        case "pptx":
            return true
        default:
            return false
        }
    }
    
    func getFileSize(at url: URL) -> Int64? {
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let fileSize = attributes[FileAttributeKey.size] as? Int64 {
                return fileSize
            }
        } catch {
            print("Error: \(error)")
        }
        
        return nil
    }
}
