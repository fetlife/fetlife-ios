//
//  TLVisitableViewController.swift
//  FetLife
//
//  Created by Matt Conz on 8/8/18.
//  Copyright © 2018 BitLove Inc. All rights reserved.
//

import UIKit
import Turbolinks

struct ConnectionError {
    static let HTTPNotFoundError = ConnectionError(title: "Page Not Found", message: "There doesn’t seem to be anything here.")
    static let NetworkError = ConnectionError(title: "Can’t Connect", message: "Unable to connect to ")
    static let UnknownError = ConnectionError(title: "Unknown Error", message: "An unknown error occurred.")
    
    let title: String
    let message: String
    
    init(title: String, message: String) {
        self.title = title
        self.message = message
    }
    
    init(HTTPStatusCode: Int) {
        self.title = "Server Error"
        self.message = "The server returned an HTTP \(HTTPStatusCode) response."
    }
}

class TLVisitableViewController: Turbolinks.VisitableViewController {
    lazy var errorView: TLErrorView = {
        let view = Bundle.main.loadNibNamed("TLErrorView", owner: self, options: nil)!.first as! TLErrorView
        view.translatesAutoresizingMaskIntoConstraints = false
        view.retryButton.addTarget(self, action: #selector(retry(_:)), for: .touchUpInside)
        return view
    }()
    
    override func visitableDidRender() {
        title = formatTitle(visitableView.webView?.title)
    }
    
    // if on a FetLife page, we don't need the " | FetLife" part of the title
    func formatTitle(_ title: String?) -> String? {
        if let t = title {
            if t.hasSuffix(" | FetLife") {
                let endIndex = t.index(t.endIndex, offsetBy: -10)
                return t.substring(to: endIndex)
            }
            return t
        }
        return nil
    }
    
    func presentError(_ error: ConnectionError) {
        errorView.error = error
        view.addSubview(errorView)
        installErrorViewConstraints()
    }
    
    func installErrorViewConstraints() {
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "H:|[view]|", options: [], metrics: nil, views: [ "view": errorView ]))
        view.addConstraints(NSLayoutConstraint.constraints(withVisualFormat: "V:|[view]|", options: [], metrics: nil, views: [ "view": errorView ]))
    }
    
    @objc func retry(_ sender: AnyObject) {
        errorView.removeFromSuperview()
        reloadVisitable()
    }
}
