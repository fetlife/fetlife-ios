//
//  MessagesViewController.swift
//  FetLife
//
//  Created by Jose Cortinas on 4/20/16.
//  Copyright © 2016 BitLove Inc. All rights reserved.
//

import UIKit
import RealmSwift
import JSQMessagesViewController
import StatefulViewController

class MessagesViewController: JSQMessagesViewController, StatefulViewController {
    var conversation: Conversation! {
        didSet {
            self.messages = try! Realm()
                .objects(Message)
                .filter("conversationId == %@", self.conversation.id)
                .sorted("createdAt", ascending: true)
        }
    }
    
    var messages: Results<Message>!
    var notificationToken: NotificationToken?
    
    let bubbleImageFactory = JSQMessagesBubbleImageFactory(bubbleImage: UIImage.init(named: "MessageBubble"), capInsets: UIEdgeInsetsZero)
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadingView = LoadingView(frame: view.frame)
        errorView = ErrorView(frame: view.frame)
        
        automaticallyScrollsToMostRecentMessage = true
        
        inputToolbar.contentView.leftBarButtonItem = nil
        inputToolbar.barTintColor = UIColor.incomingMessageBGColor();
        inputToolbar.tintColor = UIColor.brickColor()
        
        inputToolbar.contentView.textView.placeHolder = "What say you?"
        inputToolbar.contentView.textView.placeHolderTextColor = UIColor.lightTextColor()
        inputToolbar.contentView.textView.backgroundColor = UIColor.backgroundColor()
        inputToolbar.contentView.textView.textColor = UIColor.whiteColor()
        inputToolbar.contentView.textView.layer.borderWidth = 0.0
        inputToolbar.contentView.textView.layer.cornerRadius = 2.0
        
        collectionView.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        collectionView.backgroundColor = UIColor.backgroundColor()
        
        collectionView.collectionViewLayout.messageBubbleFont = UIFont.systemFontOfSize(16.0)
        
        if let conversation = conversation {
            self.notificationToken = messages.addNotificationBlock({ [unowned self] results, error in
                guard let results = results where !results.isEmpty else { return }
                
                self.collectionView.reloadData()
                
                let newMessageIds = results.filter("isNew == true").map { $0.id }
                
                if !newMessageIds.isEmpty {
                    API.sharedInstance.markMessagesAsRead(conversation.id, messageIds: newMessageIds)
                }
            })
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        // Springiness acts like iOS messsages, not completely stable yet, but cool.
        // collectionView.collectionViewLayout.springinessEnabled = true
        fetchMessages()
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageData! {
        return messages[indexPath.row]
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAtIndexPath indexPath: NSIndexPath!) -> JSQMessageBubbleImageDataSource! {
        let message = messages[indexPath.row]
        
        if message.senderId() == senderId {
            return bubbleImageFactory.outgoingMessagesBubbleImageWithColor(UIColor.outgoingMessageBGColor())
        }
        
        return bubbleImageFactory.incomingMessagesBubbleImageWithColor(UIColor.incomingMessageBGColor())
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAtIndexPath indexPath: NSIndexPath!) -> NSAttributedString! {
        if indexPath.item % 5 == 0 {
            let message = messages[indexPath.item]
            return JSQMessagesTimestampFormatter.sharedFormatter().attributedTimestampForDate(message.createdAt)
        }
    
        return nil
    }
    
    override func collectionView(collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAtIndexPath indexPath: NSIndexPath!) -> CGFloat {
        if indexPath.item % 5 == 0 {
            return kJSQMessagesCollectionViewCellLabelHeightDefault
        }
        
        return 0.0
    }
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAtIndexPath: indexPath) as! JSQMessagesCollectionViewCell
        
        cell.textView.textColor = UIColor.messageTextColor()
        
        cell.textView.linkTextAttributes = [
            NSForegroundColorAttributeName: cell.textView.textColor!
        ]
        
        return cell
    }
    
    @IBAction func refreshAction(sender: UIBarButtonItem) {
        fetchMessages()
    }
    
    func fetchMessages() {
        if let conversation = conversation, let messages = messages {
            let conversationId = conversation.id
            
            if let lastMessage = messages.first {
                let parameters: Dictionary<String, AnyObject> = [
                    "since": Int(lastMessage.createdAt.timeIntervalSince1970),
                    "since_id": lastMessage.id
                ]
                
                Dispatch.asyncOnUserInitiatedQueue() {
                    API.sharedInstance.loadMessages(conversationId, parameters: parameters, completion: nil)
                }
            } else {
                Dispatch.asyncOnUserInitiatedQueue() {
                    API.sharedInstance.loadMessages(conversationId, completion: nil)
                }
            }
        }
    }
}