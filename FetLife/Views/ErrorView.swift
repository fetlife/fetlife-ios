//
//  ErrorView.swift
//  FetLife
//
//  Created by Jose Cortinas on 3/2/16.
//  Copyright © 2016 BitLove Inc. All rights reserved.
//

import UIKit

class ErrorView: UIView {
    
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
    
    lazy var coneImage: UIImageView = {
        let image = UIImageView(image: UIImage(named: "Cone")!)
        image.tintColor = UIColor.supporterIconTintColor()
        return image
    }()
    
    lazy var textLabel: UILabel = {
        let label = UILabel()
        label.text = "Houston, we have a problem!"
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
        stackView.addArrangedSubview(coneImage)
        stackView.addArrangedSubview(textLabel)
        addSubview(stackView)
        
        backgroundColor = UIColor.backgroundColor()
        translatesAutoresizingMaskIntoConstraints = false
        
        stackView.snp.makeConstraints { make in
            make.centerX.equalTo(snp.centerX)
            make.topMargin.equalTo(70.0)
        }
        
        textLabel.snp.makeConstraints { make in
            make.width.lessThanOrEqualTo(248.0)
        }
    }
}
