//
//  FriendProfileViewController.swift
//  FetLife
//
//  Created by Matt Conz on 5/30/18.
//  Copyright © 2018 BitLove Inc. All rights reserved.
//

import UIKit
import RealmSwift
import AlamofireImage

class FriendProfileViewController: UIViewController, UIPopoverPresentationControllerDelegate {
    
    @IBOutlet var profilePicture: UIImageView!
    @IBOutlet var nick: UILabel!
    @IBOutlet var metaInfo: UILabel!
    @IBOutlet var aboutMeText: UITextView!
    @IBOutlet var imageLoadProgress: UIProgressView!
    
    var friend: Member!
    var avatarImageFilter: AspectScaledToFillSizeWithRoundedCornersFilter?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        imageLoadProgress.progress = 0
        self.title = friend.nickname
        nick.text = friend.nickname
        metaInfo.text = friend.metaLine
        aboutMeText.text = friend.aboutMe
        
        if aboutMeText.text == "" {
            aboutMeText.text = "Nothing to see here 😶"
        }
        
        avatarImageFilter = AspectScaledToFillSizeWithRoundedCornersFilter(size: profilePicture.frame.size, radius: 3.0)
        profilePicture.layer.cornerRadius = 10.0
        profilePicture.layer.borderWidth = 1
        profilePicture.layer.borderColor = UIColor.backgroundColor().cgColor
        if friend.avatarImageData == nil {
            profilePicture.af_setImage(withURL: URL(string: friend.avatarURL)!, placeholderImage: #imageLiteral(resourceName: "DefaultAvatar"), filter: avatarImageFilter, progress: { (progress) in
                self.imageLoadProgress.setProgress(Float(progress.fractionCompleted), animated: true)
            }, progressQueue: .main, imageTransition: .noTransition, runImageTransitionIfCached: false) { (response) in
                if response.error != nil {
                    print(response.error!)
                }
                self.imageLoadProgress.progress = 0
                self.imageLoadProgress.isHidden = true
            }
        } else {
            profilePicture.image = UIImage(data: friend.avatarImageData!)
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Navigation
    
    @IBAction func profilePictureTapped(_ sender: AnyObject) {
        let ppvc: ProfilePictureViewController = storyboard?.instantiateViewController(withIdentifier: "vcProfilePicture") as! ProfilePictureViewController
        ppvc.imageView = profilePicture
        let navCon = UINavigationController(rootViewController: ppvc)
        self.present(navCon, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "FriendManagementSegue" {
            let favc: FriendActionsViewController = segue.destination as! FriendActionsViewController
            let controller = favc.popoverPresentationController
            favc.friend = friend
            if (controller != nil) {
                controller?.delegate = self
            }
        }
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}
