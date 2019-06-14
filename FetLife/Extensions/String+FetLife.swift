//
//  String+FetLife.swift
//  FetLife
//
//  Created by Matt Conz on 8/23/18.
//  Copyright © 2018 BitLove Inc. All rights reserved.
//

import UIKit

extension String {
    
    /// Returns the NSRange value of a specified string.
    ///
    /// - Returns: NSRange of the string
    func range() -> NSRange {
        return NSString(string: self).range(of: self)
    }
    
    /// Indicates if the string matches the specified regex.
    ///
    /// - Parameter regex: Regular expression to match
    /// - Returns: Boolean value indicating if the string matches the regex
    func matches(_ regex: NSRegularExpression) -> Bool {
        return regex.numberOfMatches(in: self, options: .withTransparentBounds, range: self.range()) > 0
    }
}
