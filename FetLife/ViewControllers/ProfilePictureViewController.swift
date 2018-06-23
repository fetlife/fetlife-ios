//
//  ProfilePictureViewController.swift
//  FetLife
//
//  Created by Matt Conz on 6/13/18.
//  Copyright © 2018 BitLove Inc. All rights reserved.
//

import UIKit

class ProfilePictureViewController: UIViewController, UIScrollViewDelegate {
    
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var navBar: UINavigationBar!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        self.navigationController?.isNavigationBarHidden = false
    }
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return self.imageView
    }
    
    @IBAction func doneButtonPressed(_ sender: AnyObject) {
        self.dismiss(animated: true, completion: nil)
    }

}
