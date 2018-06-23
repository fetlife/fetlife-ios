//
//  FetAPI.swift
//  FetLife
//
//  Created by Jose Cortinas on 2/3/16.
//  Copyright © 2016 BitLove Inc. All rights reserved.
//

import Foundation
import UIKit
import Alamofire
import Freddy
import p2_OAuth2
import JWTDecode
import RealmSwift

// MARK: - API Singleton

final class API {
    
    // Make this a singleton, accessed through sharedInstance
    static let sharedInstance = API()
    
    let baseURL: String
    let oauthSession: OAuth2CodeGrant
    
    private var memberId: String?
    private var memberNickname: String?
    var currentMember: Member?
    
    class func isAuthorized() -> Bool {
        return sharedInstance.isAuthorized()
    }
    
    class func currentMemberId() -> String? {
        return sharedInstance.memberId
    }
    
    class func currentMemberNickname() -> String? {
        return sharedInstance.memberNickname
    }
    
    /// Authorizes the current user.
    ///
    /// - Parameters:
    ///   - context: Context of the authorization
    ///   - onAuthorize: Completion to run upon authorization
    class func authorizeInContext(_ context: AnyObject, onAuthorize: @escaping (_ parameters: OAuth2JSON?, _ error: Error?) -> Void) {
        guard isAuthorized() else {
//          sharedInstance.oauthSession.authorize(callback: onAuthorize)
//          sharedInstance.oauthSession.failure(callback: onFailure)
			let storage = HTTPCookieStorage.shared
			storage.cookies?.forEach() { storage.deleteCookie($0) }
            sharedInstance.oauthSession.authorizeEmbedded(from: context, callback: onAuthorize)
            return
        }
    }
    
    fileprivate init() {
        let info = Bundle.main.infoDictionary!
        
        self.baseURL = info["FETAPI_BASE_URL"] as! String
        
        let clientID = info["FETAPI_OAUTH_CLIENT_ID"] as! String
        let clientSecret = info["FETAPI_OAUTH_CLIENT_SECRET"] as! String
        
        oauthSession = OAuth2CodeGrant(settings: [
            "client_id": clientID,
            "client_secret": clientSecret,
            "authorize_uri": "\(baseURL)/oauth/authorize",
            "token_uri": "\(baseURL)/oauth/token",
            "scope": "",
            "redirect_uris": ["fetlifeapp://oauth/callback"],
            "verbose": false
        ] as OAuth2JSON)
        
        oauthSession.authConfig.ui.useSafariView = true
		oauthSession.authConfig.authorizeEmbeddedAutoDismiss = true
		
        if let accessToken = oauthSession.accessToken {
            do {
                let jwt = try decode(jwt: accessToken)
                
				if let userDictionary: Dictionary<String, Any> = jwt.body["user"] as? Dictionary<String, Any> {
                    self.memberId = userDictionary["id"] as? String
                    self.memberNickname = userDictionary["nick"] as? String
                }
            } catch(let error) {
                print(error)
            }
        }
    }
    
    func isAuthorized() -> Bool {
        return oauthSession.hasUnexpiredAccessToken()
    }
    
    // MARK: - Conversation API
    
    /// Loads all the conversations for the current user.
    ///
    /// - Parameter completion: Optional completion with error
    func loadConversations(_ completion: ((_ error: Error?) -> Void)?) {
        let parameters = ["limit": 100, "order": "-updated_at", "with_archived": true] as [String : Any]
        let url = "\(baseURL)/v2/me/conversations"
        
        oauthSession.request(.get, url, parameters: parameters).responseData { response -> Void in
            switch response.result {
            case .success(let value):
                do {
                    let json = try JSON(data: value).getArray()
                    if json.isEmpty {
                        completion?(nil)
                        return
                    }
                    
                    let realm = try! Realm()
					realm.refresh() // make sure Realm instance is the most recent version
					realm.beginWrite()
                    for c in json {
                        let conversation = try! Conversation.init(json: c)
                        realm.add(conversation, update: true)
                    }
                    
                    try! realm.commitWrite()
                    completion?(nil)
                } catch(let error) {
                    completion?(error)
                }
            case .failure(let error):
                completion?(error)
            }
        }
    }
    
    /// Archives the specified conversation.
    ///
    /// - Parameters:
    ///   - conversationId: ID of conversation to archive
    ///   - completion: Optional completion with error
    func archiveConversation(_ conversationId: String, completion: ((_ error: Error?) -> Void)?) {
        let parameters = ["is_archived": true]
        let url = "\(baseURL)/v2/me/conversations/\(conversationId)"
        
        oauthSession.request(.put, url, parameters: parameters).responseData { response -> Void in
            switch response.result {
            case .success(let value):
                do {
                    let json = try JSON(data: value)
                    
                    let conversation = try Conversation.init(json: json)
                    
                    let realm = try Realm()
                    realm.refresh() // make sure Realm instance is the most recent version
                    try realm.write {
                        realm.add(conversation, update: true)
                    }
                    
                    completion?(nil)
                } catch(let error) {
                    completion?(error)
                }
            case .failure(let error):
                completion?(error)
            }
        }
    }
    
