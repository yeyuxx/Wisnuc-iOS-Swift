//
//  BasicDefine.swift
//  FruitMix-Swift
//
//  Created by wisnuc-imac on 2018/3/16.
//  Copyright © 2018年 wisnuc-imac. All rights reserved.
//

import Foundation
import UIKit

public let __kWidth = UIScreen.main.bounds.size.width
public let __kHeight = UIScreen.main.bounds.size.height

public let kFirstLaunchKey =  "kFirstLaunchKey"
public let kappVersionKey =  "kappVersionKey"

public let KWxAppID = "wx99b54eb728323fe8"

public func LocalizedString(forKey key:String) -> String {
  return Bundle.main.localizedString(forKey: key, value:"", table: nil)
}


