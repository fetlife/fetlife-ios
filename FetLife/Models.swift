//
//  Models.swift
//  FetLife
//
//  Created by Jose Cortinas on 2/24/16.
//  Copyright © 2016 BitLove Inc. All rights reserved.
//

import RealmSwift
import Freddy
import DateTools
import JSQMessagesViewController

private let dateFormatter: NSDateFormatter = NSDateFormatter()

// MARK: - Member

class Member: Object, JSONDecodable {
    let defaultAvatarURL = "https://flassets.a.ssl.fastly.net/images/avatar_missing_200x200.gif"
    
    dynamic var id = ""
    dynamic var nickname = ""
    dynamic var metaLine = ""
    dynamic var avatarURL = ""
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    required convenience init(json: JSON) throws {
        self.init()
        
        id = try json.string("id")
        nickname = try json.string("nickname")
        metaLine = try json.string("meta_line")
        avatarURL = try json.string("avatar", "variants", "medium", or: defaultAvatarURL)
    }
}

// MARK: - Conversation

class Conversation: Object, JSONDecodable {
    dynamic var id = ""
    dynamic var updatedAt = NSDate()
    dynamic var member: Member?
    dynamic var hasNewMessages = false
    dynamic var isArchived = false
    
    dynamic var lastMessageBody = ""
    dynamic var lastMessageCreated = NSDate()
    
    override static func primaryKey() -> String? {
        return "id"
    }

    required convenience init(json: JSON) throws {
        self.init()
        
        id = try json.string("id")
        updatedAt = try dateStringToNSDate(json.string("updated_at"))!
        member = try json.decode("member", type: Member.self)
        hasNewMessages = try json.bool("has_new_messages")
        isArchived = try json.bool("is_archived")
        
        if let lastMessage = json["last_message"] {
            lastMessageBody = try decodeHTML(lastMessage.string("body"))
            lastMessageCreated = try dateStringToNSDate(lastMessage.string("created_at"))!
        }
    }
    
    func summary() -> String {
        return lastMessageBody
    }
    
    func timeAgo() -> String {
        return lastMessageCreated.shortTimeAgoSinceNow()
    }

}

// MARK: - Message

class Message: Object, JSQMessageData {
    dynamic var id = ""
    dynamic var body = ""
    dynamic var createdAt = NSDate()
    dynamic var memberId = ""
    dynamic var memberNickname = ""
    dynamic var isNew = false
    dynamic var isSending = false
    dynamic var conversationId = ""
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    required convenience init(json: JSON) throws {
        self.init()
        
        id = try json.string("id")
        body = try decodeHTML(json.string("body"))
        createdAt = try dateStringToNSDate(json.string("created_at"))!
        memberId = try json.string("member", "id")
        memberNickname = try json.string ("member", "nickname")
        isNew = try json.bool("is_new")
    }
    
    func messageHash() -> UInt {
        return UInt(abs(id.hash)) ^ UInt(createdAt.timeIntervalSince1970)
    }
    
    func text() -> String! {
        return body
    }
    
    func senderDisplayName() -> String! {
        return memberNickname
    }
    
    func senderId() -> String! {
        return memberId
    }
    
    func date() -> NSDate! {
        return createdAt
    }
    
    func isMediaMessage() -> Bool {
        return false
    }
}

// MARK: - Util

// Convert from a JSON format datastring to an NSDate instance.
private func dateStringToNSDate(jsonString: String!) -> NSDate? {
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    return dateFormatter.dateFromString(jsonString)
}

// Decode html encoded strings. Not recommended to be used at runtime as this this is heavyweight,
// the output should be precomputed and cached.
private func decodeHTML(htmlEncodedString: String) -> String {
    let encodedData = htmlEncodedString.dataUsingEncoding(NSUTF8StringEncoding)!
    let attributedOptions : [String: AnyObject] = [
        NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType,
        NSCharacterEncodingDocumentAttribute: NSUTF8StringEncoding
    ]
    
    var attributedString:NSAttributedString?
    
    do {
        attributedString = try NSAttributedString(data: encodedData, options: attributedOptions, documentAttributes: nil)
    } catch {
        print(error)
    }
    
    return attributedString!.string
}