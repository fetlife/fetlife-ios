//
//  UIColor.swift
//  FetLife
//
//  Created by Jose Cortinas on 2/4/16.
//  Copyright © 2016 BitLove Inc. All rights reserved.
//

import UIKit

extension UIColor {
    public class func brownishGreyColor() -> UIColor {
        return UIColor(red:0.400,  green:0.400,  blue:0.400, alpha:1)
    }
    
    public class func brickColor() -> UIColor {
        return UIColor(red:0.710,  green:0.114,  blue:0.114, alpha:1)
    }
    
    public class func backgroundColor() -> UIColor {
        return UIColor(red:0.102,  green:0.102,  blue:0.102, alpha:1)
    }
    
    public class func unreadMarkerColor() -> UIColor {
        return UIColor(red:0.467,  green:0,  blue:0, alpha:1)
    }

    public class func borderColor() -> UIColor {
        return UIColor(red:0.075,  green:0.075,  blue:0.075, alpha:1)
    }
    
    public class func incomingMessageBGColor() -> UIColor {
        return UIColor(red:0.200,  green:0.200,  blue:0.200, alpha:1)
    }
    
    public class func outgoingMessageBGColor() -> UIColor {
        return UIColor.black
    }
    
    public class func messageTextColor() -> UIColor {
        return UIColor(red:0.600, green:0.600, blue:0.600, alpha:1)
    }
    
    public class func supporterIconTintColor() -> UIColor {
        return UIColor.darkGray
    }
}
