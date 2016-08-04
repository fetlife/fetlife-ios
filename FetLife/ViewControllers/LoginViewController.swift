//
//  LoginViewController.swift
//  FetLife
//
//  Created by Jose Cortinas on 2/5/16.
//  Copyright © 2016 BitLove Inc. All rights reserved.
//

import UIKit
import p2_OAuth2
import OnePasswordExtension

class LoginViewController: UIViewController {
    
    // MARK: - Properties
    
    @IBOutlet weak var devilHeartImage: UIImageView!
    @IBOutlet weak var loginButton: UIButton!
    private weak var loginWebViewController:  UIViewController?
    private weak var loginWebView: UIWebView?
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func presentViewController(viewControllerToPresent: UIViewController, animated flag: Bool, completion: (() -> Void)?) {
        
        defer {
            super.presentViewController(viewControllerToPresent, animated: flag, completion: completion)
        }
        
        guard OnePasswordExtension.sharedExtension().isAppExtensionAvailable() else { return }
        guard let presentedNav = viewControllerToPresent as? UINavigationController,
            topViewController = presentedNav.topViewController,
            webview = presentedNav.topViewController?.view.subviews.first as? UIWebView else {
                return
        }
        
        loginWebViewController = topViewController
        loginWebView = webview
        
        let navBar = presentedNav.navigationBar
        let button = UIButton()
        let image = UIImage(named: "onepassword")?.imageWithRenderingMode(.AlwaysTemplate)
        button.setImage(image, forState: .Normal)
        button.tintColor = UIColor.brickColor()
        button.addTarget(self, action: #selector(LoginViewController.onePasswordTriggered), forControlEvents: .TouchUpInside)
        
        button.translatesAutoresizingMaskIntoConstraints = false
        navBar.addSubview(button)
        button.centerYAnchor.constraintEqualToAnchor(navBar.centerYAnchor).active = true
        button.leftAnchor.constraintEqualToAnchor(navBar.leftAnchor, constant: 10).active = true
    }
    
    // MARK: - Actions
    
    @IBAction func login(sender: UIButton) {
        sender.setTitle("Authorizing...", forState: .Normal)
        
        API.authorizeInContext(self,
                               onAuthorize: { parameters in self.didAuthorizeWith(parameters) },
                               onFailure: { error in self.didCancelOrFail(error) }
        )
    }
    
    func onePasswordTriggered(sender: UIButton) {
        guard let loginWebView = loginWebView, loginWebViewController = loginWebViewController else {
            return
        }
        
        OnePasswordExtension.sharedExtension().fillItemIntoWebView(loginWebView,
                                                                   forViewController: loginWebViewController,
                                                                   sender: sender,
                                                                   showOnlyLogins: false) { (success, error) in
                                                                    if !success {
                                                                        print("Failed to fill into webview: \(error)")
                                                                    }
        }
    }
    
    func didAuthorizeWith(parameters: OAuth2JSON) {
        if let window = UIApplication.sharedApplication().delegate?.window! {
            window.rootViewController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("chatSplitView")
        }
    }
    
    func didCancelOrFail(error: ErrorType?) {
        if let error = error {
            print("Failed to auth with error: \(error)")
        }
        
        loginButton.setTitle("Login with your FetLife account", forState: .Normal)
        loginButton.enabled = true
    }
}