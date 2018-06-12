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

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ app: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        NetworkActivityIndicatorManager.shared.isEnabled = true
        
        setupAppearance(app)
        
        let config = Realm.Configuration(schemaVersion: 0)
        
        Realm.Configuration.defaultConfiguration = config
        
        let _ = try! Realm() // Get a realm instance early on to force migrations and configuration.
        
        let splitViewController = self.window!.rootViewController as! UISplitViewController
        let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count-1] as! UINavigationController
        navigationController.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem
        
        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
        
        if API.isAuthorized() {
            self.window!.rootViewController = storyboard.instantiateInitialViewController()
        } else {
            self.window!.rootViewController = storyboard.instantiateViewController(withIdentifier: "loginView")
        }
        
        Fabric.with([Crashlytics.self])
        
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
        app.statusBarStyle = UIStatusBarStyle.lightContent
        
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

