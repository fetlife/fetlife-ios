//
//  SettingsViewController.swift
//  FetLife
//
//  Created by Matt Conz on 7/8/18.
//  Copyright © 2018 BitLove Inc. All rights reserved.
//

import UIKit
import SafariServices
import WebKit
import Turbolinks
import RealmSwift

class SettingsViewController: UITableViewController {

    @IBOutlet weak var logoutButton: UIBarButtonItem!
    @IBOutlet weak var cellUsername: UITableViewCell!
    @IBOutlet weak var cellViewProfile: UITableViewCell!
    @IBOutlet weak var cellAccountSettings: UITableViewCell!
    @IBOutlet var lblCurrentUser: UILabel!
    
    @IBOutlet weak var swchSFWMode: UISwitch!
    @IBOutlet weak var cellSFWMode: UITableViewCell!
    
    @IBOutlet weak var cellPrivacy: UITableViewCell!
    @IBOutlet weak var cellTerms: UITableViewCell!
    @IBOutlet weak var cellGuidelines: UITableViewCell!
    @IBOutlet weak var cellFAQs: UITableViewCell!
    @IBOutlet weak var cellContactUs: UITableViewCell!
    @IBOutlet weak var cellGitHub: UITableViewCell!
    @IBOutlet weak var cellOpenFetLife: UITableViewCell!
    
    @IBOutlet weak var lblAppVersion: UILabel!
    @IBOutlet weak var lblBuildNumber: UILabel!
    @IBOutlet weak var lblAppIdentifier: UILabel!
    
    @IBOutlet weak var cellPurgeRealm: UITableViewCell!
    @IBOutlet weak var swchUseAndroidAPI: UISwitch!

