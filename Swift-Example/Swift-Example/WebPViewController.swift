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
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        imageView.pin_setImageFromURL(NSURL(string: "https://github.com/samdutton/simpl/blob/master/picturetype/kittens.webp?raw=true")!)
    }
}
