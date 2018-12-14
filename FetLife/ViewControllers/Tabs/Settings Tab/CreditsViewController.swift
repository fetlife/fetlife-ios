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
            NSDocumentTypeDocumentAttribute: NSRTFTextDocumentType as AnyObject,
            NSCharacterEncodingDocumentAttribute: NSNumber(value: String.Encoding.utf8.rawValue) as AnyObject
        ]
        credits.attributedText = try! NSAttributedString(url: URL(fileReferenceLiteralResourceName: "Credits.rtf"), options: attributedOptions, documentAttributes: nil)
    }

}
