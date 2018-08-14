//
//  TLNavViewController.swift
//  FetLife
//
//  Created by Matt Conz on 8/8/18.
//  Copyright © 2018 BitLove Inc. All rights reserved.
//

import UIKit
import Turbolinks
import WebKit

class TLViewController: UIViewController, SessionDelegate, WKScriptMessageHandler {
    
    var url: URL!
    var baseURL: URL!
    var navCon: UINavigationController!
    
    fileprivate let webViewProcessPool = WKProcessPool()

    fileprivate lazy var webViewConfiguration: WKWebViewConfiguration = {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(self, name: "fetlife-ios")
        configuration.processPool = self.webViewProcessPool
        configuration.applicationNameForUserAgent = "FetLife iOS App \(APP_VERSION)"
        return configuration
    }()
    
    fileprivate lazy var session: Session = {
        let session = Session(webViewConfiguration: self.webViewConfiguration)
        session.delegate = self
        return session
    }()
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print(url)
        presentVisitableForSession(session, url: url, action: .Replace)
    }

    fileprivate func presentVisitableForSession(_ session: Session, url: URL, action: Action = .Advance) {
        let visitable = VisitableViewController(url: url)
        
        if action == .Advance {
            navCon.pushViewController(visitable, animated: true)
        } else if action == .Replace {
            navCon.popViewController(animated: false)
            navCon.pushViewController(visitable, animated: false)
        }
        
        session.visit(visitable)
    }
    
    
    func session(_ session: Session, didProposeVisitToURL URL: Foundation.URL, withAction action: Action) {
        print("Proposed URL: \(URL)")
        print("Action: \(action)")
        presentVisitableForSession(session, url: URL, action: action)
    }
    
    func session(_ session: Session, didFailRequestForVisitable visitable: Visitable, withError error: NSError) {
        print("ERROR: %@", error)
        guard let vcVisitable = visitable as? TLVisitableViewController, let errorCode = ErrorCode(rawValue: error.code) else { return }
        
        switch errorCode {
        case .httpFailure:
            let statusCode = error.userInfo["statusCode"] as! Int
            switch statusCode {
            case 401:
                print("Authentication error")
            // need to authenticate
            case 404:
                print("URL not found")
                // file not found
                vcVisitable.presentError(.HTTPNotFoundError)
            default:
                print("Other error")
                vcVisitable.presentError(ConnectionError(HTTPStatusCode: statusCode))
            }
        case .networkFailure:
            print("Network error")
            vcVisitable.presentError(.NetworkError)
        }
    }
    
    func session(_ session: Session, openExternalURL URL: URL) {
        if !URL.host!.hasSuffix("fetlife.com") {
            dlgOKCancel(self, title: "Open external link?", message: "You are about to open an external link in Safari. Do you want to continue?", onOk: { (action) in
                UIApplication.shared.openURL(URL)
            }, onCancel: nil)
        } else {
            presentVisitableForSession(session, url: URL, action: .Advance)
        }
    }

    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if let message = message.body as? String {
            let alertController = UIAlertController(title: "FetLife", message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alertController, animated: true, completion: nil)
        }
    }
}
