//
//  AppDelegate.swift
//  FetLife
//
//  Created by Jose Cortinas on 2/2/16.
//  Copyright © 2016 BitLove Inc. All rights reserved.
//

import Foundation
import UIKit
import Fabric
import Crashlytics
import JWTDecode
import AlamofireNetworkActivityIndicator
import RealmSwift


// MARK: - Global Variables
let REALM_SCHEMA_VERSION: UInt64 = 1 // Increment upon updating Realm object models between releases
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

// MARK: - User Default Variables
// Setting up user defaults as variables simplifies the process of reading and writing to the UserDefaults store.

/// The index of the UISegmentedControl indicating which mailbox should be shown.
///
/// **Possible Values:**
/// - `0` : Inbox
/// - `1` : Archived Mail
var optLastSelectedMailbox: Int { get { return defaults.integer(forKey: "optLastSelectedMailbox") } set(val) { defaults.set(val, forKey: "optLastSelectedMailbox") } }

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
        } else {
            self.window!.rootViewController = storyboard.instantiateViewController(withIdentifier: "loginView")
        }
        
        app.registerUserNotificationSettings(UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil))
        
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
    }
    
    func applicationDidBecomeActive(_ app: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }
    
    func applicationWillTerminate(_ app: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

