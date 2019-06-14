//
//  MainTabViewController.swift
//  FetLife
//
//  Created by Matt Conz on 8/14/18.
//  Copyright © 2018 BitLove Inc. All rights reserved.
//

import UIKit

enum TabIndex: Int {
    case None = -1
    case Home = 0
    case Requests = 1
    case Messages = 2
    case Notifications = 3
    case Settings = 4
    case More
}

class MainTabViewController: UITabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.tabBar.tintColor = UIColor.brickColor()
        setTab(TabIndex(rawValue: AppSettings.lastSelectedTab) ?? .Messages)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        API.sharedInstance.getRequests { (requests, err) in
            guard err == nil else { return }
            self.setBadge(requests.count, forTab: .Requests)
        }
        setTab(.Messages)
        setBadge(app.applicationIconBadgeNumber, forTab: .Messages)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        guard self.selectedIndex != NSNotFound else { return }
        AppSettings.lastSelectedTab = self.selectedIndex
    }
    
    func getViewController(_ index: TabIndex) -> UIViewController {
        switch index {
        case .Home:
            return viewControllers![TabIndex.Home.rawValue] as! HomeViewController
        case .Requests:
            return viewControllers![TabIndex.Requests.rawValue] as! RequestsViewController
        case .Messages:
            return (viewControllers![TabIndex.Messages.rawValue].children[0] as! UINavigationController).topViewController! as! ConversationsViewController
        case .Notifications:
            return viewControllers![TabIndex.Notifications.rawValue] as! NotificationViewController
        case .Settings:
            return viewControllers![TabIndex.Settings.rawValue] as? SettingsViewController ?? viewControllers![TabIndex.Settings.rawValue].children[0] as! SettingsViewController
        default:
            return viewControllers![TabIndex.Messages.rawValue].children[0] as! ConversationsViewController
        }
    }
    
    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard self.selectedIndex != NSNotFound else { return }
        AppSettings.lastSelectedTab = self.selectedIndex
    }
    
    func setTab(_ tab: TabIndex) {
        guard tab.rawValue != NSNotFound && tab != .None && tab != .More else { return }
        self.selectedIndex = tab.rawValue
        AppSettings.lastSelectedTab = tab.rawValue
    }
    
    func setBadge(_ badge: Int, forTab tab: TabIndex) {
        guard badge != 0 else { tabBar.items![tab.rawValue].badgeValue = nil; return }
        tabBar.items![tab.rawValue].badgeValue = String(badge)
    }
    
    func getBadge(_ tab: TabIndex) -> Int {
        return Int(tabBar.items![tab.rawValue].badgeValue ?? "0") ?? 0
    }
}
