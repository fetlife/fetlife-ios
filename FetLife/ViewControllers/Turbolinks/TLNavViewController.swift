//
//  TLNavViewController.swift
//  FetLife
//
//  Created by Matt Conz on 8/24/18.
//  Copyright © 2018 BitLove Inc. All rights reserved.
//

import UIKit
import WebKit
import Turbolinks
import MessageUI

class TLNavViewController: UINavigationController {
    
    var url: URL!
    
    // These three functions should always be overridden
    func baseURL() -> URL { return URL(string: "https://fetlife.com")! }
    func tabTitle() -> String { return "Home" }
    func tab() -> TabIndex { return .Home }
    
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
        url = baseURL()
        tabBarItem.title = tabTitle()
        mainTabView = self.tabBarController as! MainTabViewController
        
        if tabTitle() == "Home" && !(API.sharedInstance.currentMember?.isSupporter ?? false) {
            presentError(.TLHomepageDisabledNonSupporter)
        } else {
            currentSession.webView.backgroundColor = UIColor.backgroundColor()
            presentVisitableForSession(currentSession, url: baseURL())
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        checkForReload()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        (currentSession.topmostVisitable as? TLVisitableViewController)?.watchdogTimer?.invalidate()
    }
    
    func checkForReload() {
        
        if tabTitle() == "Home" && !API.sharedInstance.currentMember!.isSupporter {
            presentError(.TLHomepageDisabledNonSupporter)
        } else {
            // only reload if on the notification page
            if currentSession.webView.url == baseURL() {
                loadBaseURL()
            }
        }
        
        API.sharedInstance.getRequests { (requests, err) in
            guard err == nil else { return }
            self.mainTabView.setBadge(requests.count, forTab: .Requests)
        }
    }
    
    func loadURL(_ url: URL) {
        guard url != baseURL() else { loadBaseURL(); return }
        presentVisitableForSession(currentSession, url: url, action: .Replace)
    }
    
    func loadBaseURL() {
        if tabTitle() == "Home" && !API.sharedInstance.currentMember!.isSupporter {
            presentError(.TLHomepageDisabledNonSupporter)
        } else {
            presentVisitableForSession(currentSession, url: baseURL(), action: .Restore)
        }
    }
    
    func presentVisitableForSession(_ session: Session, url: URL, action: Action = .Advance) {
        let visitable = TLVisitableViewController(url: url)
        visitable.visitableDelegate = self
        if action == .Advance {
            pushViewController(visitable, animated: true)
        } else if action == .Replace {
            if viewControllers.count == 1 {
                self.viewControllers = []
                pushViewController(visitable, animated: false)
            } else {
                popViewController(animated: false)
                pushViewController(visitable, animated: false)
            }
        } else if action == .Restore {
            self.viewControllers = []
            pushViewController(visitable, animated: true)
        }
        
        session.visit(visitable)
        tabBarItem.title = tabTitle()
    }
    
    func presentError(_ error: ConnectionError) {
        let visitable = TLVisitableViewController()
        visitable.visitableDelegate = self
        if viewControllers.count == 1 {
            self.viewControllers = []
            pushViewController(visitable, animated: false)
        } else {
            popViewController(animated: false)
            pushViewController(visitable, animated: false)
        }
        if error == .TLHomepageDisabledNonSupporter {
            visitable.errorView.retryButton.addTarget(self, action: #selector(checkForReload), for: .touchUpInside)
            visitable.refreshButton.target = self
            visitable.refreshButton.action = #selector(checkForReload)
        }
        visitable.presentError(error)
        navigationController?.title = "Error"
        tabBarItem.title = tabTitle()
    }
    
    func checkForRedirects(_ session: Session, forTab tab: TabIndex, forURL url: URL, withAction action: Action) {
        
        // remove anchors for the purpose of redirects
        var trimmedURLPath = url.lastPathComponent
        if let index = trimmedURLPath.lastIndex(of: "#") {
            trimmedURLPath = trimmedURLPath.substring(to: index)
        }
        
        switch trimmedURLPath {
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
        case "notifications":
            if tab == .Notifications {
                presentVisitableForSession(session, url: url, action: .Restore)
            } else {
                mainTabView.setTab(.Notifications)
                (mainTabView.getViewController(.Notifications) as! NotificationViewController).loadBaseURL()
            }
        default:
            if trimmedURLPath.hasPrefix("/settings") {
                if tab == .Settings {
                    presentVisitableForSession(session, url: url, action: .Replace)
                } else {
                    mainTabView.setTab(.Settings)
                    (mainTabView.getViewController(.Settings) as! SettingsViewController)
                        .performSegue(withIdentifier: "segTLAccountSettings", sender: self)
                }
            } else {
                presentVisitableForSession(session, url: url, action: action)
            }
        }
    }
}

extension TLNavViewController: SessionDelegate {
    
    func session(_ session: Session, didProposeVisitToURL URL: Foundation.URL, withAction action: Action) {
        checkForRedirects(session, forTab: tab(), forURL: URL, withAction: action)
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
                print("Other error")
                vcVisitable.presentError(ConnectionError(HTTPStatusCode: statusCode))
            }
        case .networkFailure:
            print("Network error")
            vcVisitable.presentError(.NetworkError)
        }
    }
    
    func session(_ session: Session, openExternalURL URL: URL) {
        
        func getMailComposerView() -> MFMailComposeViewController {
            let vcMailComposer = MFMailComposeViewController()
            vcMailComposer.mailComposeDelegate = self
            vcMailComposer.setToRecipients([URL.baseURL!.absoluteString])
            return vcMailComposer
        }
        
        if URL.scheme! == "mailto" {
            let vcMailComposer = getMailComposerView()
            if MFMailComposeViewController.canSendMail() {
                self.present(vcMailComposer, animated: true, completion: nil)
            } else {
                app.openURL(URL)
            }
            return
        } else if !URL.scheme!.hasPrefix("http") {
            dlgOKCancel(self, title: "Open external link?", message: "You are about to open another application. Do you want to continue?\n\nLink: \(URL.absoluteString)", onOk: { (action) in
                app.openURL(URL)
            }, onCancel: nil)
            return
        }
        
        if !URL.host!.hasSuffix("fetlife.com"){
            dlgOKCancel(self, title: "Open external link?", message: "You are about to open an external link in Safari. Do you want to continue?", onOk: { (action) in
                app.openURL(URL)
            }, onCancel: nil)
        } else {
            checkForRedirects(session, forTab: tab(), forURL: URL, withAction: .Advance)
        }
    }
}

extension TLNavViewController: MFMailComposeViewControllerDelegate {
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
}

extension TLNavViewController: VisitableDelegate {
    
    func visitableViewWillAppear(_ visitable: Visitable) { }
    
    func visitableViewDidAppear(_ visitable: Visitable) {
        visitable.visitableDidRender()
    }
    
    func visitableDidRequestReload(_ visitable: Visitable) {
        currentSession.reload()
    }
    
    func visitableDidRequestRefresh(_ visitable: Visitable) {
        visitable.visitableView.webView?.reload()
    }
}

extension TLNavViewController: WKScriptMessageHandler {
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if let message = message.body as? String {
            let alertController = UIAlertController(title: "FetLife", message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alertController, animated: true, completion: nil)
        }
    }
}