    func unarchiveConversation(_ conversationId: String, completion: ((_ error: Error?) -> Void)?) {
        let parameters = ["is_archived": false]
        let url = "\(baseURL)/v2/me/conversations/\(conversationId)"
        
        oauthSession.request(.put, url, parameters: parameters).responseData { response -> Void in
            switch response.result {
            case .success(let value):
                do {
                    let json = try JSON(data: value)
                    
                    let conversation = try Conversation.init(json: json)
                    
                    let realm = try Realm()
                    realm.refresh() // make sure Realm instance is the most recent version
                    try realm.write {
                        realm.add(conversation, update: true)
                    }
                    
                    completion?(nil)
                } catch(let error) {
                    completion?(error)
                }
            case .failure(let error):
                completion?(error)
            }
        }
    }
    
    /// Gets the messages in a conversation.
    ///
    /// - Parameters:
    ///   - conversationId: ID of conversation to load
    ///   - extraParameters: A dictionary of any additional parameters to send
    ///   - completion: Optional completion with error
    func loadMessages(_ conversationId: String, parameters extraParameters: Dictionary<String, Any> = [:], completion: ((_ error: Error?) -> Void)?) {
        let url = "\(baseURL)/v2/me/conversations/\(conversationId)/messages"
        var parameters: Dictionary<String, Any> = ["limit": 100 as Any]

        for (k, v) in extraParameters {
            parameters.updateValue(v, forKey: k)
        }
        
        oauthSession.request(.get, url, parameters: parameters).responseData { response in
            switch response.result {
            case .success(let value):
                do {
                    let json = try JSON(data: value).getArray()
                    
                    if json.isEmpty {
                        completion?(nil)
                        return
                    }
                    
                    let realm = try! Realm()
                    realm.refresh() // make sure Realm instance is the most recent version
                    realm.beginWrite()
                    
                    for m in json {
                        let message = try Message.init(json: m)
                        message.conversationId = conversationId
                        realm.add(message, update: true)
                    }
                    
                    try! realm.commitWrite()
                    
                    completion?(nil)
                } catch(let error) {
                    completion?(error)
                }
            case .failure(let error):
                completion?(error)
            }
        }
    }
    
    /// Creates a message in a conversation with the specified text.
    ///
    /// - Parameters:
    ///   - conversationId: The conversation ID
    ///   - messageBody: The text of the message
    func createAndSendMessage(_ conversationId: String, messageBody: String) {
        let parameters = ["body": messageBody]
        let url = "\(baseURL)/v2/me/conversations/\(conversationId)/messages"
        
        oauthSession.request(.post, url, parameters: parameters).responseData { response in
            switch response.result {
            case .success(let value):
                do {
                    let json = try JSON(data: value)
                    
                    let realm = try! Realm()
                    realm.refresh() // make sure Realm instance is the most recent version
					let conversation: Conversation? = realm.object(ofType: Conversation.self, forPrimaryKey: conversationId as AnyObject)
                    let message = try Message(json: json)
                    
                    message.conversationId = conversationId
                    
                    try! realm.write {
                        conversation?.lastMessageBody = message.body
                        conversation?.lastMessageCreated = message.createdAt
						conversation?.lastMessageIsIncoming = false
                        realm.add(message)
                    }
                    
                } catch(let error) {
                    print(error)
                }
            case .failure(let error):
                print(error)
            }
        }
    }
    
    /// Marks a conversation as read.
    ///
    /// - Parameters:
    ///   - conversationId: ID of the conversation
    ///   - messageIds: Message(s) to mark as read
    ///   - completion: Optional completion closure with error
    func markMessagesAsRead(_ conversationId: String, messageIds: [String], completion: ((_ error: Error?) -> Void)?) {
        let parameters = ["ids": messageIds]
        let url = "\(baseURL)/v2/me/conversations/\(conversationId)/messages/read"
        
        oauthSession.request(.put, url, parameters: parameters).responseData { response in
            switch response.result {
            case .success:
                let realm = try! Realm()
                realm.refresh() // make sure Realm instance is the most recent version
                let conversation = realm.object(ofType: Conversation.self, forPrimaryKey: conversationId as AnyObject)
                
                try! realm.write {
                    conversation?.hasNewMessages = false
                }
                completion?(nil)
            case .failure(let error):
                print(error)
                completion?(error)
            }
        }
    }
    
