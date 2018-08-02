//
//  ConversationCell.swift
//  FetLife
//
//  Created by Jose Cortinas on 2/2/16.
//  Copyright © 2016 BitLove Inc. All rights reserved.
//

import UIKit
import AlamofireImage
import RealmSwift

class ConversationCell: UITableViewCell {
    
    // MARK: - Properties
    
    @IBOutlet weak var authorAvatarImage: BlurImageView!
    @IBOutlet weak var authorNicknameLabel: UILabel!
    @IBOutlet weak var authorMetaLabel: UILabel!
    @IBOutlet weak var messageTimestampLabel: UILabel!
    @IBOutlet weak var messageSummaryLabel: UILabel!
    @IBOutlet weak var unreadMarkerView: UIView!
    @IBOutlet weak var messageDirectionImage: UIImageView!
    @IBOutlet weak var supporterImage: UIImageView!
    
    var avatarImageFilter: AspectScaledToFillSizeWithRoundedCornersFilter?
    
    var conversation: Conversation? = nil {
        didSet {
            if let conversation = self.conversation, !conversation.isInvalidated {
                if let member = conversation.member {
                    self.authorAvatarImage.af_setImageWithBlur(withURL: URL(string: member.avatarURL)!, placeholderImage: #imageLiteral(resourceName: "DefaultAvatar"), filter: avatarImageFilter, progress: nil, progressQueue: .main, imageTransition: .noTransition, runImageTransitionIfCached: false, completion: nil)
                    if self.authorAvatarImage.image == nil {
                        print("Error loading avatar from \(member.avatarURL)")
                        self.authorAvatarImage.af_setImage(withURL: Bundle.main.resourceURL!.appendingPathComponent("DefaultAvatar"), filter: avatarImageFilter)
                        self.authorAvatarImage.createBlurView()
                    }
                    self.messageDirectionImage.image = conversation.lastMessageIsIncoming ? #imageLiteral(resourceName: "IncomingMessage") : #imageLiteral(resourceName: "OutgoingMessage")
                    self.authorNicknameLabel.text = member.nickname
                    self.authorMetaLabel.text = member.metaLine
                    self.supporterImage.isHidden = !member.isSupporter
                }
                
                self.messageTimestampLabel.text = conversation.timeAgo()
                self.messageSummaryLabel.text = conversation.summary()
                self.unreadMarkerView.isHidden = !conversation.hasNewMessages
                self.authorAvatarImage.awakeFromNib()
            }
        }
    }
    var index: Int = -1
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        let selectedCellBackground = UIView()
        selectedCellBackground.backgroundColor = UIColor.black
        
        self.selectedBackgroundView = selectedCellBackground
        
        self.unreadMarkerView.backgroundColor = UIColor.unreadMarkerColor()
        
        self.avatarImageFilter = AspectScaledToFillSizeWithRoundedCornersFilter(size: authorAvatarImage.frame.size, radius: 3.0)
        self.authorAvatarImage.layer.cornerRadius = 3.0
        self.authorAvatarImage.layer.borderWidth = 0.5
        self.authorAvatarImage.layer.borderColor = UIColor.borderColor().cgColor
        
        if let c = conversation {
            self.messageDirectionImage.image = c.lastMessageIsIncoming ? #imageLiteral(resourceName: "IncomingMessage") : #imageLiteral(resourceName: "OutgoingMessage")
            self.messageDirectionImage.tintColor = UIColor.messageTextColor()
        }
        self.authorAvatarImage.awakeFromNib()
        self.supporterImage.tintColor = UIColor.supporterIconTintColor()
    }
}
