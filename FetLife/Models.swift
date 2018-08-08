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
    static let defaultAvatarURL = "https://ass3.fetlife.com/images/avatar_missing_200x200.gif"
    
    dynamic var id = ""
    dynamic var nickname = ""
    dynamic var metaLine = ""
    dynamic var avatarURL = ""
    dynamic var avatarImageData: Data?
    dynamic var orientation = ""
    dynamic var aboutMe = ""
    dynamic var age: Int = 0
    dynamic var city = ""
    dynamic var state = ""
    dynamic var country = ""
    dynamic var genderName = ""
    dynamic var canFollow = true
    dynamic var contentType = ""
    dynamic var fetProfileURL = ""
    dynamic var isSupporter = false
    dynamic var relationWithMe = ""
    dynamic var friendCount: Int = 0
    dynamic var lookingFor: [String] { // we're using this complicated mess because Realm doesn't support primitive arrays 😑
        get {
            return _lookingFor.map { $0.stringValue }
        }
        set {
            _lookingFor.removeAll()
            _lookingFor.append(objectsIn: newValue.map({ RealmString(value: [$0]) }))
        }
    }
    private let _lookingFor = List<RealmString>()
    dynamic var notificationToken = ""
    var additionalInfoRetrieved: Bool {
        get {
            guard genderName != "" && orientation != "" else { return false }
            return true
        }
    }
    var lastUpdated: Date = Date()
    
    override static func ignoredProperties() -> [String] {
        return ["lookingFor", "additionalInfoRetrieved"]
    }
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    required convenience init(json: JSON) throws {
        self.init()
        
        id = try json.getString(at: "id")
        nickname = try json.getString(at: "nickname")
        metaLine = try json.getString(at: "meta_line")
        do {
            avatarURL = try json.getString(at: "avatar", "variants", "medium", or: Member.defaultAvatarURL)
            if let aURL = URL(string: avatarURL) {
                avatarImageData = try? Data(contentsOf: aURL)
            }
        } catch {
            avatarURL = Member.defaultAvatarURL
        }
        orientation = (try? json.getString(at: "sexual_orientation")) ?? ""
        aboutMe = (try? json.getString(at: "about")) ?? ""
        age = (try? json.getInt(at: "age")) ?? 0
        city = (try? json.getString(at: "city")) ?? ""
        state = (try? json.getString(at: "administrative_area")) ?? ""
        country = (try? json.getString(at: "country")) ?? ""
        genderName = (try? json.getString(at: "gender", "name")) ?? ""
        canFollow = (try? json.getBool(at: "is_followable")) ?? true
        contentType = (try? json.getString(at: "content_type")) ?? ""
        fetProfileURL = (try? json.getString(at: "url")) ?? ""
        isSupporter = (try? json.getBool(at: "is_supporter")) ?? false
        relationWithMe = (try? json.getString(at: "relation_with_me")) ?? ""
        friendCount = (try? json.getInt(at: "friend_count")) ?? 0
        var lf: [String] = []
        if let ljson = try? json.getArray(at: "looking_for") as [AnyObject] {
            for j in ljson {
                lf.append((j.description) ?? "")
            }
        }
        notificationToken = (try? json.getString(at: "notification_token")) ?? "" // only for logged-in user
        lookingFor = lf
    }
    
    func updateMemberInfo(_ json: JSON) throws -> Member {
        let realm = try! Realm()
        realm.beginWrite() // Realm write operation required because we're updating an existing Realm object
        nickname = (try? json.getString(at: "nickname")) ?? nickname
        metaLine = (try? json.getString(at: "meta_line")) ?? metaLine
        do {
            avatarURL = try json.getString(at: "avatar", "variants", "medium", or: Member.defaultAvatarURL)
            if let aURL = URL(string: avatarURL) {
                avatarImageData = try? Data(contentsOf: aURL)
            }
        } catch {
            avatarURL = Member.defaultAvatarURL
        }
        orientation = (try? json.getString(at: "sexual_orientation")) ?? ""
        aboutMe = (try? json.getString(at: "about")) ?? ""
        age = (try? json.getInt(at: "age")) ?? 0
        city = (try? json.getString(at: "city")) ?? ""
        state = (try? json.getString(at: "administrative_area")) ?? ""
        country = (try? json.getString(at: "country")) ?? ""
        genderName = (try? json.getString(at: "gender", "name")) ?? ""
        canFollow = (try? json.getBool(at: "is_followable")) ?? true
        contentType = (try? json.getString(at: "content_type")) ?? ""
        fetProfileURL = (try? json.getString(at: "url")) ?? ""
        isSupporter = (try? json.getBool(at: "is_supporter")) ?? false
        relationWithMe = (try? json.getString(at: "relation_with_me")) ?? "self"
        friendCount = (try? json.getInt(at: "friend_count")) ?? 0
        var lf: [String] = []
        if let ljson = try? json.getArray(at: "looking_for") as [AnyObject] {
            for j in ljson {
                lf.append((j.description) ?? "")
            }
        }
        lookingFor = lf
        notificationToken = (try? json.getString(at: "notification_token")) ?? "" // only for current logged-in user
        realm.add(self, update: true)
        try! realm.commitWrite()
        lastUpdated = Date()
        return self
    }
    
    static func ==(a: Member, b: Member) -> Bool {
        guard a.id == b.id else { return false }
        guard a.metaLine == b.metaLine else { return false }
        guard a.nickname == b.nickname else { return false }
        return true
    }
    
    static func !=(a: Member, b: Member) -> Bool {
        return !(a == b)
    }
    
    /// Determines if all the properties of two members are the same
    static func ===(a: Member, b: Member) -> Bool {
        guard a.id == b.id else { return false }
        guard a.aboutMe == b.aboutMe else { return false }
        guard a.age == b.age else { return false }
        guard a.avatarURL == b.avatarURL else { return false }
        guard a.canFollow == b.canFollow else { return false }
        guard a.city == b.city else { return false }
        guard a.contentType == b.contentType else { return false }
        guard a.country == b.country else { return false }
        guard a.friendCount == b.friendCount else { return false }
        guard a.genderName == b.genderName else { return false }
        guard a.isSupporter == b.isSupporter else { return false }
        guard a.lookingFor == b.lookingFor else { return false }
        guard a.metaLine == b.metaLine else { return false }
        guard a.nickname == b.nickname else { return false }
        guard a.notificationToken == b.notificationToken else { return false }
        guard a.orientation == b.orientation else { return false }
        guard a.state == b.state else { return false }
        return true
    }
    
    static func !==(a: Member, b: Member) -> Bool {
        return !(a === b)
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
    dynamic var lastMessageIsIncoming = false
    
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
            let lastMessageMemberID: String = try lastMessage.getString(at: "member", "id")
            lastMessageIsIncoming = lastMessageMemberID == member!.id
        }
        if !member!.additionalInfoRetrieved {
            // first try loading the member object from Realm
            let oldMember = try! Realm().objects(Member.self).filter("id == %@", member!.id).first ?? member
            if !oldMember!.additionalInfoRetrieved || oldMember! != member! {
                // if the additional info is still not available, request it from the API
                getAdditionalUserInfo()
            } else {
                member = oldMember
            }
        }
        if member!.lastUpdated.hoursFromNow >= 24 { // every 24 hours update the user profile information
            getAdditionalUserInfo()
        }
    }
    
    func summary() -> String {
        return lastMessageBody
    }
    
    func timeAgo() -> String {
        return (lastMessageCreated as NSDate).shortTimeAgoSinceNow()
    }
    
    private var attempts: Int = 0
    
    private func getAdditionalUserInfo() {
        let realm = try! Realm()
        if realm.isInWriteTransaction { // we can't add a change notification while in a write transaction, so we have to wait...
            if attempts <= 10 {
                attempts += 1
                print("Unable to get additional user info for \(self.member!.nickname). Will try again in ~\(attempts)s...")
                Dispatch.delay(Double(attempts) * (2 * drand48())) { // randomized to prevent collisions with other cells
                    self.getAdditionalUserInfo()
                }
            } else {
                print("Getting additional user for \(self.member!.nickname) info failed too many times!")
            }
        } else {
            Dispatch.delay(drand48()) {
                // get a more detailed Member object from the API and replace when possible
                API.sharedInstance.getFetUser(self.member!.id, completion: { (userInfo, err) in
                    if err == nil && userInfo != nil {
                        do {
                            if let u = userInfo {
                                let m = try self.member!.updateMemberInfo(u)
                                realm.beginWrite()
                                self.member = m
                                realm.add(self, update: true)
                                try realm.commitWrite()
                            }
                        } catch let e {
                            print("Error updating info: \(e.localizedDescription)")
                            return
                        }
                    }
                })
                self.attempts = 0
                print("Successfully updated user info for \(self.member!.nickname)")
            }
        }
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

// MARK: - Story
// MARK: - Util

class RealmString: Object { // using this to be able to store arrays of strings
    dynamic var stringValue = ""
}

// Convert from a JSON format datastring to an NSDate instance.
private func dateStringToNSDate(_ jsonString: String!) -> Date? {
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    return dateFormatter.date(from: jsonString)
}

// Decode html encoded strings. Not recommended to be used at runtime as this this is heavyweight,
// the output should be precomputed and cached.
private func decodeHTML(_ htmlEncodedString: String) -> String {
    // replace newline character ("\n") with placeholder to preserve line breaks
    let es = htmlEncodedString.replacingOccurrences(of: "\n", with: "\\n")
    let encodedData = es.data(using: String.Encoding.utf8)!
    let attributedOptions: [String: AnyObject] = [
        NSDocumentTypeDocumentAttribute: NSHTMLTextDocumentType as AnyObject,
        NSCharacterEncodingDocumentAttribute: NSNumber(value: String.Encoding.utf8.rawValue) as AnyObject
    ]
    
    var attributedString: NSAttributedString?
    
    // FIXME: - This will fail if initiated from a background thread. We may want to consider a more robust option such as https://github.com/IBM-Swift/swift-html-entities
    do {
        attributedString = try NSAttributedString(data: encodedData, options: attributedOptions, documentAttributes: nil)
    } catch {
        print(error)
    }
    
    return attributedString?.string.replacingOccurrences(of: "\\n", with: "\n") ?? es // replace placeholders with original linebreaks
}
