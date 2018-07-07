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
    @IBOutlet var supporterIcon: UIImageView!
    @IBOutlet var metaInfo: UILabel!
    @IBOutlet var aboutMeText: UITextView!
    @IBOutlet var imageLoadProgress: UIProgressView!
    @IBOutlet var essentialsInfoStack: UIStackView!
    @IBOutlet var showHideEssentials: UIButton!
    @IBOutlet var showHideAboutMe: UIButton!
    @IBOutlet var genderText: UILabel!
    @IBOutlet var orientationText: UILabel!
    @IBOutlet var locationText: UILabel!
    @IBOutlet var mainStackHeightConstraint: NSLayoutConstraint!
    
    var friend: Member!
    var avatarImageFilter: AspectScaledToFillSizeWithRoundedCornersFilter?
    
    var stillLoadingTimer: Timer!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        imageLoadProgress.progress = 0
        self.title = friend.nickname
        nick.text = friend.nickname
        metaInfo.text = friend.metaLine
        
        if friend.genderName != "" && friend.orientation != "" { // if gender and orientation are blank, it means the info isn't loaded yet
            loadInfo(true)
        } else {
            loadInfo(false)
            stillLoadingTimer = Timer(timeInterval: 0.5, target: self, selector: #selector(checkIfLoaded), userInfo: nil, repeats: true)
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
        supporterIcon.tintColor = UIColor.darkGray
        
    }
    
    func checkIfLoaded() {
        if friend.genderName != "" && friend.orientation != "" {
            loadInfo(true)
            stillLoadingTimer.invalidate()
        }
    }
    
    func loadInfo(_ loaded: Bool) {
        genderText.text = loaded ? friend.genderName : "Loading..."
        orientationText.text = loaded ? friend.orientation  : "Loading..."
        if friend.city != "" {
            locationText.text = "\(friend.city), \(friend.country)"
        } else if friend.state != "" {
            locationText.text = "\(friend.state), \(friend.country)"
        } else {
            locationText.text = loaded ? friend.country : "Loading..."
        }
        aboutMeText.text = loaded ? friend.aboutMe : "Loading..."
        supporterIcon.isHidden = loaded ? !friend.isSupporter : true
        if aboutMeText.text == "" {
            aboutMeText.text = "Nothing to see here..."
            aboutMeText.textAlignment = .center
            aboutMeText.textColor = UIColor.darkGray
        } else {
            aboutMeText.textAlignment = .natural
            aboutMeText.textColor = UIColor.lightText
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
    
    @IBAction func showHideEssentialsTapped(_ sender: UIButton) {
        if essentialsInfoStack.isHidden {
            UIView.animate(withDuration: 0.2) {
                self.essentialsInfoStack.isHidden = false
                self.showHideEssentials.setTitle("tap to hide", for: .normal)
            }
        } else {
            UIView.animate(withDuration: 0.2) {
                self.essentialsInfoStack.isHidden = true
                self.showHideEssentials.setTitle("tap to show", for: .normal)
            }
        }
    }
    
    @IBAction func showHideAboutMeTapped(_ sender: UIButton) {
        if aboutMeText.isHidden {
            UIView.animate(withDuration: 0.2) {
                self.aboutMeText.isHidden = false
                self.showHideAboutMe.setTitle("tap to hide", for: .normal)
                self.mainStackHeightConstraint.isActive = true
            }
        } else {
            UIView.animate(withDuration: 0.2) {
                self.aboutMeText.isHidden = true
                self.showHideAboutMe.setTitle("tap to show", for: .normal)
                self.mainStackHeightConstraint.isActive = false
            }
        }
    }
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return .none
    }
}
