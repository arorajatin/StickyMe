//
//  ViewController.swift
//  StickeyMe
//
//  Created by Jatin Arora on 26/02/16.
//  Copyright © 2016 Jatin Arora. All rights reserved.
//

import UIKit
import MobileCoreServices
import MessageUI

extension ViewController : UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        
        self.dismissViewControllerAnimated(true, completion: {
            
            self.performSegueWithIdentifier(self.processingSegue, sender : image)
            
        })
        
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
}

extension ViewController : SMImageSelectionViewControllerDelegate {
    
    func imageSelectionVCDidCancel(vc: UIViewController) {
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imageSelectionVCDidFinishProcessingImages(vc: UIViewController, processedImages: Array<UIImage>) {
        
        stickies = stickies + SMImageFetcher.storeImagesInBaseFolder(processedImages)
        
        UIView.animateWithDuration(1.0) {
            self.collectionView.reloadData()
            self.showEmptyLabelIfNeeded()
        }
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}


extension ViewController : UICollectionViewDelegate {
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        selectedIndexPath = indexPath
        self.performSegueWithIdentifier(self.imageViewerSegue, sender : nil)
    }
    
}

extension ViewController : UICollectionViewDataSource {
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return stickies.count
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! DNCollectionViewCell
        
        let image = stickies[indexPath.row].image
        
        cell.imageView.image = image
        
        if imagesToDelete == nil || !(imagesToDelete!.contains(image))  {
            cell.checkmarkOverlay.hidden = true
        } else {
            cell.checkmarkOverlay.hidden = false
        }
        
        return cell
        
    }
    
}

extension ViewController : MFMailComposeViewControllerDelegate {
    
    func mailComposeController(controller: MFMailComposeViewController, didFinishWithResult result: MFMailComposeResult, error: NSError?) {
        
        dismissViewControllerAnimated(true, completion: {
            if result == MFMailComposeResultSent {
                
                let hud = MBProgressHUD.showHUDAddedTo(self.collectionView, animated: true)
                hud.mode = MBProgressHUDModeText
                hud.labelText = "Email Sent!"
                hud.show(false)
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), {
                    hud.hide(true)
                })
            }
        })
        
        
    }
    
}

class ViewController: UIViewController {
    
    //MARK: Properties
    
    enum ImagePickerMode : Int {
        
        case Camera
        case Gallery
    }

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    let reuseIdentifier = "DNCollectionViewCell"
    let processingSegue = "ProcessingSegue"
    let imageViewerSegue = "ImageViewerSegue"
    
    var stickies = [SMImageObject]()
    
    var imagesToDelete : [UIImage]?
    var selectedIndexPath: NSIndexPath?
    
    var longPressInProgress: Bool = false
    var longPressedIndexPath : NSIndexPath?
    
    @IBOutlet weak var addButton: UIBarButtonItem!
    @IBOutlet weak var emptyLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //Test code with test stickey image
//        let initialImage = UIImage(named: "Test_Stickey.jpg")
//        stickies = CVWrapper.detectedMultipleStickeyImages(initialImage, tolerance: 0.5, threshold: 1, levels: 1, accuracy: 1)
        
        if let imagesFromDisk = SMImageFetcher.loadImagesFromBaseFolder() {
            stickies = imagesFromDisk
        }
        
        let longPressGestureRecogniser = UILongPressGestureRecognizer.init(target: self, action: #selector(longPressedInCollectionView(_:)))
        collectionView.addGestureRecognizer(longPressGestureRecogniser)
        
        collectionView.delegate = self
        collectionView.dataSource = self
        
        let screenWidth = UIScreen.mainScreen().bounds.size.width - 10
        flowLayout.itemSize = CGSize(width: screenWidth/2, height: screenWidth/2)
        
        emptyLabel.text = "Start by taking photo of multiple Sticky Notes in Landscape Mode. \n Press + to Start "
        
        showEmptyLabelIfNeeded()
    }
    
