//
//  LoginViewController.swift
//  FetLife
//
//  Created by Jose Cortinas on 2/5/16.
//  Copyright © 2016 BitLove Inc. All rights reserved.
//

import UIKit
import p2_OAuth2
import WebKit
import SafariServices

class LoginViewController: UIViewController {
    
    // MARK: - Properties
    
    @IBOutlet weak var devilHeartImage: UIImageView!
    @IBOutlet weak var loginButton: UIButton!
    
    lazy var webViewConfiguration: WKWebViewConfiguration = {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(self, name: "fetlife-ios")
        configuration.processPool = API.sharedInstance.webViewProcessPool
        configuration.applicationNameForUserAgent = "FetLife iOS App \(APP_VERSION)"
        return configuration
    }()
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Actions
    
    @IBAction func login(_ sender: UIButton) {
        sender.setTitle("Authorizing...", for: UIControlState())
        
        API.sharedInstance.oauthSession.tryToObtainAccessTokenIfNeeded(params: AppSettings.authParams) { (authResults) in
            if let authResults = authResults {
                self.didAuthorizeWith(authResults)
            } else {
                API.authorizeInContext(self, onAuthorize: { (parameters, error) -> Void in
                    if let params = parameters {
                        self.didAuthorizeWith(params)
                    }
                    if let err = error {
                        self.didCancelOrFail(err)
                    }
                })
            }
        }
    }
    
    func didAuthorizeWith(_ parameters: OAuth2JSON) {
        print("Auth parameters: \(parameters)")
        AppSettings.authParams = parameters as? OAuth2StringDict
        if let window = UIApplication.shared.delegate?.window! {
            window.rootViewController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "vcMain")
            self.dismiss(animated: false, completion: nil)
        }
        performSegue(withIdentifier: "segShowAuthController", sender: self)
        API.sharedInstance.getMe { (me, error) in
            if me != nil && error == nil {
                AppSettings.currentUserID = me!.id
                API.sharedInstance.currentMember = me
            } else if error != nil && me == nil {
                print("Error getting current user: \(String(describing: error))")
                AppSettings.currentUserID = ""
                API.sharedInstance.currentMember = nil
            } else {
                print("Error getting current user")
                AppSettings.currentUserID = ""
                API.sharedInstance.currentMember = nil
            }
        }
    }
    
    func didCancelOrFail(_ error: Error?) {
        if let error = error {
            print("Failed to auth with error: \(error)")
        }
        Dispatch.asyncOnMainQueue {
            self.loginButton.setTitle("Login to Fetlife", for: UIControlState())
            self.loginButton.isEnabled = true
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "segShowAuthController" {
            let authCon = segue.destination as! TLAuthViewController
            authCon.delegate = self
            authCon.url = URL(string: "https://fetlife.com/users/sign_in")!
            authCon.webViewConfiguration = self.webViewConfiguration
            authCon.navigationItem.title = "Login"
        }
    }
    
    @IBAction func doLogout(_ sender: AnyObject) {
        print("opening logout view")
        let safariView = SFSafariViewController(url: URL(string: "https://fetlife.com/users/sign_out")!)
        self.present(safariView, animated: true, completion: nil)
    }
}

extension LoginViewController: TLAuthControllerDelegate {
    func authenticationControllerDidAuthenticate(_ authenticationController: TLAuthViewController) {
        if let window = UIApplication.shared.delegate?.window! {
            window.rootViewController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "vcMain")
            self.dismiss(animated: false, completion: nil)
        }
    }
    
    func authenticationControllerDidCancel(_ authenticationController: TLAuthViewController) {
        if let window = UIApplication.shared.delegate?.window! {
            window.rootViewController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "vcMain")
            self.dismiss(animated: false, completion: nil)
        }
    }
}

extension LoginViewController: WKScriptMessageHandler {
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if let message = message.body as? String {
            let alertController = UIAlertController(title: "FetLife", message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alertController, animated: true, completion: nil)
        }
    }
}
