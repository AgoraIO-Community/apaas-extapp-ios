//
//  AgoraWidgetsUIUtils.swift
//  AgoraWidgets
//
//  Created by DoubleCircle on 2022/1/14.
//

import AgoraUIBaseViews
import UIKit

fileprivate let kPad = UIDevice.current.userInterfaceIdiom == .pad

fileprivate var kScale: CGFloat = {
    let width = max(UIScreen.main.bounds.width,
                    UIScreen.main.bounds.height)
    
    let height = min(UIScreen.main.bounds.width,
                     UIScreen.main.bounds.height)
    
    if width / height > 667.0 / 375.0 {
        return height / 375.0
    } else {
        return width / 667.0
    }
}()

struct AgoraWidgetsFit {
    static func scale(_ value: CGFloat) -> CGFloat {
        return value * kScale
    }
    
    static func os(phone: CGFloat,
                   pad: CGFloat) -> CGFloat {
        return kPad ? pad : phone
    }
}

public extension UIImage {
    @objc static func ag_image(_ name: String) -> UIImage? {
        return UIImage.agora_image(name,
                                     in: "AgoraWidgets")
    }
}
