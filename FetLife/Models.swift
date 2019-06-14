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
import HTMLEntities

private let dateFormatter: DateFormatter = DateFormatter()

// MARK: - Member

class Member: Object, JSONDecodable {
    static let defaultAvatarURL = "https://ass3.fetlife.com/images/avatar_missing_200x200.gif"
    
    @objc dynamic var id = ""
    @objc dynamic var nickname = ""
    @objc dynamic var metaLine = ""
    @objc dynamic var avatarURL = ""
    @objc dynamic var avatarImageData: Data?
    @objc dynamic var orientation = ""
    @objc dynamic var aboutMe = ""
    @objc dynamic var age: Int = 0
    @objc dynamic var city = ""
    @objc dynamic var state = ""
    @objc dynamic var country = ""
    @objc dynamic var genderName = ""
    @objc dynamic var canFollow = true
    @objc dynamic var contentType = ""
    @objc dynamic var fetProfileURL = ""
    @objc dynamic var isSupporter = false
    @objc dynamic var relationWithMe = ""
    @objc dynamic var friendCount: Int = 0
    @objc dynamic var blocked = false
    @objc dynamic var lookingFor: [String] { // we're using this complicated mess because Realm doesn't support primitive arrays 😑
        get {
            return _lookingFor.map { $0.stringValue }
        }
        set {
            _lookingFor.removeAll()
            _lookingFor.append(objectsIn: newValue.map({ RealmString(value: [$0]) }))
        }
    }
    private let _lookingFor = List<RealmString>()
    @objc dynamic var notificationToken = ""
    var additionalInfoRetrieved: Bool { get { guard orientation != "" && contentType != "" && country != "" else { return false }; return true } }
    @objc var lastUpdated: Date = Date()
    
