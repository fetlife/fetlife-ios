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
	
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
	
	func viewForZooming(in scrollView: UIScrollView) -> UIView? {
		return self.imageView
	}
	
	@IBAction func doneButtonPressed(_ sender: AnyObject) {
		self.dismiss(animated: true, completion: nil)
	}

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
