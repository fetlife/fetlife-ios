//
//  BlurImageView.swift
//  FetLife
//
//  Created by Matt Conz on 7/8/18.
//  Copyright © 2018 BitLove Inc. All rights reserved.
//

import UIKit
import DynamicBlurView
import Alamofire
import AlamofireImage

class BlurImageView: UIImageView, UIGestureRecognizerDelegate {
    
    var blurRadius: CGFloat = 10
    private var blurView: DynamicBlurView!
    private var isBlurred: Bool = false
    private var blurDelay: Double = 0.25
    // Create a gesture recognizer for double-tapping an image.
    let doubleTapRecognizer = UITapGestureRecognizer()
    
    // MARK: - Init Overrides
    
    override init(image: UIImage?) {
        super.init(image: image)
        createBlurView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        createBlurView()
    }
    
    func af_setImageWithBlur(withURL url: URL, placeholderImage: UIImage?, filter: ImageFilter?, progress: ImageDownloader.ProgressHandler?, progressQueue: DispatchQueue, imageTransition: UIImageView.ImageTransition, runImageTransitionIfCached: Bool, completion: ((DataResponse<UIImage>) -> Void)?) {
        super.af_setImage(withURL: url, placeholderImage: placeholderImage, filter: filter, progress: progress, progressQueue: progressQueue, imageTransition: imageTransition, runImageTransitionIfCached: runImageTransitionIfCached, completion: completion)
        createBlurView()
    }
    
    func af_setImageWithBlur(withURLRequest urlRequest: URLRequestConvertible, placeholderImage: UIImage?, filter: ImageFilter?, progress: ImageDownloader.ProgressHandler?, progressQueue: DispatchQueue, imageTransition: UIImageView.ImageTransition, runImageTransitionIfCached: Bool, completion: ((DataResponse<UIImage>) -> Void)?) {
        super.af_setImage(withURLRequest: urlRequest, placeholderImage: placeholderImage, filter: filter, progress: progress, progressQueue: progressQueue, imageTransition: imageTransition, runImageTransitionIfCached: runImageTransitionIfCached, completion: completion)
        createBlurView()
    }
    
    // MARK: - Blur Management
    
    func createBlurView() {
        if let img = self.image {
            let frame = self.bounds
            blurView = DynamicBlurView(frame: frame)
            blurRadius = img.size.width / 5
            blurView.blurRadius = blurRadius
        } else {
            print("No image!")
            let frame = self.bounds
            blurView = DynamicBlurView(frame: frame)
            blurRadius = frame.width / 5
            blurView.blurRadius = blurRadius
        }

        doubleTapRecognizer.delegate = self
        doubleTapRecognizer.numberOfTapsRequired = 2 // two taps
        doubleTapRecognizer.numberOfTouchesRequired = 1 // with one finger
        if #available(iOS 9.2, *) {
            doubleTapRecognizer.requiresExclusiveTouchType = true
        }
        doubleTapRecognizer.cancelsTouchesInView = true
        doubleTapRecognizer.delaysTouchesBegan = true
        doubleTapRecognizer.delaysTouchesEnded = true
        doubleTapRecognizer.addTarget(self, action: #selector(doubleTapped))
        self.addGestureRecognizer(doubleTapRecognizer)
        self.awakeFromNib()
    }

    @objc private func doubleTapped() {
        if isBlurred { unBlur(true) } else { blur(true) }
    }
  
    /// Blurs the displayed image
    func blur(_ animated: Bool) {
        guard !isBlurred else { return } // if image is already blurred don't do anything
        if animated {
            blurView.blurRadius = 0
            self.addSubview(blurView)
            UIView.animate(withDuration: blurDelay) {
                self.blurView.blurRadius = self.blurRadius
            }
        } else {
            self.addSubview(blurView)
        }
        isBlurred = true
    }
    
    func unBlur(_ animated: Bool) {
        guard isBlurred else { return }
        blurView.blurRadius = blurRadius
        if animated {
            UIView.animate(withDuration: blurDelay) {
                self.blurView.blurRadius = 0
            }
            Dispatch.delay(blurDelay * 2) {
                if self.subviews.count > 0 { // if there are still subviews, remove them
                    for sv in self.subviews {
                        UIView.animate(withDuration: self.blurDelay) {
                            sv.removeFromSuperview()
                        }
                    }
                }
                self.blurView.removeFromSuperview()
            }
        } else {
            blurView.removeFromSuperview()
            if self.subviews.count > 0 { // if there are still subviews, remove them
                for sv in self.subviews {
                    sv.removeFromSuperview()
                }
            }
        }
        isBlurred = false
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        if AppSettings.sfwModeEnabled {
            blur(false)
        } else {
            unBlur(false)
        }
        self.blurView.refresh()
    }
    
}
