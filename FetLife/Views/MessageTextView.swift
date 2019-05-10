//
//  MessageTextView.swift
//  FetLife
//
//  Created by Matt Conz on 5/25/18.
//  Copyright © 2018 BitLove Inc. All rights reserved.
//

import UIKit

class MessageTextView: UITextView, UITextViewDelegate {
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.delegate = self
        self.isEditable = false
        self.isSelectable = true
    }
    
    @available(iOS 10.0, *)
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        print(URL)
        return true
    }
    
    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange) -> Bool {
        print(URL)
        return true
    }
    
}
