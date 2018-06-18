//
//  BaseMessagesTableViewCell.swift
//  FetLife
//
//  Created by Jose Cortinas on 2/11/16.
//  Copyright © 2016 BitLove Inc. All rights reserved.
//

import UIKit

class BaseMessagesTableViewCell: UITableViewCell {
    
    @IBOutlet weak var bodyLabel: MessageTextView!
    @IBOutlet weak var unreadMarkerView: UIView!
    @IBOutlet weak var messageContainerView: UIView!
	@IBOutlet weak var messageTimestamp: UILabel!
	
	let dateFormatter = DateFormatter()
    
    var message: Message? = nil {
        didSet {
            if let m = message {
                self.bodyLabel.text = m.isSending ? "Sending..." : m.body
				let timeSince: TimeInterval = m.createdAt.timeIntervalSinceNow
				// if it's been less than a day, show relative time
				if abs(timeSince) <= 60 * 60 * 24 {
					self.messageTimestamp.text = m.createdAt.relativeTime
				} else {
					self.messageTimestamp.text = dateFormatter.string(from: m.createdAt)
				}
            }
        }
    }

    override func awakeFromNib() {
        super.awakeFromNib()
		dateFormatter.dateStyle = .short
		dateFormatter.timeStyle = .medium
		dateFormatter.locale = .current
		if let m = message {
			let timeSince: TimeInterval = m.createdAt.timeIntervalSinceNow
			// if it's been less than a day, show relative time
			if abs(timeSince) <= 60 * 60 * 24 {
				self.messageTimestamp.text = m.createdAt.relativeTime
			} else {
				self.messageTimestamp.text = dateFormatter.string(from: m.createdAt)
			}
		}
    }

}

extension Date {
	var yearsFromNow:   Int { return Calendar.current.dateComponents([.year],       from: self, to: Date()).year        ?? 0 }
	var monthsFromNow:  Int { return Calendar.current.dateComponents([.month],      from: self, to: Date()).month       ?? 0 }
	var weeksFromNow:   Int { return Calendar.current.dateComponents([.weekOfYear], from: self, to: Date()).weekOfYear  ?? 0 }
	var daysFromNow:    Int { return Calendar.current.dateComponents([.day],        from: self, to: Date()).day         ?? 0 }
	var hoursFromNow:   Int { return Calendar.current.dateComponents([.hour],       from: self, to: Date()).hour        ?? 0 }
	var minutesFromNow: Int { return Calendar.current.dateComponents([.minute],     from: self, to: Date()).minute      ?? 0 }
	var secondsFromNow: Int { return Calendar.current.dateComponents([.second],     from: self, to: Date()).second      ?? 0 }
	var relativeTime: String {
		if yearsFromNow   > 0 { return "\(yearsFromNow) year"    + (yearsFromNow    > 1 ? "s" : "") + " ago" }
		if monthsFromNow  > 0 { return "\(monthsFromNow) month"  + (monthsFromNow   > 1 ? "s" : "") + " ago" }
		if weeksFromNow   > 0 { return "\(weeksFromNow) week"    + (weeksFromNow    > 1 ? "s" : "") + " ago" }
		if daysFromNow    > 0 { return daysFromNow == 1 ? "Yesterday" : "\(daysFromNow) days ago" }
		if hoursFromNow   > 0 { return "\(hoursFromNow) hour"     + (hoursFromNow   > 1 ? "s" : "") + " ago" }
		if minutesFromNow > 0 { return "\(minutesFromNow) minute" + (minutesFromNow > 1 ? "s" : "") + " ago" }
		if secondsFromNow > 0 { return secondsFromNow < 5 ? "Just now"
			: "\(secondsFromNow) second" + (secondsFromNow > 1 ? "s" : "") + " ago" }
		return ""
	}
}
