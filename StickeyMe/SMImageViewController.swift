//
//  SMImageViewController.swift
//  StickeyMe
//
//  Created by Jatin Arora on 09/04/16.
//  Copyright © 2016 Jatin Arora. All rights reserved.
//

import Foundation

class SMImageViewController : UIViewController {
    
    
    @IBOutlet weak var imageView: UIImageView?
    var image : UIImage?
    
    override func viewDidLoad() {
        
        imageView!.image = image
        
    }
}