    override static func ignoredProperties() -> [String] {
        return ["lookingFor", "additionalInfoRetrieved", "blocked"]
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
    
    private static var addlInfoAttempts = 0
    static func getAdditionalUserInfo(_ member: Member, _ completion: ((Bool, Member?) -> Void)?) {
        
        let oldMember = try! Realm().objects(Member.self).filter("id == %@", member.id).first ?? member
        print("Old member \(member.nickname) == member? \(oldMember == member)")
        print("Additional info retrieved: \(oldMember.additionalInfoRetrieved)")
        print("Old member last updated \(oldMember.lastUpdated.description(with: Locale.current))")
        if !oldMember.additionalInfoRetrieved || oldMember != member {
            print("Getting additional user info for \(member.nickname)...")
            let realm = try! Realm()
            if realm.isInWriteTransaction { // we can't add a change notification while in a write transaction, so we have to wait...
                if addlInfoAttempts <= 10 {
                    addlInfoAttempts += 1
                    print("Unable to get additional user info for \(member.nickname). Will try again in ~\(addlInfoAttempts)s...")
                    Dispatch.delay(Double(addlInfoAttempts) * (2 * drand48())) { // randomized to prevent collisions with other cells
                        self.getAdditionalUserInfo(member, completion)
                    }
                    return
                } else {
                    print("Getting additional user info for \(member.nickname) failed too many times!")
                }
            } else {
                Dispatch.delay(drand48() * 2) {
                    // get a more detailed Member object from the API and replace when possible
                    let sd = Date()
                    API.sharedInstance.getFetUser(member.id, completion: { (userInfo, err) in
                        if err == nil && userInfo != nil {
                            do {
                                if let u = userInfo {
                                    try member.updateMemberInfo(u) { m in
                                        self.addlInfoAttempts = 0
                                        print("Successfully updated user info for \(m.nickname)")
                                        let fd = Date()
                                        print("time elapsed: \(fd.timeIntervalSince(sd))\n---")
                                        completion?(true, m)
                                    }
                                }
                            } catch let e {
                                print("Error updating info for \(member.nickname): \(e.localizedDescription)")
                                completion?(false, nil)
                                return
                            }
                        } else if err != nil {
                            completion?(false, nil)
                        }
                    })
                    addlInfoAttempts = 0
                }
            }
        } else {
            completion?(true, member)
        }
    }
    
    private var updateAttempts: Int = 0
    func updateMemberInfo(_ json: JSON, completion: @escaping ((Member) throws -> Void)) throws {

        let realm = try! Realm()
        if realm.isInWriteTransaction { // we can't add a change notification while in a write transaction, so we have to wait...
            if updateAttempts <= 10 {
                updateAttempts += 1
                let updateDelay: Double = Double(updateAttempts) * (drand48() + drand48())
                print("Unable to update member info. Will try again in ~\(updateDelay)s...")
                Dispatch.delay(updateDelay) { // randomized to prevent collisions with other cells
                    try? self.updateMemberInfo(json, completion: completion)
                }
            } else {
                print("Updating member info failed too many times!")
            }
        } else {
            realm.beginWrite()
            if let err = try? json.getString(at: "error") {
                if err == "Forbidden" {
                    blocked = true
                    try! realm.commitWrite()
                    throw APIError.Forbidden
                } else {
                    try! realm.commitWrite()
                    throw APIError.General(description: err)
                }
            } else {
                blocked = false
            }
            
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
            
            try completion(self)
            updateAttempts = 0
        }
    }
    
    static func getMemberFromURL(_ url: URL) -> Member? {
        guard url.absoluteString.matches(CommonRegexes.profileURL) else { return nil }
        return try! Realm().objects(Member.self).filter("fetProfileURL == %@", url.absoluteString.lowercased()).first
    }
    
    static func getMemberFromString(_ url: String) -> Member? {
        guard url.matches(CommonRegexes.profileURL) else { return nil }
        return try! Realm().objects(Member.self).filter("fetProfileURL == %@", url.lowercased()).first
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
    @objc dynamic var id = ""
    @objc dynamic var updatedAt = Date()
    @objc dynamic var member: Member?
    @objc dynamic var hasNewMessages = false
    @objc dynamic var isArchived = false
    @objc dynamic var subject = ""
    
    @objc dynamic var lastMessageBody = ""
    @objc dynamic var lastMessageCreated = Date()
    @objc dynamic var lastMessageIsIncoming = false
    
    private var json: JSON!
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    override static func ignoredProperties() -> [String] {
        return ["json"]
    }
    
    required convenience init(json: JSON) throws {
        self.init()
        
        self.json = json
        id = try json.getString(at: "id")
        updatedAt = try dateStringToNSDate(json.getString(at: "updated_at"))!
        
        if let mID = try? json.getString(at: "member", "id"), let m = try! Realm().objects(Member.self).filter("id == %@", mID).first {
            self.member = m
        } else {
            self.member = try? json.decode(at: "member", type: Member.self)
        }
        
        hasNewMessages = try json.getBool(at: "has_new_messages")
        isArchived = try json.getBool(at: "is_archived")
        if let lastMessage = json["last_message"] {
            lastMessageBody = try decodeHTML(lastMessage.getString(at: "body"))
            lastMessageCreated = try dateStringToNSDate(lastMessage.getString(at: "created_at"))!
            let lastMessageMemberID: String = try lastMessage.getString(at: "member", "id")
            let memberID: String = try json.getString(at: "member", "id")
            lastMessageIsIncoming = (lastMessageMemberID == memberID)
        }
        subject = (try? json.getString(at: "subject")) ?? ""
        
        Dispatch.asyncOnUserInitiatedQueue {
            guard self.member != nil else { return }
            if self.member!.lastUpdated.hoursFromNow >= 24 { // every 24 hours update the user profile information
                Member.getAdditionalUserInfo(self.member!, nil)
            }
        }
    }
    
    private var attempts: Int = 0
    func updateMember() {
        let realm: Realm = (self.realm != nil) ? self.realm! : try! Realm()
        if realm.isInWriteTransaction {
            if attempts <= 10 {
                attempts += 1
                print("Unable to create member. Will try again in ~\(attempts)s...")
                Dispatch.delay(Double(attempts) * (2 * drand48())) { // randomized to prevent collisions with other cells
                    self.updateMember()
                }
            } else {
                print("Creating member failed too many times!")
            }
        } else {
            let _m = self.member
            do {
                try realm.write {
                    if let id = _m?.id, let m = try! Realm().objects(Member.self).filter("id == %@", id).first {
                        self.member = m
                    } else {
                        self.member = _m
                    }
                    guard self.member != nil else { return }
                    realm.add(self.member!, update: true)
                }
                
                // get existing conversation in realm if possible
                if let c = try! Realm().objects(Conversation.self).filter("id == %@", self.id).first, let m = self.member {
                    // create thread-safe reference to conversation
                    let wrappedConvo = ThreadSafeReference(to: c)
                    let threadSafeMember = realm.resolve(wrappedConvo)?.member ?? m
                    try realm.write {
                        realm.add(threadSafeMember, update: true)
                    }
                } else if self.member == nil {
                    print("Member is still nil")
                } else {
                    print("Could not find conversation in Realm!")
                }
            } catch let e {
                print("Error updating conversation in Realm: \(e.localizedDescription)")
            }
            attempts = 0
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
    @objc dynamic var id = ""
    @objc dynamic var body = ""
    @objc dynamic var createdAt = Date()
    @objc dynamic var memberId = ""
    @objc dynamic var memberNickname = ""
    @objc dynamic var isNew = false
    @objc dynamic var isSending = false
    @objc dynamic var conversationId = ""
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    required convenience init(json: JSON) throws {
        self.init()
        if let error = try? json.getString(at: "error") {
            print(error)
            if error == "Forbidden" {
                throw APIError.Forbidden
            } else {
                throw APIError.General(description: error)
            }
        }
        
        id = try json.getString(at: "id")
        
        if let msg = try! Realm().objects(Message.self).filter("id == %@", self.id).first as Message? {
            body = msg.body
        } else {
            body = try decodeHTML(json.getString(at: "body"))
        }
        
        createdAt = try dateStringToNSDate(json.getString(at: "created_at"))!
        memberId = try json.getString(at: "member", "id")
        memberNickname = try json.getString(at: "member", "nickname")
        isNew = try json.getBool(at: "is_new")
    }
}


// MARK: - Requests

class FriendRequest: Object {
    @objc dynamic var id = ""
    @objc dynamic var createdAt = Date()
    @objc dynamic var member: Member?
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    required convenience init(json: JSON) throws {
        self.init()
        
        id = try json.getString(at: "id")
        createdAt = try dateStringToNSDate(json.getString(at: "created_at"))!
        member = try json.decode(at: "member", type: Member.self)
    }
}

// MARK: - Util

class RealmString: Object { // using this to be able to store arrays of strings
    @objc dynamic var stringValue = ""
}

// Convert from a JSON format datastring to an NSDate instance.
private func dateStringToNSDate(_ jsonString: String!) -> Date? {
    dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
    return dateFormatter.date(from: jsonString)
}

// Decode html encoded strings. Not recommended to be used at runtime as this this is heavyweight,
// the output should be precomputed and cached.
private func decodeHTML(_ htmlEncodedString: String) -> String {
    // remove extraneous tabs after newlines
    let str = htmlEncodedString.replacingOccurrences(of: "\n   ", with: "\n")
    return str.htmlUnescape()
}
