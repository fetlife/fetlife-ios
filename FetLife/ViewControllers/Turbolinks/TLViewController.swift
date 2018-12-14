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
import MessageUI

class TLViewController: UIViewController {
    
    var url: URL!
    var baseURL: URL!
    var tab: TabIndex!
    var navCon: UINavigationController!
    var mainTabView: MainTabViewController = MainTabViewController()

    lazy var webViewConfiguration: WKWebViewConfiguration = {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(self, name: "fetlife-ios")
        configuration.processPool = API.sharedInstance.webViewProcessPool
        configuration.applicationNameForUserAgent = "FetLife iOS App \(APP_VERSION)"
        return configuration
    }()
    
    lazy var currentSession: Session = {
        let session = Session(webViewConfiguration: self.webViewConfiguration)
        session.delegate = self
        return session
    }()
    

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        mainTabView = self.tabBarController as! MainTabViewController
    }
    
    override func viewDidAppear(_ animated: Bool) {
        presentVisitableForSession(currentSession, url: url, action: .Replace)
    }

    func presentVisitableForSession(_ session: Session, url: URL, action: Action = .Advance) {
        let visitable = TLVisitableViewController(url: url)
        visitable.webViewConfiguration = webViewConfiguration
        visitable.currentSession = currentSession
        if action == .Advance {
            navCon.pushViewController(visitable, animated: true)
        } else if action == .Replace {
            navCon.popViewController(animated: false)
            navCon.pushViewController(visitable, animated: false)
        }
        
        currentSession.visit(visitable)
    }
    
    func checkForRedirects(_ session: Session, forTab tab: TabIndex, forURL url: URL, withAction action: Action) {
        
        // remove anchors for the purpose of redirects
        var trimmedURLPath = url.path
        if let index = trimmedURLPath.lastIndex(of: "#") {
            trimmedURLPath = trimmedURLPath.substring(to: index)
        }
        var lastPathComponent = url.lastPathComponent
        if let index = lastPathComponent.lastIndex(of: "#") {
            lastPathComponent = lastPathComponent.substring(to: index)
        }
        
        switch lastPathComponent {
        case "home", "/":
            if tab == .Home {
                presentVisitableForSession(session, url: url, action: .Restore)
            } else {
                mainTabView.setTab(.Home)
                (mainTabView.getViewController(.Home) as! HomeViewController).loadBaseURL()
            }
        case "requests":
            if tab == .Requests {
                presentVisitableForSession(session, url: url, action: .Restore)
            } else {
                mainTabView.setTab(.Requests)
                (mainTabView.getViewController(.Requests) as! RequestsViewController).loadBaseURL()
            }
        case "inbox":
            mainTabView.setTab(.Messages)
        default:
            if trimmedURLPath.hasPrefix("/settings") {
                if tab == .Settings {
                    presentVisitableForSession(session, url: url, action: .Replace)
                } else {
                    mainTabView.setTab(.Settings)
                    (mainTabView.getViewController(.Settings) as! SettingsViewController).performSegue(withIdentifier: "segTLAccountSettings", sender: self)
                }
            } else if trimmedURLPath == "/notifications" { // have to do this after the "/settings" prefix check because if we're in account settings the last path component is also "notifications"
                if tab == .Notifications {
                    presentVisitableForSession(session, url: url, action: .Restore)
                } else {
                    mainTabView.setTab(.Notifications)
                    (mainTabView.getViewController(.Notifications) as! NotificationViewController).loadBaseURL()
                }
            } else if trimmedURLPath.matches(CommonRegexes.profileURL) {
                // Do we already have this person in our Realm database?
                if let m = Member.getMemberFromString(trimmedURLPath) {
                    let fpvc = storyboard!.instantiateViewController(withIdentifier: "vcFriendProfile") as! FriendProfileViewController
                    fpvc.friend = m
                    navCon.present(fpvc, animated: true, completion: nil)
                } else {
                    // if not, just present the visitable
                    presentVisitableForSession(session, url: url, action: action)
                }
            } else {
                presentVisitableForSession(session, url: url, action: action)
            }
        }
    }
}

extension TLViewController: SessionDelegate {
    
    func session(_ session: Session, didProposeVisitToURL URL: Foundation.URL, withAction action: Action) {
        checkForRedirects(session, forTab: tab, forURL: URL, withAction: action)
    }
    
    func session(_ session: Session, didFailRequestForVisitable visitable: Visitable, withError error: NSError) {
        print("ERROR: %@", error)
        guard let vcVisitable = visitable as? TLVisitableViewController, let errorCode = ErrorCode(rawValue: error.code) else { return }
        
        switch errorCode {
        case .httpFailure:
            let statusCode = error.userInfo["statusCode"] as! Int
            switch statusCode {
            case 404:
                print("URL not found")
                // file not found
                vcVisitable.presentError(.HTTPNotFoundError)
            default:
                print("HTTP \(statusCode) Error")
                vcVisitable.presentError(ConnectionError(HTTPStatusCode: statusCode))
            }
        case .networkFailure:
            print("Network error")
            vcVisitable.presentError(.NetworkError)
        }
    }
    
    func session(_ session: Session, openExternalURL URL: URL) {

        if !URL.scheme!.hasPrefix("http") {
            dlgOKCancel(self.navCon, title: "Open external link?", message: "You are about to open another application. Do you want to continue?\n\nLink: \(URL.absoluteString)", onOk: { (action) in
                app.openURL(URL)
            }, onCancel: nil)
            return
        }
        
        if !URL.host!.hasSuffix("fetlife.com"){
            dlgOKCancel(self.navCon, title: "Open external link?", message: "You are about to open an external link in Safari. Do you want to continue?", onOk: { (action) in
                app.openURL(URL)
            }, onCancel: nil)
        } else {
            checkForRedirects(session, forTab: .None, forURL: URL, withAction: .Advance)
        }
    }
}

extension TLViewController: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}

extension TLViewController: WKScriptMessageHandler {

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if let message = message.body as? String {
            let alertController = UIAlertController(title: "FetLife", message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alertController, animated: true, completion: nil)
        }
    }
}
