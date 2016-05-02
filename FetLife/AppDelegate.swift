//
//  AppDelegate.swift
//  FetLife
//
//  Created by Jose Cortinas on 2/2/16.
//  Copyright © 2016 BitLove Inc. All rights reserved.
//

import Foundation
import UIKit
import JWTDecode
import AlamofireNetworkActivityIndicator
import RealmSwift

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(app: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        NetworkActivityIndicatorManager.sharedManager.isEnabled = true
        
        setupAppearance(app)
        
        let config = Realm.Configuration(schemaVersion: 0)
        
        let info = NSBundle.mainBundle().infoDictionary!
        
        Realm.Configuration.defaultConfiguration = config
        
        let _ = try! Realm() // Get a realm instance early on to force migrations and configuration.
        
        let splitViewController = self.window!.rootViewController as! UISplitViewController
        let navigationController = splitViewController.viewControllers[splitViewController.viewControllers.count-1] as! UINavigationController
        navigationController.topViewController!.navigationItem.leftBarButtonItem = splitViewController.displayModeButtonItem()
        
        let storyboard = UIStoryboard.init(name: "Main", bundle: nil)
        
        if API.isAuthorized() {
            self.window!.rootViewController = storyboard.instantiateInitialViewController()
        } else {
            self.window!.rootViewController = storyboard.instantiateViewControllerWithIdentifier("loginView")
        }
        
        let hockeyAppID = info["HOCKEYAPP_ID"] as! String
        
        BITHockeyManager.sharedHockeyManager().configureWithIdentifier(hockeyAppID)
        // Do some additional configuration if needed here
        BITHockeyManager.sharedHockeyManager().startManager()
        BITHockeyManager.sharedHockeyManager().authenticator.authenticateInstallation()
        
        return true
    }
    
    func application(app: UIApplication, openURL url: NSURL, options: [String : AnyObject]) -> Bool {
        
        if "fetlifeapp" == url.scheme {
            print("Received redirect")
            API.sharedInstance.oauthSession.handleRedirectURL(url)
            return true
        }
        
        return false
    }
    
    
    func setupAppearance(app: UIApplication) {
        app.statusBarStyle = UIStatusBarStyle.LightContent
        
        UINavigationBar.appearance().tintColor = UIColor.brickColor()
        UINavigationBar.appearance().titleTextAttributes = [NSForegroundColorAttributeName: UIColor.brickColor()]
        UINavigationBar.appearance().barTintColor = UIColor.backgroundColor()
        UINavigationBar.appearance().shadowImage = UIImage()
        UINavigationBar.appearance().translucent = false
        
        UITableView.appearance().backgroundColor = UIColor.backgroundColor()
        UITableView.appearanceWhenContainedInInstancesOfClasses([ConversationsViewController.self]).separatorColor = UIColor.borderColor()
        UITableView.appearanceWhenContainedInInstancesOfClasses([MessagesTableViewController.self]).separatorColor = UIColor.backgroundColor()
        UITableViewCell.appearance().backgroundColor = UIColor.backgroundColor()
    }
    
    

    func applicationWillResignActive(app: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(app: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(app: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(app: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(app: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
}

