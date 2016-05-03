//
//  SMImageSelectionViewController.swift
//  StickeyMe
//
//  Created by Jatin Arora on 03/04/16.
//  Copyright © 2016 Jatin Arora. All rights reserved.
//

import Foundation

//Adding class keyword limits the protocol's adoption to only classes and not structs and enums

protocol SMImageSelectionViewControllerDelegate: class {
    
    func imageSelectionVCDidFinishProcessingImages(vc: UIViewController, processedImages: Array<UIImage>)
    
    func imageSelectionVCDidCancel(vc : UIViewController)
}

class SMImageSelectionViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    var stickies: Array<UIImage>?
    var image : UIImage? = nil
    var finalImages : Array<UIImage> = []
    let reuseIdentifier = "DNCollectionViewCell"
    var selectionDelegate:SMImageSelectionViewControllerDelegate?
    
    
    @IBOutlet weak var doneButton: UIBarButtonItem!
    @IBOutlet weak var cancelButton: UIBarButtonItem!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    @IBOutlet weak var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        
        let progressHUD = MBProgressHUD.showHUDAddedTo(view, animated: true)
        progressHUD.mode = MBProgressHUDModeIndeterminate
        progressHUD.labelText = "Processing Image"
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        let screenWidth = UIScreen.mainScreen().bounds.size.width - 10
        flowLayout.itemSize = CGSize(width: screenWidth/2, height: screenWidth/2)
        
        let image = UIImage(named:"wooden.jpg")
        let imageView = UIImageView(image: image, highlightedImage: nil)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .ScaleAspectFill
        collectionView.backgroundView = imageView
        
        collectionView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[imageView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["imageView" : imageView]))
        collectionView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[imageView]|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["imageView" : imageView]))
        
    }
    
    override func viewDidAppear(animated: Bool) {
        
        super.viewDidAppear(animated)
        
        //Get different stickey notes out of the image retrieved
        
        stickies = CVWrapper.detectedMultipleStickeyImages(image, tolerance: 0.5, threshold: 1, levels: 1, accuracy: 1)
        
        UIView.animateWithDuration(0.5, animations: { 
            
            self.collectionView.hidden = false
            self.collectionView.reloadData()
            
        }) { (success) in
            
            MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
            
        }
        
    }

    
    //MARK: UICollectionViewDataSource
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if stickies != nil {
            return stickies!.count
        } else {
            return 0
        }
        
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! DNCollectionViewCell
        
        let image = stickies![indexPath.row]
        
        if stickies != nil {
            cell.imageView.image = image
        }
    
        
        if finalImages.contains(image) {
            cell.checkmarkOverlay.hidden = false
        } else {
            cell.checkmarkOverlay.hidden = true
        }
        
        return cell
        
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! DNCollectionViewCell
        
        let image = stickies![indexPath.row]
        
        
        if finalImages.contains(image) { //Already present in the array
            
            finalImages.removeAtIndex(finalImages.indexOf(image)!)
            cell.checkmarkOverlay.hidden = true
            
        } else {    //Not present in the array yet, add images
            
            finalImages.insert(stickies![indexPath.row], atIndex: 0)
            cell.checkmarkOverlay.hidden = false
            
        }
        
        collectionView.reloadItemsAtIndexPaths([indexPath])
        collectionView.deselectItemAtIndexPath(indexPath, animated: false)
        changeDoneButtonState()
    }
    
    func changeDoneButtonState() {
        
        UIView.animateWithDuration(0.1) {
            
            if self.finalImages.count > 0 {
                self.doneButton.enabled = true
            } else {
                self.doneButton.enabled = false
            }
        }
        
    }
    
  
    @IBAction func doneButtonPressed(sender: AnyObject) {
        
        selectionDelegate?.imageSelectionVCDidFinishProcessingImages(self, processedImages: finalImages)
        
    }
    
    
    @IBAction func cancelButtonPressed(sender: AnyObject) {
        
        //QuestionMark after delegate means optional chaining, that means the method call would go only if the delegate is non-nil
        selectionDelegate?.imageSelectionVCDidCancel(self)
        
    }
}
