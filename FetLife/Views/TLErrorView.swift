//
//  TLErrorView.swift
//  FetLife
//
//  Created by Matt Conz on 8/8/18.
//  Copyright © 2018 BitLove Inc. All rights reserved.
//

import UIKit
import MessageUI

class TLErrorView: UIView, MFMailComposeViewControllerDelegate {

    @IBOutlet var errorImage: UIImageView!
    @IBOutlet var titleLabel: UILabel!
    @IBOutlet var messageLabel: UILabel!
    @IBOutlet var retryButton: UIButton!
    @IBOutlet var contactSupportButton: UIButton!
    
    var parent: UIViewController!
    
    var error: ConnectionError? {
        didSet {
            backgroundColor = UIColor.backgroundColor()
            titleLabel.text = error?.title
            messageLabel.text = error?.message
            errorImage.image = UIImage(imageLiteralResourceName: "Cone")
            errorImage.tintColor = UIColor.darkGray
            updateConstraintsIfNeeded()
        }
    }
    
    func getMailComposerView() -> MFMailComposeViewController {
        UINavigationBar.appearance().tintColor = UIColor.brickColor()
        let vcMailComposer = MFMailComposeViewController()
        vcMailComposer.mailComposeDelegate = self
        vcMailComposer.setToRecipients(["support@fetlife.com"])
        vcMailComposer.setSubject("[iOS App]")
        vcMailComposer.setMessageBody("\n\n\n\nUser Nickname: \(API.currentMemberNickname()!)\nUser ID: \(AppSettings.currentUserID)\nApp Version: \(APP_VERSION), build \(BUILD_NUMBER)\niOS Version: \(device.systemName) \(device.systemVersion)\nDevice Model: \(device.localizedModel)\nDevice ID: \(device.identifierForVendor?.uuidString ?? "Unknown Device ID")", isHTML: false)
        vcMailComposer.navigationBar.titleTextAttributes = convertToOptionalNSAttributedStringKeyDictionary([NSAttributedString.Key.foregroundColor.rawValue: UIColor.brickColor()])
        vcMailComposer.navigationBar.tintColor = UIColor.brickColor()
        return vcMailComposer
    }
    
    @IBAction func contactSupport(_ sender: UIButton) {
        let viewMC = getMailComposerView()
        if MFMailComposeViewController.canSendMail() {
            parent.present(viewMC, animated: true, completion: nil)
        } else {
            app.openURL(URL(string: "mailto:support@fetlife.com?body=\n\n\n\nUser Nickname: \(API.currentMemberNickname()!)\nUser ID: \(AppSettings.currentUserID)\nApp Version: \(APP_VERSION), build \(BUILD_NUMBER)\niOS Version: \(device.systemName) \(device.systemVersion)\nDevice Model: \(device.localizedModel)\nDevice ID: \(device.identifierForVendor?.uuidString ?? "Unknown Device ID")&subject=[iOS App]")!)
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true, completion: nil)
    }
    
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToOptionalNSAttributedStringKeyDictionary(_ input: [String: Any]?) -> [NSAttributedString.Key: Any]? {
	guard let input = input else { return nil }
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.Key(rawValue: key), value)})
}
