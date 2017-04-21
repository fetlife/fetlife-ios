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

private let dateFormatter: DateFormatter = DateFormatter()

// MARK: - Member

class Member: Object, JSONDecodable {
    let defaultAvatarURL = "https://ass3.fetlife.com/images/avatar_missing_200x200.gif"

    dynamic var id = ""
    dynamic var nickname = ""
    dynamic var metaLine = ""
    dynamic var avatarURL = ""

    override static func primaryKey() -> String? {
        return "id"
    }

    required convenience init(json: JSON) throws {
        self.init()

        id = try json.getString(at: "id")
        nickname = try json.getString(at: "nickname")
        metaLine = try json.getString(at: "meta_line")
        do {
            avatarURL = try json.getString(at: "avatar", "variants", "medium", or: defaultAvatarURL)
        } catch {
            avatarURL = defaultAvatarURL
        }
    }
}

// MARK: - Conversation

class Conversation: Object, JSONDecodable {
    dynamic var id = ""
    dynamic var updatedAt = Date()
    dynamic var member: Member?
    dynamic var hasNewMessages = false
    dynamic var isArchived = false

    dynamic var lastMessageBody = ""
    dynamic var lastMessageCreated = Date()

    override static func primaryKey() -> String? {
        return "id"
    }

    required convenience init(json: JSON) throws {
        self.init()

        id = try json.getString(at: "id")
        updatedAt = try dateStringToNSDate(json.getString(at: "updated_at"))!
        member = try json.decode(at: "member", type: Member.self)
        hasNewMessages = try json.getBool(at: "has_new_messages")
        isArchived = try json.getBool(at: "is_archived")

        if let lastMessage = json["last_message"] {
            lastMessageBody = try decodeHTML(lastMessage.getString(at: "body"))
            lastMessageCreated = try dateStringToNSDate(lastMessage.getString(at: "created_at"))!
        }
    }

    func summary() -> String {
        return lastMessageBody
    }

    func timeAgo() -> String {
        return (lastMessageCreated as NSDate).shortTimeAgoSinceNow()
    }

}

// MARK: - Message

class Message: Object {
    dynamic var id = ""
    dynamic var body = ""
    dynamic var createdAt = Date()
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

        id = try json.getString(at: "id")
        body = try decodeHTML(json.getString(at: "body"))
        createdAt = try dateStringToNSDate(json.getString(at: "created_at"))!
        memberId = try json.getString(at: "member", "id")
        memberNickname = try json.getString(at: "member", "nickname")
        isNew = try json.getBool(at: "is_new")
    }
}

// MARK: - Util

// Convert from a JSON format datastring to an NSDate instance.
private func dateStringToNSDate(_ jsonString: String!) -> Date? {
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    return dateFormatter.date(from: jsonString)
}

// Decode html encoded strings. Not recommended to be used at runtime as this this is heavyweight,
// the output should be precomputed and cached.
private func decodeHTML(_ htmlEncodedString: String) -> String {
    let encodedData = htmlEncodedString.data(using: String.Encoding.utf8)!
    let attributedOptions : [String: AnyObject] = [
        NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType as AnyObject,
        NSCharacterEncodingDocumentAttribute: NSNumber(value: String.Encoding.utf8.rawValue) as AnyObject
    ]

    var attributedString:NSAttributedString?

    do {
        attributedString = try NSAttributedString(data: encodedData, options: attributedOptions, documentAttributes: nil)
    } catch {
        print(error)
    }

    return attributedString!.string
}
