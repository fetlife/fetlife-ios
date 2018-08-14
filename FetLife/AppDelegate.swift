//
//  AppDelegate.swift
//  FetLife
//
//  Created by Jose Cortinas on 2/2/16.
//  Copyright © 2016 BitLove Inc. All rights reserved.
//

import Foundation
import UserNotifications
import UIKit
import Fabric
import Crashlytics
import JWTDecode
import Alamofire
import AlamofireNetworkActivityIndicator
import RealmSwift


// MARK: - Global Variables
let REALM_SCHEMA_VERSION: UInt64 = 2 // Increment upon updating Realm object models between releases
let APP_VERSION: String = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
let BUILD_NUMBER: String = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
let defaults = UserDefaults.standard // The UserDefaults object for storing preferences and persistent variables


// MARK: - Globally Shared Functions

/// Creates an Ok/Cancel message box with optional completion handlers.
///
/// - Parameters:
///   - sender: UIViewController presenting the dialog
///   - title: Title of the dialog box
///   - message: Main body of the dialog box
///   - onOk: Optional completion handler for when "Ok" is pressed
///   - onCancel: Optional completion handler for when "Cancel" is pressed
func dlgOKCancel(_ sender: UIViewController, title: String, message: String, onOk: ((UIAlertAction) -> Void)?, onCancel: ((UIAlertAction) -> Void)?) {
    let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
    let okAction = UIAlertAction(title: "Ok", style: .default) { (action) -> Void in
        onOk?(action)
    }
    let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) -> Void in
        onCancel?(action)
    }
    alertController.addAction(okAction)
    alertController.addAction(cancelAction)
    sender.present(alertController, animated: true, completion: nil)
}

/// Creates a message box with optional completion handlers.
///
/// - Parameters:
///   - sender: UIViewController presenting the dialog
///   - title: Title of the dialog box
///   - message: Main body of the dialog box
///   - onOk: Optional completion handler for when "Ok" is pressed
func dlgOK(_ sender: UIViewController, title: String, message: String, onOk: ((UIAlertAction) -> Void)?) {
    let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
    let okAction = UIAlertAction(title: "Ok", style: .default) { (action) -> Void in
        onOk?(action)
    }
    alertController.addAction(okAction)
    sender.present(alertController, animated: true, completion: nil)
}

// MARK: - User Default Variables
// Setting up user defaults as variables simplifies the process of reading and writing to the UserDefaults store.

/// Global user defaults settings, preserved across launches
public struct AppSettings {
    /// The index of the `UISegmentedControl` indicating which mailbox should be shown.
    ///
    /// **Possible Values:**
    /// - `0` : Inbox
    /// - `1` : Archived Mail
    static var lastSelectedMailbox: Int { get { return defaults.integer(forKey: "optLastSelectedMailbox") }
        set(val) { defaults.set(val, forKey: "optLastSelectedMailbox") } }
    /// Boolean value indicating if the Safe For Work mode is enabled.
    static var sfwModeEnabled: Bool { get { return defaults.bool(forKey: "optSFWModeEnabled") }
        set(val) { defaults.set(val, forKey: "optSFWModeEnabled") } }
    /// String value of current user (or empty string if no user is logged in)
    static var currentUserID: String { get { return defaults.string(forKey: "optCurrentUserID")! }
        set(val) { defaults.set(val, forKey: "optCurrentUserID") } }
    /// Boolean value indicating if the user has granted permission to display notifications
    static var notificationPermissionsGranted: Bool { get { return defaults.bool(forKey: "optNotificationPermissionsGranted") }
        set(val) { defaults.set(val, forKey: "optNotificationPermissionsGranted") } }
    /// Date indicating the last time the conversation list was updated
    static var lastUpdated: Date { get { return defaults.object(forKey: "optLastUpdatedConvos") as? Date ?? Date() }
        set(val) { defaults.set(val, forKey: "optLastUpdatedConvos") } }
}

/// Connectivity monitor
public struct Connectivity {
    private static let apiURLString: String = (Bundle.main.infoDictionary!["FETAPI_BASE_URL"] as! String).substring(from: String.Index(encodedOffset: 8)) // removes the "https://" from the url
    static let sharedInstance = NetworkReachabilityManager()!
    static let apiReachabilityMgr = NetworkReachabilityManager(host: apiURLString)!
    static var isConnected: Bool { get { return self.sharedInstance.isReachable } }
    static var canReachAPI: Bool { get { return self.apiReachabilityMgr.isReachable } }
}

