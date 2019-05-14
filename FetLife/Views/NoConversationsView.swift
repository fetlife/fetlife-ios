//
//  NoConversationsView.swift
//  FetLife
//
//  Created by Jose Cortinas on 3/2/16.
//  Copyright © 2016 BitLove Inc. All rights reserved.
//

import UIKit

class NoConversationsView: UIView {
    
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
    
    lazy var vaderImage: UIImageView = {
        return UIImageView(image: UIImage(named: "Vader")!)
    }()
    
    lazy var textLabel: UILabel = {
        let label = UILabel()
        label.text = "Luke, you sadly haven't received any messages yet."
        label.textColor = UIColor.brownishGreyColor()
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.textAlignment = .center
        return label
    }()
    
    lazy var refreshButton: UIButton = {
        let button = UIButton()
        button.titleLabel?.font = UIFont.systemFont(ofSize: 17.0)
        button.setTitle("Refresh", for: UIControl.State())
        button.setTitleColor(UIColor.brickColor(), for: UIControl.State())
        button.addTarget(self, action: #selector(NoConversationsView.tryRefresh), for: .touchUpInside)
        return button
    }()
    
    var refreshAction: (() -> Void)?
    
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
        stackView.addArrangedSubview(vaderImage)
        stackView.addArrangedSubview(textLabel)
        stackView.addArrangedSubview(refreshButton)
        
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
    
    // MARK: - Actions
    
    @objc func tryRefresh() {
        refreshAction?()
    }
}
