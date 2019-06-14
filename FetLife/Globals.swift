//
//  Globals.swift
//  FetLife
//
//  Created by Matt Conz on 8/27/18.
//  Copyright © 2018 BitLove Inc. All rights reserved.
//

import UIKit
import UserNotifications
import Alamofire
import AlamofireNetworkActivityIndicator
import p2_OAuth2

// MARK: - Global Variables
let REALM_SCHEMA_VERSION: UInt64 = 3 // Increment upon updating Realm object models between releases
let APP_VERSION: String = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
let BUILD_NUMBER: String = Bundle.main.infoDictionary!["CFBundleVersion"] as! String
let APP_IDENTIFIER: String = Bundle.main.infoDictionary!["CFBundleIdentifier"] as! String

let defaults = UserDefaults.standard // The UserDefaults object for storing preferences and persistent variables
let app = UIApplication.shared
let device = UIDevice.current

var latestNotifications: [String] = []
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
    let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
    let okAction = UIAlertAction(title: "OK", style: .default) { (action) -> Void in
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
    let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
    let okAction = UIAlertAction(title: "Ok", style: .default) { (action) -> Void in
        onOk?(action)
    }
    alertController.addAction(okAction)
    sender.present(alertController, animated: true, completion: nil)
}

/// Schedules a local notification to be sent.
///
/// - Parameters:
///   - title: Title of the notification
///   - body: Body of the notification
///   - category: Notification category
///   - userInfo: Additional information to be passed along with the notification
///   - uuid: A unique string value for each notification
///   - fireDate: The date when the notification should be sent
///   - threadID: (Available
func sendNotification(_ title: String, body: String, category: String, userInfo: Dictionary<AnyHashable, Any>?, uuid: String, fireDate: Date = Date(), threadID: String?) {
    if #available(iOS 10.0, *) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.categoryIdentifier = category
        if let userInfo = userInfo {
            content.userInfo = userInfo
        }
        content.sound = .default
        if let threadID = threadID {
            content.threadIdentifier = threadID
        }
        // schedule notification for one second in the future
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        // Create the request
        let request = UNNotificationRequest(identifier: uuid, content: content, trigger: trigger)
        // Schedule the request with the system.
        let notificationCenter = UNUserNotificationCenter.current()
        notificationCenter.add(request) { (error) in
            if error != nil {
                // Handle any errors.
                print("Error scheduling local notification: \(error!.localizedDescription)")
            } else {
                print("Successfully scheduled notification")
            }
        }
    } else {
        // Fallback on earlier versions
        let notification = UILocalNotification()
        notification.fireDate = fireDate
        notification.alertTitle = title
        notification.alertBody = body
        notification.category = category
        notification.userInfo = userInfo
        notification.soundName = UILocalNotificationDefaultSoundName
        app.presentLocalNotificationNow(notification)
    }
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
    /// The index of the `UITabBar` indicating which tab view should be shown.
    ///
    /// **Possible Values:**
    /// - `0` : Home
    /// - `1` : Messages
    /// - `2` : Notifications
    /// - `3` : Settings
    static var lastSelectedTab: Int { get { return defaults.integer(forKey: "optLastSelectedTab") }
        set(val) { defaults.set(val, forKey: "optLastSelectedTab") } }
    /// Boolean value indicating if the Safe For Work mode is enabled.
    static var sfwModeEnabled: Bool { get { return defaults.bool(forKey: "optSFWModeEnabled") }
        set(val) { defaults.set(val, forKey: "optSFWModeEnabled") } }
    /// Boolean value indicating if we should use the Android API for certain operations.
    static var useAndroidAPI: Bool { get { return defaults.bool(forKey: "optUseAndroidAPI") }
        set(val) { defaults.set(val, forKey: "optUseAndroidAPI") } }
    /// String value of current user (or empty string if no user is logged in).
    static var currentUserID: String { get { return defaults.string(forKey: "optCurrentUserID") ?? "" }
        set(val) { defaults.set(val, forKey: "optCurrentUserID") } }
    /// Boolean value indicating if the user has granted permission to display notifications.
    static var notificationPermissionsGranted: Bool { get { return defaults.bool(forKey: "optNotificationPermissionsGranted") }
        set(val) { defaults.set(val, forKey: "optNotificationPermissionsGranted") } }
    /// Date indicating the last time the conversation list was updated.
    static var lastUpdated: Date { get { return defaults.object(forKey: "optLastUpdatedConvos") as? Date ?? Date() }
        set(val) { defaults.set(val, forKey: "optLastUpdatedConvos") } }
    /// Authorization parameters as [String: String]
    static var authParams: OAuth2StringDict? { get { return defaults.dictionary(forKey: "optAuthParams") as? OAuth2StringDict }
        set(val) { defaults.set(val, forKey: "optAuthParams") } }
    /// App version
    static var appVersion: String { get { return defaults.string(forKey: "optAppVersion") ?? "" }
        set(val) { defaults.set(val, forKey: "optAppVersion") } }
}