    func longPressedInCollectionView (sender : UILongPressGestureRecognizer) {
        
        let location = sender.locationInView(collectionView)
        let indexPath = collectionView.indexPathForItemAtPoint(location)
        
        if indexPath != nil {
            let cell = collectionView.cellForItemAtIndexPath(indexPath!) as! DNCollectionViewCell
            cell.checkmarkOverlay.hidden = false
            longPressInProgress = true
            longPressedIndexPath = indexPath
            
            func longPressDismissed () {
                self.longPressedIndexPath = nil
                self.longPressInProgress = false
                
                UIView.animateWithDuration(1.0, animations: {
                    self.collectionView.reloadData()
                    self.showEmptyLabelIfNeeded()
                })
                
            }
            
            let alertController = UIAlertController(title: "Options", message: "", preferredStyle: UIAlertControllerStyle.ActionSheet)
            
            let cancelAction = UIAlertAction.init(title: "Cancel", style: UIAlertActionStyle.Cancel) { (action) -> Void in
                longPressDismissed()
            }
            
            let deleteAction = UIAlertAction.init(title: "Delete Note", style: .Default) { (action) -> Void in
                let index = (self.longPressedIndexPath?.row)!
                
                //Delete the image from the disk
                SMImageFetcher.deleteImageWithName(self.stickies[index].timestamp)
                
                //Remove the image from data source
                self.stickies.removeAtIndex(index)
                
                longPressDismissed()
            }
            
            let emailNoteAction = UIAlertAction.init(title: "Email Note", style: .Default, handler: { (action) in
                
                let index = (self.longPressedIndexPath?.row)!
                let image = self.stickies[index].image
                
                let mailComposer = MFMailComposeViewController.init()
                mailComposer.setSubject("StickyMe Note")
                mailComposer.addAttachmentData(UIImagePNGRepresentation(image)!, mimeType: "image/png", fileName: "Sticky Note")
                mailComposer.mailComposeDelegate = self
                
                self.presentViewController(mailComposer, animated: true, completion: nil)
                
                longPressDismissed()
            })
            
            let saveNoteToGalleryAction = UIAlertAction.init(title: "Save Image", style: .Default, handler: { (action) in
                
                let index = (self.longPressedIndexPath?.row)!
                let image = self.stickies[index].image
                
                UIImageWriteToSavedPhotosAlbum(image, self, #selector(self.imageSaved(_:didFinishSavingWithError:contextInfo:)), nil)
                
                longPressDismissed()
            })
            
            alertController.addAction(deleteAction)
            alertController.addAction(emailNoteAction)
            alertController.addAction(saveNoteToGalleryAction)
            alertController.addAction(cancelAction)
            
            
            presentViewController(alertController, animated: true, completion: nil)
            
        }
        
    }
    
    @IBAction func addButtonPressed(sender: AnyObject) {
        
        let alertController = UIAlertController(title: "New Sticky Note Image", message: "", preferredStyle: UIAlertControllerStyle.ActionSheet)
        
        let cancelAction = UIAlertAction.init(title: "Cancel", style: UIAlertActionStyle.Cancel, handler:nil)
        
        let cameraAction = UIAlertAction.init(title: "Camera", style: UIAlertActionStyle.Default) { (action) -> Void in
            
            self.showImagePickerWithMode(ImagePickerMode.Camera)
        }
        
        let galleryAction = UIAlertAction.init(title: "Gallery", style: UIAlertActionStyle.Default) { (action) -> Void in
            
            self.showImagePickerWithMode(ImagePickerMode.Gallery)
        }

        alertController.addAction(cameraAction)
        alertController.addAction(galleryAction)
        alertController.addAction(cancelAction)
        
        presentViewController(alertController, animated: true, completion: nil)
    }
    
    func showImagePickerWithMode(mode : ImagePickerMode) {
        
        if UIImagePickerController.isSourceTypeAvailable(UIImagePickerControllerSourceType.Camera) {
            
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.mediaTypes = [kUTTypeImage as String]
            
            if mode == .Camera {
                
                imagePicker.sourceType = .Camera
                
            } else if mode == .Gallery {
                
                imagePicker.sourceType = .PhotoLibrary
                
            }
            
            presentViewController(imagePicker, animated: true, completion: nil)

        } else {
            
            let imagePicker = UIImagePickerController()
            imagePicker.delegate = self
            imagePicker.mediaTypes = [kUTTypeImage as String]
            
            if mode == .Gallery {
                
                imagePicker.sourceType = .PhotoLibrary
                
            }
            
            presentViewController(imagePicker, animated: true, completion: nil)
            
        }
        
    }
    
    //MARK: Segues
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == self.processingSegue {
            let destinationNavVC = segue.destinationViewController as! UINavigationController
            let destinationVc = destinationNavVC.topViewController as! SMImageSelectionViewController
            let image = sender as! UIImage
            destinationVc.selectionDelegate = self
            destinationVc.image = image
        } else if segue.identifier == self.imageViewerSegue {
            let destinationVc = segue.destinationViewController as! SMImageViewController
            
            destinationVc.image = stickies[selectedIndexPath!.row].image
        }
        
    }
    
    func showEmptyLabelIfNeeded() {
        
        emptyLabel.hidden = stickies.count > 0 ? true : false
        
    }
    
    func imageSaved(image: UIImage!, didFinishSavingWithError error: NSError?, contextInfo: AnyObject?) {
        
        let completionHUD = MBProgressHUD.showHUDAddedTo(view, animated: true)
        completionHUD.mode = MBProgressHUDModeText
        
        
        if (error == nil) {
            
            completionHUD.labelText = "Image Saved"
            
        } else {
            completionHUD.labelText = "Image Save Failed"
        }
        
        completionHUD.show(true)
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
            MBProgressHUD.hideAllHUDsForView(self.view, animated: true)
        }
    }
}

