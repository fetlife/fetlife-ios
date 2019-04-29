//
//  CreditsViewController.swift
//  FetLife
//
//  Created by Matt Conz on 8/17/18.
//  Copyright © 2018 BitLove Inc. All rights reserved.
//

import UIKit

class CreditsViewController: UIViewController {

    @IBOutlet var credits: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        let attributedOptions: [String: AnyObject] = [
            convertFromNSAttributedStringDocumentAttributeKey(NSAttributedString.DocumentAttributeKey.documentType): convertFromNSAttributedStringDocumentType(NSAttributedString.DocumentType.rtf) as AnyObject,
            convertFromNSAttributedStringDocumentAttributeKey(NSAttributedString.DocumentAttributeKey.characterEncoding): NSNumber(value: String.Encoding.utf8.rawValue) as AnyObject
        ]
        credits.attributedText = try! NSAttributedString(url: URL(fileReferenceLiteralResourceName: "Credits.rtf"), options: convertToNSAttributedStringDocumentReadingOptionKeyDictionary(attributedOptions), documentAttributes: nil)
    }

}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringDocumentAttributeKey(_ input: NSAttributedString.DocumentAttributeKey) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertFromNSAttributedStringDocumentType(_ input: NSAttributedString.DocumentType) -> String {
	return input.rawValue
}

// Helper function inserted by Swift 4.2 migrator.
fileprivate func convertToNSAttributedStringDocumentReadingOptionKeyDictionary(_ input: [String: Any]) -> [NSAttributedString.DocumentReadingOptionKey: Any] {
	return Dictionary(uniqueKeysWithValues: input.map { key, value in (NSAttributedString.DocumentReadingOptionKey(rawValue: key), value)})
}
