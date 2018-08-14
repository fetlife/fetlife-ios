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

class FriendProfileViewController: UIViewController, UIPopoverPresentationControllerDelegate, UIGestureRecognizerDelegate {
    
    @IBOutlet var profilePicture: BlurImageView!
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
    @IBOutlet var profilePicTapGesture: UITapGestureRecognizer!
    @IBOutlet var logoutButton: UIBarButtonItem!
    @IBOutlet var openInSafariButton: UIBarButtonItem!
    
    var friend: Member!
    var isMe: Bool = false
    var messagesViewController: MessagesTableViewController!
    var avatarImageFilter: AspectScaledToFillSizeWithRoundedCornersFilter?
    
    var stillLoadingTimer: Timer = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        imageLoadProgress.progress = 0
        self.title = friend.nickname
        nick.text = friend.nickname
        metaInfo.text = friend.metaLine
        
        if friend.additionalInfoRetrieved {
            loadInfo(true)
        } else {
            loadInfo(false)
            stillLoadingTimer = Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(checkIfLoaded), userInfo: nil, repeats: true)
        }
        
        avatarImageFilter = AspectScaledToFillSizeWithRoundedCornersFilter(size: profilePicture.frame.size, radius: 3.0)
        profilePicture.layer.cornerRadius = 10.0
        profilePicture.layer.borderWidth = 1
        profilePicture.layer.borderColor = UIColor.backgroundColor().cgColor
        if friend.avatarImageData == nil {
            profilePicture.af_setImageWithBlur(withURL: URL(string: friend.avatarURL)!, placeholderImage: #imageLiteral(resourceName: "DefaultAvatar"), filter: avatarImageFilter, progress: { (progress) in
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
            profilePicture.createBlurView()
        }
        supporterIcon.tintColor = UIColor.darkGray
        profilePicture.awakeFromNib()
        if isMe {
            self.navigationItem.rightBarButtonItems = [logoutButton, openInSafariButton]
        } else {
            self.navigationItem.rightBarButtonItem = openInSafariButton
        }
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Don't recognize a single tap until a double-tap fails.
        if gestureRecognizer == self.profilePicTapGesture &&
            otherGestureRecognizer == self.profilePicture.doubleTapRecognizer {
            return true
        }
        return false
    }
    
    func checkIfLoaded() {
        print("checking for info")
        friend = messagesViewController.member
        if friend.additionalInfoRetrieved {
            print("Info loaded!")
            loadInfo(true)
            stillLoadingTimer.invalidate()
        } else { print("info not yet loaded") }
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
        } else if !loaded {
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
    
    @IBAction func logoutButtonPressed(_ sender: UIBarButtonItem) {
        let alertController = UIAlertController(title: "Are you sure?", message: "Do you really want to log out of FetLife? We'll be very sad... 😢", preferredStyle: .actionSheet)
        let okAction = UIAlertAction(title: "Logout", style: .destructive) { (action) -> Void in
            API.sharedInstance.logout()
            self.navigationController?.viewControllers = [self.storyboard!.instantiateViewController(withIdentifier: "loginView"), self]
            _ = self.navigationController?.popViewController(animated: false)
            _ = self.navigationController?.popViewController(animated: true)
        }
        let cancelAction = UIAlertAction(title: "Never mind", style: .cancel, handler: nil)
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    @IBAction func openInSafari(_ sender: UIBarButtonItem) {
        dlgOKCancel(self, title: "Open external link?", message: "You are about to open an external link in Safari. Do you want to continue?", onOk: { (action) in
            UIApplication.shared.openURL(URL(string: self.friend.fetProfileURL)!)
        }, onCancel: nil)
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