    /// Logs the user out of Fetlife by forgetting OAuth tokens and removing all fetlife cookies.
    func logout() {
        oauthSession.forgetTokens();
        let storage = HTTPCookieStorage.shared
        storage.cookies?.forEach() { storage.deleteCookie($0) }
        let realm: Realm = try! Realm()
        try! realm.write {
            realm.deleteAll()
        }
    }
    
    // MARK: - Profile API
    
    /// Gets the profile of the specified user.
    ///
    /// - Important: Do not use this to get the profile of the currently logged-in user. Instead, use getMe(_:).
    /// - Parameters:
    ///   - userID: ID of the user whose profile you wish to retrieve
    ///   - completion: Optional completion handler taking `JSON?` and `Error?` parameters
    func getFetUser(_ userID: String, completion: ((_ userInfo: JSON?, _ error: Error?) -> Void)?) {
        let url = "\(baseURL)/v2/members/\(userID)"
        
        oauthSession.request(.get, url, parameters: nil).responseData { response -> Void in
            switch response.result {
            case .success(let value):
                do {
                    let json: JSON = try JSON(data: value)
                    completion?(json, nil)
                } catch(let error) {
                    print("Error reading JSON data")
                    completion?(nil, error)
                }
            case .failure(let error):
                print("Error: \(error.localizedDescription)")
                completion?(nil, error)
            }
        }
    }
    
