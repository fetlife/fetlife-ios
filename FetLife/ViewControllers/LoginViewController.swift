//
//  LoginViewController.swift
//  FetLife
//
//  Created by Jose Cortinas on 2/5/16.
//  Copyright © 2016 BitLove Inc. All rights reserved.
//

import UIKit
import p2_OAuth2

class LoginViewController: UIViewController {
    
    // MARK: - Properties
    
    @IBOutlet weak var devilHeartImage: UIImageView!
    @IBOutlet weak var loginButton: UIButton!
    
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
        
        API.authorizeInContext(self,
            onAuthorize: { (parameters, error) -> Void in
                if let params = parameters {
                    self.didAuthorizeWith(params)
                }
                if let err = error {
                    self.didCancelOrFail(err)
                }
            }
        )
    }
    
    func didAuthorizeWith(_ parameters: OAuth2JSON) {
        if let window = UIApplication.shared.delegate?.window! {
            window.rootViewController = UIStoryboard.init(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "chatSplitView")
            self.dismiss(animated: false, completion: nil)
        }
    }
    
    func didCancelOrFail(_ error: Error?) {
        if let error = error {
            print("Failed to auth with error: \(error)")
        }
        
        loginButton.setTitle("Login to Fetlife", for: UIControlState())
        loginButton.isEnabled = true
    }
}