// MARK: - Connectivity

/// Connectivity monitor
public struct Connectivity {
    private static let apiURLString: String = (Bundle.main.infoDictionary!["FETAPI_BASE_URL"] as! String).substring(from: String.Index(encodedOffset: 8)) // removes the "https://" from the url
    static let sharedInstance = NetworkReachabilityManager()!
    static let apiReachabilityMgr = NetworkReachabilityManager(host: apiURLString)!
    static var isConnected: Bool { get { return self.sharedInstance.isReachable } }
    static var canReachAPI: Bool { get { return self.apiReachabilityMgr.isReachable } }
}

/// Connectivity errors
public struct ConnectionError {
    static let HTTPNotFoundError = ConnectionError(title: "Page Not Found", message: "There doesn’t seem to be anything here.")
    static let NetworkError = ConnectionError(title: "Can’t Connect", message: "Unable to connect to Fetlife.")
    static let TimeoutError = ConnectionError(title: "Unable to Load", message: "We're having a problem loading this page. Either our servers are too slow, or this page isn't available in a mobile version.\n---------\nIf you were trying to see your activity feed, you need to enable \"Responsive Feed\" in your Account Settings in the Settings tab.")
    static let NotLoggedInError = ConnectionError(title: "Not Logged In", message: "Whoops! You need to log into the site to see this page.")
    static let LoggedOutError = ConnectionError(title: "Logged Out", message: "We're sorry to see you go. Would you like to log in again?")
    static let TLHomepageDisabledNonSupporter = ConnectionError(title: "Mobile View Disabled", message: "Unfortunately, it appears that the mobile home feed view is disabled. You need to be a FetLife supporter and enable \"Responsive Feed\" in your Account Settings in the Settings tab to view your Activity Feed in the app.")
    static let UnknownError = ConnectionError(title: "Unknown Error", message: "An unknown error occurred.")
    
    let title: String
    let message: String
    
    init(title: String, message: String) {
        self.title = title
        self.message = message
    }
    
    init(HTTPStatusCode: Int) {
        switch HTTPStatusCode {
        case 401:
            self.title = "401 Unauthorized"
            self.message = "This here is off limits. Did you ask permission (or log in) first?"
        case 403:
            self.title = "403 Forbidden"
            self.message = "We're saying our safe word (\"Baku's Beard\") now. You can't go here, even if you beg."
        case 408:
            self.title = "408 Request Timeout"
            self.message = "We didn't drink our coffee this morning and were too slow to respond to your request. Give us another chance?"
        case 500:
            self.title = "500 Server Error"
            self.message = "Shitaki, we encountered an error, but it is not your fault, it is FetLife that deserves the spanking. If you continue to get this error, please email us at support@fetlife.com."
        case 502:
            self.title = "502 Bad Gateway"
            self.message = "One of our servers is misbehaving. Please excuse us while we discipline it."
        case 503:
            self.title = "503 Service Unavailable"
            self.message = "@JohnBaku's beard uploaded too many selfies and crashed the server. We should be back up shortly."
        case 504:
            self.title = "504 Gateway Timeout"
            self.message = "Our servers are a little slow right now. Wait a few minutes and try again."
        default:
            self.title = "Unknown Server Error"
            self.message = "The server returned an HTTP \(HTTPStatusCode) response."
        }
    }
    
    static func ==(a: ConnectionError, b: ConnectionError) -> Bool {
        guard a.title == b.title && a.message == b.message else { return false }
        return true
    }
    static func !=(a: ConnectionError, b: ConnectionError) -> Bool {
        guard a.title != b.title || a.message != b.message else { return false }
        return true
    }
}

// MARK:- API

/// API errors
public enum APIError: Swift.Error {
    case NotAuthorized
    case Forbidden
    case ConnectionError
    case RateLimitExceeded
    case General(description: String)
}

// MARK:- RegEx

/// Regular expressions
public struct CommonRegexes {
    /// Matches `(2)`, `(0/5)`
    static let parentheticalNumbers = try! NSRegularExpression(pattern: "(\\([0-9]+\\) )|(\\([0-9]+/[0-9]+\\) )", options: .caseInsensitive)
    /// Matches profile URLs such as `https://fetlife.com/users/1`
    static let profileURL = try! NSRegularExpression(pattern: "(http(s)?:\\/\\/)?(www\\.)?fetlife.com\\/users\\/[0-9]+\\/?$", options: .caseInsensitive)
}

