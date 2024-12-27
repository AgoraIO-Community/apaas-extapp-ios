//
//  AgoraWidgetLog.swift
//  AgoraWidgets
//
//  Created by Cavan on 2022/3/9.
//

import Foundation
import AgoraFoundation

protocol AgoraWidgetLogTube where Self: NSObject {
    var logger: AgoraWidgetLogger {set get}
    
    func log(content: String,
             extra: String?,
             type: AgoraLogInnerType,
             fromClass: AnyClass?,
             funcName: String,
             line: Int)
}
 
extension AgoraWidgetLogTube {
    func log(content: String,
             extra: String? = nil,
             type: AgoraLogInnerType,
             fromClass: AnyClass? = nil,
             funcName: String = #function,
             line: Int = #line) {
        var fClass: AnyClass
        
        if let from = fromClass {
            fClass = from
        } else {
            fClass = self.classForCoder
        }
        
        logger.log(content: content,
                   extra: extra,
                   type: type,
                   from: fClass,
                   funcName: funcName,
                   line: line)
    }
}

class AgoraWidgetLogger: NSObject {
    private let logger: AgoraLogger
    private let queue = DispatchQueue(label: "io.agora.widgets.log.thread")
    private var traceId: String
    private let widgetId: String
    var isPrintOnConsole: Bool = false
    
    init(widgetId: String,
         logId: String) {
        let cachesFolder = NSSearchPathForDirectoriesInDomains(.cachesDirectory,
                                                               .userDomainMask,
                                                               true)[0]
        let folder = cachesFolder.appending("/AgoraLog")
        let manager = FileManager.default

        if !manager.fileExists(atPath: folder,
                               isDirectory: nil) {
            try? manager.createDirectory(atPath: folder,
                                         withIntermediateDirectories: true,
                                         attributes: nil)
        }
        
        let folderPath = folder
        
        logger = AgoraLogger(folderPath: folderPath,
                             filePrefix: widgetId,
                             maximumNumberOfFiles: 3)
        logger.setPrintOnConsoleType(.none)
        
        let timeStamp = "\(Date().timeIntervalSince1970.intValue)"
        
        traceId = "\(timeStamp)\(logId)".agora_md5()
        
        self.widgetId = widgetId
    }
    
    fileprivate func log(content: String,
                         extra: String?,
                         type: AgoraLogInnerType,
                         from: AnyClass,
                         funcName: String = #function,
                         line: Int = #line) {
        queue.async { [weak self] in
            guard let `self` = self else {
                
                return
            }
            
            let classText = NSStringFromClass(from)
            
            var fileLog = "\(classText) \(line) : \(funcName) \(content)"
            
            if let `extra` = extra {
                fileLog.append(" \(extra)")
            }
            
            self.logger.log(fileLog,
                            type: type)
            
            guard self.isPrintOnConsole else {
                return
            }
            
            DispatchQueue.main.async {
                let separator = "~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~"
                let timeRange: [Date.Range] = [.hour,
                                               .minute,
                                               .milliSecond]
                let currentDate = Date.currentDateString(with: timeRange,
                                                         separator: ":")
                
                var consoleArray = [separator,
                                    "[\(self.widgetId) Widget]",
                                    "TIME: \(currentDate)",
                                    "CLASS: \(classText)",
                                    "\(type.stringValue): \(content)",
                                    separator]
                
                if let ex = extra {
                    let index = consoleArray.count - 1
                    consoleArray.insert("EXTRA: \(ex)",
                                        at: index)
                }
                
                let consoleLog = consoleArray.joined(separator: "\n")
                
                print(consoleLog.utf8)
            }
        }
    }
}

extension AgoraWidgetLogger: ArLogTube {
    func onLog(info: String,
               extra: [String : Any]?) {
        log(content: info,
            extra: extra?.agora_json_string(),
            type: .info,
            from: AgoraWidgetServerAPI.self)
    }
    
    func onLog(warning: String, 
               extra: [String : Any]?) {
        log(content: warning,
            extra: extra?.agora_json_string(),
            type: .warning,
            from: AgoraWidgetServerAPI.self)
    }
    
    func onLog(error: Error, 
               extra: [String : Any]?) {
        log(content: error.localizedDescription,
            extra: extra?.agora_json_string(),
            type: .error,
            from: AgoraWidgetServerAPI.self)
    }
}

extension Date {
    static func currentDateString(with range: [Date.Range],
                                  separator: String? = nil) -> String {
        let array = range.map { (item) -> String in
            return item.rawValue
        }
        
        let formatter = DateFormatter()
        
        if let sep = separator {
            formatter.dateFormat = array.joined(separator: sep)
        } else {
            formatter.dateFormat = array.joined(separator: "")
        }
        
        return formatter.string(from: Date())
    }
}

extension AgoraLogInnerType {
    var stringValue: String {
        switch self {
        case .debug:   return "DEBUG"
        case .warning: return "WARNING"
        case .info:    return "INFO"
        case .error:   return "ERROR"
        default:       return "INFO"
        }
    }
}
