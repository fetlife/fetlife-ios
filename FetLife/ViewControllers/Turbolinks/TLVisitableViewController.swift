//
//  TLVisitableViewController.swift
//  FetLife
//
//  Created by Matt Conz on 8/8/18.
//  Copyright © 2018 BitLove Inc. All rights reserved.
//

import UIKit
import WebKit
import Turbolinks

class TLVisitableViewController: Turbolinks.VisitableViewController {
    
    var watchdogTimer: Timer?
    var currentSession: Session?
    
    lazy var errorView: TLErrorView = {
        let view = Bundle.main.loadNibNamed("TLErrorView", owner: self, options: nil)!.first as! TLErrorView
        view.translatesAutoresizingMaskIntoConstraints = false
        view.retryButton.addTarget(self, action: #selector(retry(_:)), for: .touchUpInside)
        return view
    }()
    
    lazy var webViewConfiguration: WKWebViewConfiguration = {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(self, name: "fetlife-ios")
        configuration.processPool = API.sharedInstance.webViewProcessPool
        configuration.applicationNameForUserAgent = "FetLife iOS App \(APP_VERSION)"
        return configuration
    }()
    
    lazy var refreshButton: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: .refresh, target: self, action: #selector(retry(_:)))
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        visitableView.backgroundColor = UIColor.backgroundColor()
        navigationItem.title = "Loading..."
        watchdogTimer = Timer.scheduledTimer(timeInterval: 20, target: self, selector: #selector(timeoutError), userInfo: nil, repeats: false)
        visitableView.activityIndicatorView.hidesWhenStopped = true
        visitableView.allowsPullToRefresh = true
        visitableView.refreshControl.addTarget(self, action: #selector(retry(_:)), for: .valueChanged)
        let openInSafariButton = UIBarButtonItem(image: UIImage(imageLiteralResourceName: "OpenInSafari"), style: .plain, target: self, action: #selector(openInSafari))
        navigationItem.rightBarButtonItems = [refreshButton, openInSafariButton]
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        visitableView.deactivateWebView()
        visitableView.webView?.stopLoading()
        watchdogTimer?.invalidate()
        visitableView.refreshControl.endRefreshing()
    }
    
    override func visitableDidRender() {
        watchdogTimer?.invalidate()
        navigationItem.title = formatTitle(visitableView.webView?.title)
        if navigationItem.title == "Login" {
            presentError(.NotLoggedInError)
        } else if navigationItem.title == "We'll Miss You!" { // logged out
            presentError(.LoggedOutError)
        }
        visitableView.refreshControl.endRefreshing()
    }
    
    
    // if on a FetLife page, we don't need the " | FetLife" part of the title
    func formatTitle(_ title: String?) -> String? {
        if var t = title {
            if t.hasSuffix(" | FetLife") {
                let endIndex = t.index(t.endIndex, offsetBy: -10)
                t = t.substring(to: endIndex)
            }
            guard t != "" else { return nil }
            // if there are notifications pending, remove the "(2)" or "(0/3)" in the title
            t = CommonRegexes.parentheticalNumbers.stringByReplacingMatches(in: t, options: .withTransparentBounds, range: t.range(), withTemplate: "")
            return t
        }
        return nil
    }
    
    @objc func timeoutError() {
        navigationItem.title = formatTitle(visitableView.webView?.title)
        presentError(.TimeoutError)
    }
    
    func presentError(_ error: ConnectionError) {
        errorView.error = error
        errorView.parent = self
        if error == ConnectionError.NotLoggedInError || error == ConnectionError.LoggedOutError {
            navigationItem.title = "Not Logged In"
            errorView.retryButton.setTitle("Login", for: .normal)
            errorView.retryButton.addTarget(self, action: #selector(presentAuthentication(_:)), for: .touchUpInside)
        } else {
            navigationItem.title = "Error"
            errorView.retryButton.setTitle("Retry", for: .normal)
            errorView.retryButton.addTarget(self, action: #selector(retry(_:)), for: .touchUpInside)
        }
        view.addSubview(errorView)
        installErrorViewConstraints()
    }
    
    @objc func presentAuthentication(_ sender: AnyObject) {
        let authCon = TLAuthViewController()
        authCon.delegate = self
        authCon.url = URL(string: "https://fetlife.com/users/sign_in")!
        authCon.webViewConfiguration = self.webViewConfiguration
        authCon.navigationItem.title = "Login"
        let navCon = UINavigationController(rootViewController: authCon)
        self.present(navCon, animated: true, completion: nil)
    }
    
    func installErrorViewConstraints() {
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|", options: [], metrics: nil, views: ["view": errorView]))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|",options: [], metrics: nil, views: ["view": errorView]))
    }
    
    @objc func retry(_ sender: AnyObject) {
        errorView.removeFromSuperview()
        navigationItem.title = "Loading..."
        currentSession?.reload()
        let nvc = navigationController as? TLNavViewController
        guard nvc != nil && visitableURL != nil else { return }
        nvc!.presentVisitableForSession(nvc!.currentSession, url: visitableURL, action: .Replace)
        watchdogTimer = Timer.scheduledTimer(timeInterval: 20, target: self, selector: #selector(timeoutError), userInfo: nil, repeats: false)
    }
    
    @objc func openInSafari() {
        dlgOKCancel(self, title: "Open external link?", message: "You are about to open an external link in Safari. Do you want to continue?", onOk: { (_) in
            app.openURL(self.visitableURL)
        }, onCancel: nil)
    }
}

extension TLVisitableViewController: TLAuthControllerDelegate {
    
    func authenticationControllerDidAuthenticate(_ authenticationController: TLAuthViewController) {
        dismiss(animated: true) {
            self.errorView.removeFromSuperview()
            self.navigationItem.title = "Loading..."
            self.reloadVisitable()
            self.currentSession?.reload()
            self.watchdogTimer = Timer.scheduledTimer(timeInterval: 15, target: self, selector: #selector(self.timeoutError), userInfo: nil, repeats: false)
        }
    }

    func authenticationControllerDidCancel(_ authenticationController: TLAuthViewController) {
        dismiss(animated: true) {
            self.errorView.removeFromSuperview() // remove from superview if present
            self.presentError(.NotLoggedInError)
        }
    }
}

extension TLVisitableViewController: WKScriptMessageHandler {
    
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if let message = message.body as? String {
            let alertController = UIAlertController(title: "FetLife", message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alertController, animated: true, completion: nil)
        }
    }
}
