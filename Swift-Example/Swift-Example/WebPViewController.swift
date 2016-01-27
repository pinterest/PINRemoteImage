//
//  WebPViewController.swift
//  Swift-Example
//
//  Created by Marius Landwehr on 23.01.16.
//  Copyright © 2016 Marius Landwehr. All rights reserved.
//

import UIKit
import PINRemoteImage

class WebPViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        imageView.pin_setImageFromURL(NSURL(string: "http://pinterest.com/googleKitten.webp")!)
    }
}
