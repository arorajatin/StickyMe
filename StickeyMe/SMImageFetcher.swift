//
//  SMImageFetcher.swift
//  StickeyMe
//
//  Created by Jatin Arora on 08/04/16.
//  Copyright © 2016 Jatin Arora. All rights reserved.
//

import Foundation

class SMImageFetcher {
    
    static let BASE_DOCUMENT_FOLDER_NAME : String = "Stickies"
    static let IMAGE_BASE_STRING : String = "IMG_"
    
    static func storeImagesInBaseFolder(images : Array<UIImage>) -> Array<SMImageObject> {
        
        let documentDirectoryPath = SMImageFetcher.stickiesBaseFolderPath()
        
        if !NSFileManager.defaultManager().fileExistsAtPath(documentDirectoryPath) {
            
            do {
                try NSFileManager.defaultManager().createDirectoryAtPath(documentDirectoryPath, withIntermediateDirectories: false, attributes: nil)
                
            } catch let createDirectoryError as NSError {
                print("Error with creating directory at path: \(createDirectoryError.localizedDescription)")
            }
            
        }
        
        var imageObjectsToReturn = [SMImageObject]()
        
        for (_, image) in images.enumerate() {
            
            let time = NSDate().timeIntervalSince1970
            let imageName = "\(IMAGE_BASE_STRING)\(time).png"
            
            let finalPath = documentDirectoryPath.stringByAppendingString("/\(imageName)")
            
            do {
                try UIImagePNGRepresentation(image)?.writeToFile(finalPath, options: .DataWritingAtomic)
            } catch {
                print("Error generated while storing the file at path : \(finalPath)")
            }
            
            imageObjectsToReturn.append(SMImageObject(image: image, timestamp: "\(time)"))
        }
      
        return imageObjectsToReturn
    }
    
    static func loadImagesFromBaseFolder() -> Array<SMImageObject>? {
        
        var documentDirectoryPath = SMImageFetcher.stickiesBaseFolderPath()
        documentDirectoryPath.appendContentsOf("/")
        
        let enumerator = NSFileManager.defaultManager().enumeratorAtPath(documentDirectoryPath)
        
        var images = [SMImageObject]()
        
        while let imageURL = enumerator?.nextObject()  {
            
            let finalURL = documentDirectoryPath + (imageURL as! String)
            
            let image = UIImage(contentsOfFile: finalURL)
            
            if image != nil {
                images.append(SMImageObject(image: image!, timestamp: imageURL as! String))
            }
            
        }
        
        return images
        
    }
    
    static func stickiesBaseFolderPath() -> String {
        var documentDirectoryPath: String = NSSearchPathForDirectoriesInDomains(.DocumentDirectory, .UserDomainMask, true).first!
        
        documentDirectoryPath.appendContentsOf("/")
        documentDirectoryPath.appendContentsOf(BASE_DOCUMENT_FOLDER_NAME)
        
        return documentDirectoryPath
    }
    
    static func deleteImageWithName(imageName : String) {
        
        let documentDirectoryPath = SMImageFetcher.stickiesBaseFolderPath()
        
        let finalPath = documentDirectoryPath.stringByAppendingString("/\(imageName)")
        
        do {
            try NSFileManager().removeItemAtPath(finalPath)
        } catch {
            print("Image could not be deleted from disk")
        }
        
        
    }
}