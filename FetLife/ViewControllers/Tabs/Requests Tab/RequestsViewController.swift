//
//  RequestsViewController.swift
//  FetLife
//
//  Created by Matt Conz on 8/20/18.
//  Copyright © 2018 BitLove Inc. All rights reserved.
//

import UIKit
import WebKit
import Turbolinks

class RequestsViewController: TLNavViewController {
    
    override func baseURL() -> URL { return URL(string: "https://fetlife.com/requests")! }
    override func tabTitle() -> String { return "Requests" }
    override func tab() -> TabIndex { return .Requests }

}