    let navTLBrowser = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "vcTLSettings") as! TLViewController
    var navCon = UINavigationController()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        // User Info
        if let me = API.sharedInstance.currentMember {
            lblCurrentUser.text = me.nickname
        } else {
            API.sharedInstance.getMe { (me, error) in
                if me != nil && error == nil {
                    self.lblCurrentUser.text = me?.nickname
                } else if error != nil && me == nil {
                    print("Error getting current user: \(error!.localizedDescription)")
                } else {
                    print("Error getting current user")
                }
            }
        }
        
        // Settings
        swchSFWMode.isOn = AppSettings.sfwModeEnabled
        swchUseAndroidAPI.isOn = AppSettings.useAndroidAPI
        
        // App Info
        lblAppVersion.text = APP_VERSION
        lblBuildNumber.text = BUILD_NUMBER
        lblAppIdentifier.text = APP_IDENTIFIER
        
        tableView.backgroundColor = .backgroundColor()
        configureCellActions()
        navCon = self.navigationController ?? UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "conversationsView") as! UINavigationController
        navTLBrowser.tab = .Settings
    }
    
    // MARK: - User Information
    
    func presentUserInBrowser() {
        let svc = SFSafariViewController(url: URL(string: API.sharedInstance.currentMember!.fetProfileURL)!)
        if #available(iOS 10.0, *) {
            svc.preferredBarTintColor = .backgroundColor()
            svc.preferredControlTintColor = .brickColor()
        }
        self.present(svc, animated: true, completion: nil)
    }
    
    // MARK: - Configuration
    
    func presentPrivacy() {
        navTLBrowser.url = URL(string: "https://fetlife.com/privacy")!
        navTLBrowser.navCon = navCon
        navCon.pushViewController(navTLBrowser, animated: true)
    }
    func presentTerms() {
        navTLBrowser.url = URL(string: "https://fetlife.com/legalese/tou")!
        navTLBrowser.baseURL = navTLBrowser.url
        navTLBrowser.navCon = navCon
        navCon.pushViewController(navTLBrowser, animated: true)
    }
    func presentGuidelines() {
        navTLBrowser.url = URL(string: "https://fetlife.com/guidelines")!
        navTLBrowser.baseURL = navTLBrowser.url
        navTLBrowser.navCon = navCon
        navCon.pushViewController(navTLBrowser, animated: true)
    }
    func presentFAQs() {
        navTLBrowser.url = URL(string: "https://fetlife.com/help")!
        navTLBrowser.baseURL = navTLBrowser.url
        navTLBrowser.navCon = navCon
        navCon.pushViewController(navTLBrowser, animated: true)
    }
    func presentContactUs() {
        navTLBrowser.url = URL(string: "https://fetlife.com/contact")!
        navTLBrowser.baseURL = navTLBrowser.url
        navTLBrowser.navCon = navCon
        navCon.pushViewController(navTLBrowser, animated: true)
    }
    func presentGitHub() {
        let svc = SFSafariViewController(url: URL(string: "https://github.com/fetlife/ios")!)
        if #available(iOS 10.0, *) {
            svc.preferredBarTintColor = .backgroundColor()
            svc.preferredControlTintColor = .brickColor()
        }
        self.present(svc, animated: true, completion: nil)
    }
    func presentFetLife() {
        let fetURL = URL(string: "https://fetlife.com")!
        UIApplication.shared.openURL(fetURL)
    }
    
    func configureCellActions() {
        if API.sharedInstance.currentMember == nil {
            API.sharedInstance.getMe { (me, error) in
                if error != nil && me == nil {
                    print("Error getting current user: \(error!.localizedDescription)")
                } else if error == nil && me == nil {
                    print("Error getting current user")
                }
            }
        }
        
        cellSFWMode.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(sfwModeTapped)))

        cellPrivacy.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(presentPrivacy)))
        cellTerms.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(presentTerms)))
        cellGuidelines.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(presentGuidelines)))
        cellFAQs.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(presentFAQs)))
        cellContactUs.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(presentContactUs)))
        cellGitHub.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(presentGitHub)))
        cellOpenFetLife.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(presentFetLife)))
        
        cellPurgeRealm.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(purgeRealmTapped)))
    }
    
    override func tableView(_ tableView: UITableView, shouldShowMenuForRowAt indexPath: IndexPath) -> Bool {
        guard indexPath.section == 2 && indexPath.row < 3 else { return false }
        return true
    }
    
    // MARK: - Settings
    
    @IBAction func sfwModeToggled(_ sender: UISwitch) {
        AppSettings.sfwModeEnabled = sender.isOn
    }
    @IBAction func logoutButtonPressed(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "Are you sure?", message: "Do you really want to log out of FetLife? We'll be very sad... 😢", preferredStyle: .actionSheet)
        let okAction = UIAlertAction(title: "Logout", style: .destructive) { (action) -> Void in
            API.sharedInstance.logout()
            if let window = UIApplication.shared.delegate?.window! {
                window.rootViewController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "loginView")
                self.dismiss(animated: false, completion: nil)
            }
        }
        let cancelAction = UIAlertAction(title: "Never mind", style: .cancel, handler: nil)
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func sfwModeTapped() {
        dlgOK(self, title: "Safe For Work Mode", message: "Turning this option on will blur images. To temporarily unblur images, double-tap on the image. Note: this setting may not take effect everywhere.", onOk: nil)
    }
    
    func purgeRealmTapped() {
        let ac = UIAlertController(title: "Purge Realm Database?", message: "Are you sure you want to purge the Realm database? This can cause undesired behavior and/or cause the app to be unusable.", preferredStyle: .actionSheet)
        let purgeAction = UIAlertAction(title: "Yes, purge", style: .destructive) { (action) in
            let realm = try! Realm()
            realm.deleteAll()
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        ac.addAction(purgeAction)
        ac.addAction(cancelAction)
        
        self.present(ac, animated: true, completion: nil)
    }
    @IBAction func useAndroidAPIToggled(_ sender: UISwitch) {
        AppSettings.useAndroidAPI = sender.isOn
    }

    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "segShowCurrentUser" {
            (segue.destination as! FriendProfileViewController).isMe = true
            (segue.destination as! FriendProfileViewController).friend = API.sharedInstance.currentMember!
        }
    }
}
