//
//  TLErrorView.swift
//  FetLife
//
//  Created by Matt Conz on 8/8/18.
//  Copyright © 2018 BitLove Inc. All rights reserved.
//

import UIKit

class TLErrorView: UIView {

    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var retryButton: UIButton!
    
    var error: ConnectionError? {
        didSet {
            titleLabel.text = error?.title
            messageLabel.text = error?.message
        }
    }
}
