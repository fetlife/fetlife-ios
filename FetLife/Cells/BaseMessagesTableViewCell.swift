//
//  BaseMessagesTableViewCell.swift
//  FetLife
//
//  Created by Jose Cortinas on 2/11/16.
//  Copyright © 2016 BitLove Inc. All rights reserved.
//

import UIKit

class BaseMessagesTableViewCell: UITableViewCell {
    
    @IBOutlet weak var bodyLabel: MessageTextView!
    @IBOutlet weak var unreadMarkerView: UIView!
    @IBOutlet weak var messageContainerView: UIView!
    
    var message: Message? = nil {
        didSet {
            if let message = message {
                self.bodyLabel.text = message.isSending ? "Sending..." : message.body
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
    }

}
