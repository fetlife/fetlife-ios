//
//  LoadingView.swift
//  FetLife
//
//  Created by Jose Cortinas on 3/2/16.
//  Copyright © 2016 BitLove Inc. All rights reserved.
//

import UIKit
import RealmSwift

class LoadingView: UIView {
    
    // MARK: - Properties
    
    lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.distribution = .fillProportionally
        stack.alignment = .center
        stack.spacing = 26.0
        stack.translatesAutoresizingMaskIntoConstraints = false
        return stack
    }()
    
    lazy var activityIndicatorView: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(activityIndicatorStyle:  UIActivityIndicatorViewStyle.whiteLarge)
        indicator.startAnimating()
        return indicator
    }()
    
    lazy var textLabel: UILabel = {
        let label = UILabel()
        label.text = "Loading…"
        label.textColor = UIColor.brownishGreyColor()
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
	
	lazy var noConversationsLabel: UILabel = {
		let label = UILabel()
		label.text = "No Conversations"
		label.textColor = UIColor.brownishGreyColor()
		label.lineBreakMode = .byWordWrapping
		label.numberOfLines = 0
		label.textAlignment = .center
		return label
	}()
    
    // MARK: - Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupView()
    }
    
    func setupView() {
        stackView.addArrangedSubview(activityIndicatorView)
        stackView.addArrangedSubview(textLabel)
        
        addSubview(stackView)
        
        backgroundColor = UIColor.backgroundColor()
        translatesAutoresizingMaskIntoConstraints = false
        
        stackView.snp.makeConstraints { make in
            make.centerX.equalTo(snp.centerX)
            make.topMargin.equalTo(97.0)
        }
		
		if API.sharedInstance.isAuthorized() { // only show loading view if logged in
			activityIndicatorView.snp.makeConstraints { make in
				make.size.equalTo(37.0)
			}
			
			textLabel.snp.makeConstraints { make in
				make.width.lessThanOrEqualTo(248.0)
			}
		} else {
			stackView.removeArrangedSubview(activityIndicatorView)
			stackView.removeArrangedSubview(textLabel)
			stackView.addArrangedSubview(noConversationsLabel)
			noConversationsLabel.snp.makeConstraints { make in
				make.width.lessThanOrEqualTo(248.0)
			}
		}
    }
}