// MARK: -
@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    var window: UIWindow?
    
    func application(_ app: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        NetworkActivityIndicatorManager.shared.isEnabled = true
        setupAppearance(app)
        
        Fabric.with([Crashlytics.self])
        
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
        
        let splitViewController = self.window!.rootViewController as! UISplitViewController
        let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count-1] as! UINavigationController
        navigationController.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
        
        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
        
        if API.isAuthorized() {
            self.window!.rootViewController = storyboard.instantiateInitialViewController()
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
        
        // Set the minimum time between background updates (30 seconds)
        // NOTE: - The amount of time between background updates can and will vary wildly depending on a number of factors,
        // including connection strength, connnection type, battery level, user settings, frequency of new data (how often
        // the user gets new messages), and many other variables. This is determined entirely by iOS and cannot be explicitly
        // controlled by the app.
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)
        
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
    
    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        guard API.isAuthorized() else { return }
        checkForNewMessages(completionHandler)
    }
    
    func checkForNewMessages(_ completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        print("checking for new messages")
        guard API.isAuthorized() else {
            completionHandler(.failed)
            return
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
                return
            }
            // FIXME: - If there is an existing notification, opening the app will show another notification once conversations are updated
            let unreadConversations: [Conversation] = conversations.filter({ (c: Conversation) -> Bool in
                return c.hasNewMessages
            }).sorted(by: { (a, b) -> Bool in // sort by most recent conversation first
                return a.lastMessageCreated < b.lastMessageCreated
            })
            
            let df = DateFormatter()
            df.dateStyle = .long
            df.timeStyle = .long
            
            // if there are no unread conversations remove badge and exit function
            let unreadConversationCount = unreadConversations.count
            guard unreadConversationCount != 0 else {
                UIApplication.shared.applicationIconBadgeNumber = unreadConversationCount
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
                    UIApplication.shared.applicationIconBadgeNumber = unreadConversationCount
                    return
                }
                
                // if the latest message in Realm doesn't match the latest message indicated in the conversation,
                // or if the number of unread conversations doesn't match the badge number, send a notification
                if UIApplication.shared.applicationIconBadgeNumber != unreadConversationCount || lastMessage.createdAt != convo.lastMessageCreated {
                    completionHandler(.newData)
                    if unreadConversationCount != 0 {
                        if #available(iOS 10.0, *) {
                            let content = UNMutableNotificationContent()
                            content.title = "New message from \(user)"
                            content.body = convo.lastMessageBody
                            content.categoryIdentifier = "newMessage"
                            content.userInfo = [
                                "conversationId": convo.id,
                                "messageId": messages[0].id,
                                "user": user,
                                "userId": convo.member!.id,
                                "createdAt": df.string(from: convo.lastMessageCreated)
                            ]
                            var dc = DateComponents()
                            dc.calendar = Calendar.current
                            // schedule notification for 10 seconds from now
                            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 10, repeats: false)
                            // Create the request
                            let uuidString = "\(convo.id)-\(messages[0].id)"
                            let request = UNNotificationRequest(identifier: uuidString, content: content, trigger: trigger)
                            // Schedule the request with the system.
                            let notificationCenter = UNUserNotificationCenter.current()
                            notificationCenter.add(request) { (error) in
                                if error != nil {
                                    // Handle any errors.
                                    print("Error scheduling local notification: \(error!.localizedDescription)")
                                }
                            }
                        } else {
                            // Fallback on earlier versions
                            let notification = UILocalNotification()
                            notification.fireDate = Date(timeIntervalSinceNow: 10)
                            let user = convo.member!.nickname
                            notification.alertTitle = "New message from \(user)"
                            notification.alertBody = convo.lastMessageBody
                            notification.category = "newMessage"
                            notification.userInfo = [
                                "conversationId": convo.id,
                                "messageId": messages[0].id,
                                "user": user,
                                "userId": convo.member!.id,
                                "createdAt": df.string(from: convo.lastMessageCreated)
                            ]
                            notification.soundName = UILocalNotificationDefaultSoundName
                            UIApplication.shared.scheduleLocalNotification(notification)
                        }
                    }
                } else {
                    completionHandler(.noData)
                }
                UIApplication.shared.applicationIconBadgeNumber = unreadConversationCount
            })
        }
    }
    
    func applicationWillEnterForeground(_ app: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }
    
    func applicationDidBecomeActive(_ app: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ app: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

@available(iOS 10.0, *)
extension AppDelegate: UNUserNotificationCenterDelegate {
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print(response.notification.request.content.userInfo)
        let content = response.notification.request.content
        if content.categoryIdentifier == "newMessage" {
            // FIXME: - Tapping on the notification will present message view from current view controller instead of from conversation view controller
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
        }
        completionHandler()
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .badge, .sound])
    }
}

