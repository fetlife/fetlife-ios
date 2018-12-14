//
//  BaseMessagesTableViewCell.swift
//  FetLife
//
//  Created by Jose Cortinas on 2/11/16.
//  Copyright © 2016 BitLove Inc. All rights reserved.
//

import UIKit
import SafariServices

class BaseMessagesTableViewCell: UITableViewCell, UITextViewDelegate {
    
    @IBOutlet weak var bodyLabel: MessageTextView!
    @IBOutlet weak var unreadMarkerView: UIView!
    @IBOutlet weak var messageContainerView: UIView!
    @IBOutlet weak var messageTimestamp: UILabel!
    
    let dateFormatter = DateFormatter()
    var navCon: UIViewController!
    var tapGesture: UITapGestureRecognizer!
    var tableView: UITableView!
    
    var message: Message? = nil {
        didSet {
            if let m = message {
                self.bodyLabel.text = m.isSending ? "Sending..." : m.body
                let timeSince: TimeInterval = m.createdAt.timeIntervalSinceNow
                // if it's been less than a day, show relative time
                if abs(timeSince) <= 60 * 60 * 24 {
                    self.messageTimestamp.text = m.createdAt.relativeTime
                } else {
                    self.messageTimestamp.text = dateFormatter.string(from: m.createdAt)
                }
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        dateFormatter.dateStyle = .short
        dateFormatter.timeStyle = .medium
        dateFormatter.locale = .current
        if let m = message {
            let timeSince: TimeInterval = m.createdAt.timeIntervalSinceNow
            // if it's been less than a day, show relative time
            if abs(timeSince) <= 60 * 60 * 24 {
                self.messageTimestamp.text = m.createdAt.relativeTime
            } else {
                self.messageTimestamp.text = dateFormatter.string(from: m.createdAt)
            }
        }
        bodyLabel.delegate = self
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(bodyWasTapped(_:)))
        tapGesture.numberOfTapsRequired = 2
        self.addGestureRecognizer(tapGesture)
        self.bodyLabel.addGestureRecognizer(tapGesture)
        messageTimestamp.isHidden = true
    }
    
    override func copy() -> Any {
        return message?.body ?? ""
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if URL.absoluteString.matches(CommonRegexes.profileURL) {
            if let friend = Member.getMemberFromURL(URL) {
                let fpvc = storyboard.instantiateViewController(withIdentifier: "vcFriendProfile") as! FriendProfileViewController
                fpvc.friend = friend
                (storyboard.instantiateViewController(withIdentifier: "ncMessages") as! UINavigationController).pushViewController(fpvc, animated: true)
                navCon.navigationController?.pushViewController(fpvc, animated: true)
            } else {
                return true
            }
        } else {
            if let scheme = URL.scheme, scheme.hasPrefix("http") {
                let svc = SFSafariViewController(url: URL)
                if #available(iOS 10.0, *) {
                    svc.preferredBarTintColor = .backgroundColor()
                    svc.preferredControlTintColor = .brickColor()
                }
                navCon.present(svc, animated: true, completion: nil)
            } else {
                return true
            }
        }
        return false
    }
    
    @available(iOS 10.0, *)
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        if URL.absoluteString.matches(CommonRegexes.profileURL) {
            if let friend = Member.getMemberFromURL(URL) {
                let fpvc = storyboard.instantiateViewController(withIdentifier: "vcFriendProfile") as! FriendProfileViewController
                fpvc.friend = friend
                (storyboard.instantiateViewController(withIdentifier: "ncMessages") as! UINavigationController).pushViewController(fpvc, animated: true)
                navCon.navigationController?.pushViewController(fpvc, animated: true)
            } else {
                return true
            }
        } else {
            if let scheme = URL.scheme, scheme.hasPrefix("http") {
                let svc = SFSafariViewController(url: URL)
                svc.preferredBarTintColor = .backgroundColor()
                svc.preferredControlTintColor = .brickColor()
                navCon.present(svc, animated: true, completion: nil)
            } else {
                return true
            }
        }
        return false
    }
    
    override func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//        guard gestureRecognizer == tapGesture else { return super.gestureRecognizer(gestureRecognizer, shouldRequireFailureOf: otherGestureRecognizer) }
        return true
    }
    
    func bodyWasTapped(_ sender: AnyObject) {
        UIView.animate(withDuration: 0.25) {
            self.messageTimestamp.isHidden = !self.messageTimestamp.isHidden
            self.clipsToBounds = false
            self.bodyLabel.sizeToFit()
        }
    }
}

