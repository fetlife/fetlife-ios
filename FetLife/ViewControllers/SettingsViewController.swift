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

class SettingsViewController: UITableViewController {

    @IBOutlet weak var cellUsername: UITableViewCell!
    @IBOutlet weak var lblCurrentUser: UILabel!
    @IBOutlet weak var lblAppVersion: UILabel!
    @IBOutlet weak var lblBuildNumber: UILabel!
    
    @IBOutlet weak var swchSFWMode: UISwitch!
    @IBOutlet weak var cellSFWMode: UITableViewCell!
    
    @IBOutlet weak var cellPrivacy: UITableViewCell!
    @IBOutlet weak var cellTerms: UITableViewCell!
    @IBOutlet weak var cellGuidelines: UITableViewCell!
    @IBOutlet weak var cellFAQs: UITableViewCell!
    @IBOutlet weak var cellContactUs: UITableViewCell!
    @IBOutlet weak var cellGitHub: UITableViewCell!
    @IBOutlet weak var cellOpenFetLife: UITableViewCell!
    
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
        
        // App Info
        lblAppVersion.text = APP_VERSION
        lblBuildNumber.text = BUILD_NUMBER
        
        tableView.backgroundColor = .backgroundColor()
        configureCellActions()
        navCon = self.navigationController ?? UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "conversationsView") as! UINavigationController
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

    }
    
    // MARK: - Settings
    
    @IBAction func sfwModeToggled(_ sender: UISwitch) {
        AppSettings.sfwModeEnabled = sender.isOn
    }
    
    func sfwModeTapped() {
        dlgOK(self, title: "Safe For Work Mode", message: "Turning this option on will blur all images. To temporarily unblur images, double-tap on the image.", onOk: nil)
    }

    // MARK: - Navigation

    @IBAction func closeButtonPressed(_ sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if segue.identifier == "segShowCurrentUser" {
            (segue.destination as! FriendProfileViewController).isMe = true
            (segue.destination as! FriendProfileViewController).friend = API.sharedInstance.currentMember!
        }
    }

}
