//
//  NotificationViewController.swift
//  FetLife
//
//  Created by Matt Conz on 8/14/18.
//  Copyright © 2018 BitLove Inc. All rights reserved.
//

import UIKit
import WebKit
import Turbolinks

class NotificationViewController: TLNavViewController {
    
    override func baseURL() -> URL { return URL(string: "https://fetlife.com/notifications")! }
    override func tabTitle() -> String { return "Notifications" }
    override func tab() -> TabIndex { return .Notifications }
}
