//
//  AccountSettingsViewController.swift
//  FetLife
//
//  Created by Matt Conz on 8/26/18.
//  Copyright © 2018 BitLove Inc. All rights reserved.
//

import UIKit
import Turbolinks

class AccountSettingsViewController: TLViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        baseURL = URL(string: "https://fetlife.com/settings/account")!
        url = baseURL
        tab = TabIndex.Settings
        navCon = self.navigationController!
    }
}
