//
//  HomeViewController.swift
//  FetLife
//
//  Created by Matt Conz on 8/14/18.
//  Copyright © 2018 BitLove Inc. All rights reserved.
//

import UIKit
import WebKit
import Turbolinks

class HomeViewController: TLNavViewController {
    
    override func baseURL() -> URL { return URL(string: "https://fetlife.com/home")! }
    override func tabTitle() -> String { return "Home" }
    override func tab() -> TabIndex { return .Home }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabBarItem.title = tabTitle()
    }
}
