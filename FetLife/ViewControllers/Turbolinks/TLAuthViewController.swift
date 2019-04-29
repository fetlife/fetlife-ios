//
//  TLAuthViewController.swift
//  FetLife
//
//  Created by Matt Conz on 8/14/18.
//  Copyright © 2018 BitLove Inc. All rights reserved.
//

import UIKit
import WebKit

protocol TLAuthControllerDelegate: class {
    func authenticationControllerDidAuthenticate(_ authenticationController: TLAuthViewController)
    func authenticationControllerDidCancel(_ authenticationController: TLAuthViewController)
}

class TLAuthViewController: UIViewController {
    var url: URL?
    weak var delegate: TLAuthControllerDelegate?
    
    lazy var webViewConfiguration: WKWebViewConfiguration = {
        let configuration = WKWebViewConfiguration()
        configuration.userContentController.add(self, name: "fetlife-ios")
        configuration.processPool = API.sharedInstance.webViewProcessPool
        configuration.applicationNameForUserAgent = "FetLife iOS App \(APP_VERSION)"
        return configuration
    }()
    
    lazy var webView: WKWebView = {
        let configuration = self.webViewConfiguration
        let webView = WKWebView(frame: CGRect.zero, configuration: configuration)
        webView.translatesAutoresizingMaskIntoConstraints = false
        webView.navigationDelegate = self
        return webView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let cancelButton = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(userDidCancel))
        self.navigationItem.leftBarButtonItem = cancelButton
        
        view.addSubview(webView)
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|", options: [], metrics: nil, views: [ "view": webView ]))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|", options: [], metrics: nil, views: [ "view": webView ]))
        
        if let url = self.url {
            webView.load(URLRequest(url: url))
        }
        
    }
    
    @objc func userDidCancel() {
        delegate?.authenticationControllerDidCancel(self)
    }
}
    
extension TLAuthViewController: WKScriptMessageHandler {

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        if let message = message.body as? String {
            let alertController = UIAlertController(title: "FetLife", message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alertController, animated: true, completion: nil)
        }
    }
}

extension TLAuthViewController: WKNavigationDelegate {
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if let url = navigationAction.request.url, !(url == self.url || url == URL(string: "https://fetlife.com/login")!) {
            decisionHandler(.cancel)
            delegate?.authenticationControllerDidAuthenticate(self)
            return
        }
        
        decisionHandler(.allow)
    }
}

