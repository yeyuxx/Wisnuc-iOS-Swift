//
//  ActivityIndicator.swift
//  Wisnuc-iOS-Swift
//
//  Created by wisnuc-imac on 2018/4/13.
//  Copyright © 2018年 wisnuc-imac. All rights reserved.
//

import UIKit
import MaterialComponents.MDCActivityIndicator
//import SDWebImage
class ActivityIndicator: NSObject{
    
    static let shareSingleOneActivityIndicator = MDCActivityIndicator(frame: CGRect.zero)
    static var window = UIWindow.init(frame: CGRect(x: 0, y: MDCAppNavigationBarHeight, width: __kWidth, height: __kHeight - MDCAppNavigationBarHeight))
    
    
    struct MDCPalette {
        static let blue: UIColor = UIColor(red: 0.129, green: 0.588, blue: 0.953, alpha: 1.0)
        static let red: UIColor = UIColor(red: 0.957, green: 0.263, blue: 0.212, alpha: 1.0)
        static let green: UIColor = UIColor(red: 0.298, green: 0.686, blue: 0.314, alpha: 1.0)
        static let yellow: UIColor = UIColor(red: 1.0, green: 0.922, blue: 0.231, alpha: 1.0)
    }
    
    
    class func startActivityIndicatorAnimation(){
        DispatchQueue.main.async {
            if shareSingleOneActivityIndicator.isAnimating{
                stopActivityIndicatorAnimation()
            }
            let width: CGFloat = __kWidth / 2
            let height: CGFloat = __kHeight / 2
        
            //Initialize single color progress indicator
            let frame: CGRect = CGRect(x: width - 48/2, y: height, width: 48, height: 48)
            shareSingleOneActivityIndicator.frame = frame
            // Pass colors you want to indicator to cycle through
            shareSingleOneActivityIndicator.cycleColors = [MDCPalette.blue, MDCPalette.red, MDCPalette.green, MDCPalette.yellow]
            shareSingleOneActivityIndicator.radius = 18.0
            shareSingleOneActivityIndicator.strokeWidth = 3.0
            shareSingleOneActivityIndicator.indicatorMode = .indeterminate
            shareSingleOneActivityIndicator.sizeToFit()
            shareSingleOneActivityIndicator.startAnimating()
            let window = UIApplication.shared.keyWindow
            window?.windowLevel = UIWindowLevelNormal
//            UIViewController.currentViewController().view.isUserInteractionEnabled = false
            window?.addSubview(shareSingleOneActivityIndicator)
            window?.bringSubview(toFront: shareSingleOneActivityIndicator)
            window?.isUserInteractionEnabled = false
        }
    }
    
    class func startActivityIndicatorAnimation(in view:UIView){
         mainThreadSafe {
            if shareSingleOneActivityIndicator.isAnimating{
                stopActivityIndicatorAnimation()
            }
            let width: CGFloat = view.width / 2
            let height: CGFloat = view.height / 2
            let frame: CGRect = CGRect(x: 0, y: 0, width: 48, height: 48)
            shareSingleOneActivityIndicator.frame = frame
            shareSingleOneActivityIndicator.center = CGPoint(x: width, y: height)
            shareSingleOneActivityIndicator.cycleColors = [MDCPalette.blue, MDCPalette.red, MDCPalette.green, MDCPalette.yellow]
            shareSingleOneActivityIndicator.radius = 18.0
            shareSingleOneActivityIndicator.strokeWidth = 3.0
//            shareSingleOneActivityIndicator.delegate = self.init()
            shareSingleOneActivityIndicator.indicatorMode = .indeterminate
            shareSingleOneActivityIndicator.sizeToFit()
            shareSingleOneActivityIndicator.startAnimating()
            view.addSubview(shareSingleOneActivityIndicator)
            view.isUserInteractionEnabled = false
            view.bringSubview(toFront: shareSingleOneActivityIndicator)
        }
    }
    
    class func stopActivity(in view:UIView){
        mainThreadSafe {
            shareSingleOneActivityIndicator.stopAnimating()
            shareSingleOneActivityIndicator.removeFromSuperview()
            view.isUserInteractionEnabled  = true
        }
    }
    
    class func stopActivityIndicatorAnimation(){
        mainThreadSafe {
        shareSingleOneActivityIndicator.stopAnimating()
        shareSingleOneActivityIndicator.removeFromSuperview()
        let window = UIApplication.shared.keyWindow
        window?.isUserInteractionEnabled  = true
        }
    }
    
    class func isAnimating() -> Bool{
        return shareSingleOneActivityIndicator.isAnimating
    }
}

 // MARK: - MDCActivityIndicatorDelegate
extension ActivityIndicator : MDCActivityIndicatorDelegate {
    func activityIndicatorAnimationDidFinish(_ activityIndicator: MDCActivityIndicator) {
        
    }
    
    
    func activityIndicatorModeTransitionDidFinish(_ activityIndicator: MDCActivityIndicator) {
        
    }
}