    // Extremely useful for making app store screenshots, keeping this around for now.
    func fakeConversations() -> JSON {
        return JSON.array([
            
            .dictionary([ // 1
                "id": .string("fake-convo-1"),
                "updated_at": .string("2016-03-11T02:29:27.000Z"),
                "member": .dictionary([
                    "id": .string("fake-member-1"),
                    "nickname": .string("JohnBaku"),
                    "meta_line": .string("38M Dom"),
                    "avatar": .dictionary([
                        "status": "sfw",
                        "variants": .dictionary(["medium": "https://flpics0.a.ssl.fastly.net/0/1/0005031f-846f-5022-a440-3bf29e0a649e_110.jpg"])
                    ])
                ]),
                "has_new_messages": .bool(true),
                "is_archived": .bool(false),
                "last_message": .dictionary([
                    "created_at": .string("2016-03-11T02:29:27.000Z"),
                    "body": .string("Welcome?! Welcome!"),
                    "member": .dictionary([
                        "id": .string("fake-member-1"),
                        "nickname": .string("JohnBaku"),
                    ])
                ])
            ]),
            
            .dictionary([ // 2
                "id": .string("fake-convo-2"),
                "updated_at": .string("2016-03-11T02:22:27.000Z"),
                "member": .dictionary([
                    "id": .string("fake-member-2"),
                    "nickname": .string("phoenix_flame"),
                    "meta_line": .string("24F Undecided"),
                    "avatar": .dictionary([
                        "status": "sfw",
                        "variants": .dictionary(["medium": "https://flpics2.a.ssl.fastly.net/729/729713/00051c06-0754-8b77-802c-c87e9632d126_110.jpg"])
                    ])
                ]),
                "has_new_messages": .bool(false),
                "is_archived": .bool(false),
                "last_message": .dictionary([
                    "created_at": .string("2016-03-11T02:22:27.000Z"),
                    "body": .string("Miss you!"),
                    "member": .dictionary([
                        "id": .string("fake-member-2"),
                        "nickname": .string("phoenix_flame"),
                    ])
                ])
            ]),
            
            .dictionary([ // 3
                "id": .string("fake-convo-3"),
                "updated_at": .string("2016-03-11T00:59:27.000Z"),
                "member": .dictionary([
                    "id": .string("fake-member-3"),
                    "nickname": .string("_jose_"),
                    "meta_line": .string("28M Evolving"),
                    "avatar": .dictionary([
                        "status": "sfw",
                        "variants": .dictionary(["medium": "https://flpics0.a.ssl.fastly.net/1568/1568309/0004c1d4-637c-8930-0e97-acf588a65176_110.jpg"])
                    ])
                ]),
                "has_new_messages": .bool(false),
                "is_archived": .bool(false),
                "last_message": .dictionary([
                    "created_at": .string("2016-03-11T00:59:27.000Z"),
                    "body": .string("I'm so glad :)"),
                    "member": .dictionary([
                        "id": .string("fake-member-3"),
                        "nickname": .string("_jose_"),
                    ])
                ])
            ]),
            
            .dictionary([ // 4
                "id": .string("fake-convo-4"),
                "updated_at": .string("2016-03-11T00:22:27.000Z"),
                "member": .dictionary([
                    "id": .string("fake-member-4"),
                    "nickname": .string("meowtacos"),
                    "meta_line": .string("24GF kitten"),
                    "avatar": .dictionary([
                        "status": "sfw",
                        "variants": .dictionary(["medium": "https://flpics1.a.ssl.fastly.net/3215/3215981/0005221b-36b5-8f8d-693b-4d695b78c947_110.jpg"])
                    ])
                ]),
                "has_new_messages": .bool(false),
                "is_archived": .bool(false),
                "last_message": .dictionary([
                    "created_at": .string("2016-03-11T00:22:27.000Z"),
                    "body": .string("That's awesome!"),
                    "member": .dictionary([
                        "id": .string("fake-member-4"),
                        "nickname": .string("meowtacos"),
                    ])
                ])
            ]),
            
            
            
            .dictionary([ // 5
                "id": .string("fake-convo-5"),
                "updated_at": .string("2016-03-10T20:41:27.000Z"),
                "member": .dictionary([
                    "id": .string("fake-member-5"),
                    "nickname": .string("hashtagbrazil"),
                    "meta_line": .string("30M Kinkster"),
                    "avatar": .dictionary([
                        "status": "sfw",
                        "variants": .dictionary(["medium": "https://flpics1.a.ssl.fastly.net/4634/4634686/000524af-28b0-c73d-d811-d67ae1b93019_110.jpg"])
                        
                    ])
                ]),
                "has_new_messages": .bool(false),
                "is_archived": .bool(false),
                "last_message": .dictionary([
                    "created_at": .string("2016-03-10T20:41:27.000Z"),
                    "body": .string("I love that design"),
                    "member": .dictionary([
                        "id": .string("fake-member-5"),
                        "nickname": .string("hashtagbrazil"),
                    ])
                ])
            ]),
            
            .dictionary([ // 6
                "id": .string("fake-convo-6"),
                "updated_at": .string("2016-03-10T01:10:27.000Z"),
                "member": .dictionary([
                    "id": .string("fake-member-6"),
                    "nickname": .string("BobRegular"),
                    "meta_line": .string("95GF"),
                    "avatar": .dictionary([
                        "status": "sfw",
                        "variants": .dictionary(["medium": "https://flpics1.a.ssl.fastly.net/978/978206/0004df12-b6be-f3c3-0ec5-b34d357957a3_110.jpg"])
                    ])
                ]),
                "has_new_messages": .bool(false),
                "is_archived": .bool(false),
                "last_message": .dictionary([
                    "created_at": .string("2016-03-10T01:10:27.000Z"),
                    "body": .string("Yes"),
                    "member": .dictionary([
                        "id": .string("fake-member-6"),
                        "nickname": .string("BobRegular"),
                    ])
                ])
            ]),
            
            .dictionary([ // 7
                "id": .string("fake-convo-7"),
                "updated_at": .string("2016-03-08T01:22:27.000Z"),
                "member": .dictionary([
                    "id": .string("fake-member-7"),
                    "nickname": .string("GothRabbit"),
                    "meta_line": .string("24 Brat"),
                    "avatar": .dictionary([
                        "status": "sfw",
                        "variants": .dictionary(["medium": "https://flpics2.a.ssl.fastly.net/4625/4625410/00052da5-9c1a-df4c-f3bd-530f944def18_110.jpg"])
                    ])
                ]),
                "has_new_messages": .bool(false),
                "is_archived": .bool(false),
                "last_message": .dictionary([
                    "created_at": .string("2016-03-08T01:22:27.000Z"),
                    "body": .string("Best munch ever"),
                    "member": .dictionary([
                        "id": .string("fake-member-7"),
                        "nickname": .string("JohnBaku"),
                    ])
                ])
            ]),
            
            .dictionary([ // 8
                "id": .string("fake-convo-8"),
                "updated_at": .string("2016-03-02T01:22:27.000Z"),
                "member": .dictionary([
                    "id": .string("fake-member-8"),
                    "nickname": .string("BiggleWiggleWiggle"),
                    "meta_line": .string("19 CEO"),
                    "avatar": .dictionary([
                        "status": "sfw",
                        "variants": .dictionary(["medium": "https://flpics0.a.ssl.fastly.net/0/1/0004c0a3-562e-7bf7-780e-6903293438a0_110.jpg"])
                    ])
                ]),
                "has_new_messages": .bool(false),
                "is_archived": .bool(false),
                "last_message": .dictionary([
                    "created_at": .string("2016-03-02T01:22:27.000Z"),
                    "body": .string("See ya"),
                    "member": .dictionary([
                        "id": .string("fake-member-8"),
                        "nickname": .string("BiggleWiggleWiggle"),
                    ])
                ])
            ])
        ])
    }
}
