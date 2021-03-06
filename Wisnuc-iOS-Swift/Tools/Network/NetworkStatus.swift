//
//  NetworkStatus.swift
//  Wisnuc-iOS-Swift
//
//  Created by wisnuc-imac on 2018/4/12.
//  Copyright © 2018年 wisnuc-imac. All rights reserved.
//

import UIKit
import RealReachability

enum WSNetworkStatus:Int{
    case Disconnected = 0
    case WIFI
    case ViaWWAN
    case Unknow
}

enum NetworkServiceState:Int {
    case normal = 0
    case local
}

class NetworkStatus: NSObject {
    typealias NetworkHandler = (_ status: WSNetworkStatus) -> Void
    var networkStatus:WSNetworkStatus?
    
    class func getNetworkStatus(_ closure: @escaping NetworkHandler){
        RealReachability.sharedInstance().reachability { (status) in
            switch status {
            case .RealStatusNotReachable:
                closure(WSNetworkStatus.Disconnected)
            case .RealStatusViaWiFi:
                closure(WSNetworkStatus.WIFI)
            case .RealStatusViaWWAN:
                closure(WSNetworkStatus.ViaWWAN)
            case .RealStatusUnknown:
                closure(WSNetworkStatus.Unknow)
            }
        }
    }
}
