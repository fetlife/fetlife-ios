//
//  ConversationCell.swift
//  FetLife
//
//  Created by Jose Cortinas on 2/2/16.
//  Copyright © 2016 BitLove Inc. All rights reserved.
//

import UIKit
import RealmSwift
import AlamofireImage

class ConversationCell: UITableViewCell {
    
    // MARK: - Properties
    
    @IBOutlet weak var authorAvatarImage: BlurImageView!
    @IBOutlet weak var authorNicknameLabel: UILabel!
    @IBOutlet weak var authorMetaLabel: UILabel!
    @IBOutlet weak var conversationSubject: UILabel!
    @IBOutlet weak var messageTimestampLabel: UILabel!
    @IBOutlet weak var messageSummaryLabel: UILabel!
    @IBOutlet weak var unreadMarkerView: UIView!
    @IBOutlet weak var messageDirectionImage: UIImageView!
    @IBOutlet weak var supporterImage: UIImageView!
    
    var avatarImageFilter: AspectScaledToFillSizeWithRoundedCornersFilter?
    
    var conversation: Conversation? = nil {
        didSet {
            if let conversation = self.conversation, !conversation.isInvalidated {
                self.messageDirectionImage.image = conversation.lastMessageIsIncoming ? #imageLiteral(resourceName: "IncomingMessage") : #imageLiteral(resourceName: "OutgoingMessage")
                self.messageTimestampLabel.text = conversation.timeAgo()
                self.messageSummaryLabel.text = conversation.summary()
                self.unreadMarkerView.isHidden = !conversation.hasNewMessages
                if conversation.subject != "" {
                    self.conversationSubject.isHidden = false
                    self.conversationSubject.text = conversation.subject
                } else {
                    self.conversationSubject.isHidden = true
                }
                self.authorAvatarImage.awakeFromNib()
                self.awakeFromNib()
            }
        }
    }
    var index: Int = -1
    var tableView: UITableView?
    var notificationToken: NotificationToken? = nil
    
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
            self.setMember()
            if c.subject != "" {
                self.conversationSubject.isHidden = false
                self.conversationSubject.text = c.subject
            } else {
                self.conversationSubject.isHidden = true
            }
        }
        self.authorAvatarImage.awakeFromNib()
        self.supporterImage.tintColor = UIColor.supporterIconTintColor()
    }
    
    private var notificationAttempts: Int = 0
    private func createNotificationToken() {
        
        let realm = try! Realm()
        
        if realm.isInWriteTransaction { // we can't add a change notification while in a write transaction, so we have to wait...
            if notificationAttempts <= 10 {
                notificationAttempts += 1
                let attemptDelay: Double = Double(notificationAttempts) * (2 * drand48())
                print("Unable to create a notification token. Will try again in ~\(attemptDelay)s...")
                Dispatch.delay(attemptDelay) { // randomized to prevent collisions with other cells
                    self.createNotificationToken()
                }
            } else {
                print("Creating notification token failed too many times!")
            }
        } else {
            notificationToken = conversation?.member?.observe({ (change) in
                switch change {
                case .error(let e):
                    print("Error in conversation object change! Error: \(e.localizedDescription)")
                    break
                case .change(_):
                    self.setMember()
                    break
                case .deleted:
                    print("Conversation deleted!")
                    break
                }
            })
            notificationAttempts = 0
        }
    }
    
    private var attempts: Int = 0
    private func setMember() {
        if conversation!.member != nil && attempts < 10 {
            let member = conversation!.member!
            self.authorAvatarImage.af_setImageWithBlur(withURL: URL(string: member.avatarURL)!, placeholderImage: #imageLiteral(resourceName: "DefaultAvatar"), filter: avatarImageFilter, progress: nil, progressQueue: .main, imageTransition: .noTransition, runImageTransitionIfCached: false, completion: nil)
            if self.authorAvatarImage.image == nil {
                print("Error loading avatar from \(member.avatarURL)")
                self.authorAvatarImage.af_setImage(withURL: Bundle.main.resourceURL!.appendingPathComponent("DefaultAvatar"), filter: avatarImageFilter)
                self.authorAvatarImage.createBlurView()
            }
            if !member.additionalInfoRetrieved {
                Member.getAdditionalUserInfo(member) { (_, m) in
                    self.authorNicknameLabel.text = (m ?? member).nickname
                    self.authorMetaLabel.text = (m ?? member).metaLine
                    self.supporterImage.isHidden = !(m ?? member).isSupporter
                }
            }
            self.authorNicknameLabel.text = member.nickname
            self.authorMetaLabel.text = member.metaLine
            self.supporterImage.isHidden = !member.isSupporter
            if self.conversation!.subject != "" {
                self.conversationSubject.isHidden = false
                self.conversationSubject.text = self.conversation!.subject
            } else {
                self.conversationSubject.isHidden = true
            }
            attempts = 0
        } else if attempts < 10 {
            attempts += 1
            
            print("Member object is nil. Trying again... (attempt \(attempts))")
            Dispatch.delay(1 * Double(attempts), closure: { self.setMember() })
        } else {
            print("Member object is still nil after 10 attempts! Attempting to retrieve from Realm...")
            attempts = 0
            conversation = try! Realm().objects(Conversation.self).filter("id == %@", conversation!.id).first
        }
    }
    
    deinit {
        notificationToken?.invalidate()
    }
}
