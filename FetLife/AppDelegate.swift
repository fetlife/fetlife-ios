//
//  AppDelegate.swift
//  FetLife
//
//  Created by Jose Cortinas on 2/2/16.
//  Copyright © 2016 BitLove Inc. All rights reserved.
//

import UserNotifications
import UIKit
import Fabric
import Crashlytics
import JWTDecode
import Alamofire
import AlamofireImage
import AlamofireNetworkActivityIndicator
import RealmSwift


// MARK: -
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ app: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        Fabric.with([Crashlytics.self])
        NetworkActivityIndicatorManager.shared.isEnabled = true
        
        setupAppearance(app)
        
        let config = Realm.Configuration(
            // Set the new schema version. This must be greater than the previously used
            // version (if you've never set a schema version before, the version is 0).
            schemaVersion: REALM_SCHEMA_VERSION,
            
            // Set the block which will be called automatically when opening a Realm with
            // a schema version lower than the one set above
            migrationBlock: { migration, oldSchemaVersion in
                print("Old schema version: \(oldSchemaVersion)")
                print("New schema version: \(REALM_SCHEMA_VERSION)")
                if (oldSchemaVersion < REALM_SCHEMA_VERSION) {
                    print("Performing migration...")
                    // Nothing to do!
                    // Realm will automatically detect new properties and removed properties
                    // And will update the schema on disk automatically
                }
        })
        Realm.Configuration.defaultConfiguration = config
        do {
            let realm = try Realm() // Get a realm instance early on to force migrations and configuration.
            realm.autorefresh = true
        } catch let e {
            print("Error initializing Realm instance! \(e.localizedDescription)")
            print("This application will now exit.")
            fatalError(e.localizedDescription)
        }

        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
        
        let splitViewController = storyboard.instantiateViewController(withIdentifier: "chatSplitView") as! UISplitViewController
        let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count-1] as! UINavigationController
        navigationController.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
        if API.isAuthorized() {
            self.window!.rootViewController = storyboard.instantiateViewController(withIdentifier: "vcMain")
            API.sharedInstance.getMe { (me, error) in
                if me != nil && error == nil {
                    AppSettings.currentUserID = me!.id
                } else if error != nil && me == nil {
                    print("Error getting current user: \(error!.localizedDescription)")
                    AppSettings.currentUserID = ""
                } else {
                    print("Error getting current user")
                    AppSettings.currentUserID = ""
                }
            }
            print("Token expires: \(API.sharedInstance.oauthSession.accessTokenExpiry?.description(with: Locale.current) ?? "nil")")
        } else {
            self.window!.rootViewController = storyboard.instantiateViewController(withIdentifier: "loginView")
        }
        
        if #available(iOS 10.0, *) {
            let center = UNUserNotificationCenter.current()
            center.requestAuthorization(options: [.alert, .sound, .badge]) { (granted, err) in
                if err != nil {
                    print("Error requesting notification permissions: \(err!.localizedDescription)")
                    AppSettings.notificationPermissionsGranted = granted
                } else {
                    AppSettings.notificationPermissionsGranted = granted
                }
            }
        } else {
            // Fallback on earlier versions
            app.registerUserNotificationSettings(UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil))
            if app.currentUserNotificationSettings!.types == .init(rawValue: 0) {
                AppSettings.notificationPermissionsGranted = false
            } else {
                AppSettings.notificationPermissionsGranted = true
            }
        }
        
        // Set the minimum time between background updates (varies by device and system)
        // NOTE: - The amount of time between background updates can and will vary wildly depending on a number of factors,
        // including connection strength, connnection type, battery level, user settings, frequency of new data (how often
        // the user gets new messages), and many other variables. This is determined entirely by iOS and cannot be explicitly
        // controlled by the app.
        app.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        
        if APP_IDENTIFIER != "co.bitlove.opensource.FetLife" && AppSettings.appVersion != APP_VERSION {
            dlgOK(self.window!.rootViewController!, title: "Non-standard app version detected!", message: "You appear to be running a version of the FetLife app that has been modified from the official version on GitHub. If you have compiled the app yourself, are testing a beta version of the app, or know the person who installed the app, you can ignore this message.\n\nOriginal App ID: co.bitlove.opensource.FetLife\nYour App ID: \(APP_IDENTIFIER)", onOk: nil)
        }
        AppSettings.appVersion = APP_VERSION
        
        return true
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any]) -> Bool {
        
        if "fetlifeapp" == url.scheme {
            print("Received redirect: \(url)")
            API.sharedInstance.oauthSession.handleRedirectURL(url)
            return true
        }
        
        return false
    }
    
    
    func setupAppearance(_ app: UIApplication) {
        
        UINavigationBar.appearance().tintColor = UIColor.brickColor()
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName: UIColor.brickColor()]
        UINavigationBar.appearance().barTintColor = UIColor.backgroundColor()
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().isTranslucent = false
        
        UITableView.appearance().backgroundColor = UIColor.backgroundColor()
        UITableView.appearance(whenContainedInInstancesOf: [ConversationsViewController.self]).separatorColor = UIColor.borderColor()
        UITableView.appearance(whenContainedInInstancesOf: [MessagesTableViewController.self]).separatorColor = UIColor.backgroundColor()
        UITableViewCell.appearance().backgroundColor = UIColor.backgroundColor()
    }
    
    
    func applicationWillResignActive(_ app: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }
    
    func applicationDidEnterBackground(_ app: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }
    
    func applicationWillEnterForeground(_ app: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        if app.currentUserNotificationSettings!.types == .init(rawValue: 0) {
            AppSettings.notificationPermissionsGranted = false
        } else {
            AppSettings.notificationPermissionsGranted = true
        }
    }
    
    func applicationDidBecomeActive(_ app: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ app: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        guard API.isAuthorized() else { completionHandler(.noData); return }
        AppSettings.lastUpdated = Date()
        checkForNotifications(completionHandler)
    }
    
    func checkForNotifications(_ completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("checking for updates")
        guard API.isAuthorized() else {
            print("Not authorized! Token expiration: \(API.sharedInstance.oauthSession.accessTokenExpiry?.description(with: Locale.current) ?? "nil")")
            if #available(iOS 10.0, *) {
                UNUserNotificationCenter.current().getDeliveredNotifications { (notifications) in
                    var deauthNotificationSent = false
                    for n in notifications {
                        if n.request.identifier == "authError" {
                            deauthNotificationSent = true
                            break
                        }
                    }
                    if !deauthNotificationSent {
                        sendNotification("Deauthorized", body: "You have been deauthorized or your token has expired. Token expiration: \(API.sharedInstance.oauthSession.accessTokenExpiry?.description(with: Locale.current) ?? "nil")\nCurrent user id: \(AppSettings.currentUserID)", category: "authError", userInfo: nil, uuid: "authError", fireDate: Date(), threadID: nil)
                    }
                }
            }
            completionHandler(.noData)
            return
        }
        
        let watchdogTimer = Timer.scheduledTimer(timeInterval: 29, target: self, selector: #selector(notificationCheckExpired(_:)), userInfo: completionHandler, repeats: false)
        
        let df = DateFormatter()
        df.dateStyle = .long
        df.timeStyle = .long
        
        API.sharedInstance.getRequests { (requests, err) in
            guard err == nil else {
                print("Error getting requests: \(err!.localizedDescription)")
                return
            }
            for r in requests {
                let title = "New friend request!"
                let body = "You have a new friend request from \(r.member!.nickname)"
                let category = "newRequest"
                let userInfo = [
                    "requestId": r.id,
                    "user": r.member!.nickname,
                    "userId": r.member!.id,
                    "createdAt": df.string(from: r.createdAt)
                ]
                let uuidString = "\(r.id)"
                let fireDate = r.createdAt
                let threadID = "newRequest"
                sendNotification(title, body: body, category: category, userInfo: userInfo, uuid: uuidString, fireDate: fireDate, threadID: threadID)
            }
        }
        
        var conversations: Results<Conversation> {
            get {
                return try! Realm()
                    .objects(Conversation.self)
                    .filter("isArchived == false")
                    .sorted(byKeyPath: "lastMessageCreated", ascending: false)
            }
        }
        API.sharedInstance.loadConversations { (err) in
            guard err == nil else {
                print("Error loading conversations: \(err!.localizedDescription)")
                completionHandler(.failed)
                watchdogTimer.invalidate()
                return
            }
            // FIXME: - If there is an existing notification, opening the app will show another notification once conversations are updated
            let unreadConversations: [Conversation] = conversations.filter({ (c: Conversation) -> Bool in
                return c.hasNewMessages
            }).sorted(by: { (a, b) -> Bool in // sort by most recent conversation first
                return a.lastMessageCreated < b.lastMessageCreated
            })
            
            // if there are no unread conversations remove badge and exit function
            let unreadConversationCount = unreadConversations.count
            guard unreadConversationCount != 0 else {
                app.applicationIconBadgeNumber = unreadConversationCount
                completionHandler(.noData)
                watchdogTimer.invalidate()
                return
            }
            
            let convo = unreadConversations[0] // get the most recently updated unread conversation
            let user = convo.member!.nickname
            let messages: Results<Message> = try! Realm()
                .objects(Message.self)
                .filter("conversationId == \"\(convo.id)\"")
                .sorted(byKeyPath: "createdAt", ascending: false)
            let lastMessage = messages[0] // get latest message in Realm database
            
            // update the Realm database with the latest messages
            API.sharedInstance.loadMessages(convo.id, parameters: [:], completion: { (err2) in
                guard err2 == nil else {
                    print("Error loading messages: \(err2!.localizedDescription)")
                    app.applicationIconBadgeNumber = unreadConversationCount
                    completionHandler(.failed)
                    watchdogTimer.invalidate()
                    return
                }
                
                // if the latest message in Realm doesn't match the latest message indicated in the conversation,
                // or if the number of unread conversations doesn't match the badge number, send a notification
                if app.applicationIconBadgeNumber != unreadConversationCount || lastMessage.createdAt != convo.lastMessageCreated {
                    completionHandler(.newData)
                    if unreadConversationCount != 0 {
                        let title = "New message from \(user)"
                        let body = convo.lastMessageBody
                        let category = "newMessage"
                        let userInfo = [
                            "conversationId": convo.id,
                            "messageId": messages[0].id,
                            "user": user,
                            "userId": convo.member!.id,
                            "createdAt": df.string(from: convo.lastMessageCreated)
                        ]
                        let uuidString = "\(convo.id)-\(messages[0].id)"
                        let fireDate = convo.lastMessageCreated
                        let threadID = "\(category)-\(user)"
                        
                        sendNotification(title, body: body, category: category, userInfo: userInfo, uuid: uuidString, fireDate: fireDate, threadID: threadID)
                    }
                } else {
                    completionHandler(.noData)
                    watchdogTimer.invalidate()
                }
                app.applicationIconBadgeNumber = unreadConversationCount
            })
        }
    }
    
    func notificationCheckExpired(_ completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        completionHandler(.failed)
    }
    
}

@available(iOS 10.0, *)
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let content = response.notification.request.content
        switch content.categoryIdentifier {
        case "newMessage":
            let convoId = content.userInfo["conversationId"] as! String
            let conversation: Conversation = try! Realm().objects(Conversation.self).filter("id == \"\(convoId)\"").first!
            let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
            let controller: MessagesTableViewController = storyboard.instantiateViewController(withIdentifier: "vcMessagesTable") as! MessagesTableViewController
            controller.conversation = conversation
            controller.navigationItem.title = "\(conversation.member!.nickname) ‣"
            let splitViewController = self.window!.rootViewController as! UISplitViewController
            controller.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
            controller.navigationItem.leftItemsSupplementBackButton = true
            controller.conversationId = conversation.id
            let navCon = UINavigationController(rootViewController: controller)
            self.window!.rootViewController!.present(navCon, animated: true, completion: nil)
        case "newRequest":
            (self.window!.rootViewController! as! MainTabViewController).setTab(.Requests)
        default:
        }
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
}

