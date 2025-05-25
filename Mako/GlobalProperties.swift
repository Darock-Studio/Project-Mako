//
//  GlobalProperties.swift
//  Mako
//
//  Created by Mark Chan on 2025/5/5.
//

import UIKit
import Alamofire
import Foundation

#if canImport(WatchKit)
import WatchKit
#endif

// !!!: It's STRONGLY NOT RECOMMENDED to use this API endpoint
// !!!: in your OWN project. It's UNSTABLE.
var apiBaseURL = "http://mako.darock.top"

var globalRequestHeaders: HTTPHeaders {
    [
        "Cookie": UserDefaults.standard.string(forKey: "AccountCookie") ?? ""
    ]
}

var screenBounds: CGRect {
    #if os(iOS)
    UIApplication.shared.windows.filter { $0.isKeyWindow }.first!.frame
    #else
    WKInterfaceDevice.current().screenBounds
    #endif
}
