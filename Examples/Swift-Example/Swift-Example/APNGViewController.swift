//
//  APNGViewController.swift
//  Swift-Example
//
//  Created by Garrett Moon on 4/24/18.
//  Copyright © 2018 Marius Landwehr. All rights reserved.
//

import UIKit
import PINRemoteImage

class APNGViewController: UIViewController {
    
    @IBOutlet weak var imageView: PINAnimatedImageView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        imageView.pin_setImage(from: URL(string: "https://upload.wikimedia.org/wikipedia/commons/1/14/Animated_PNG_example_bouncing_beach_ball.png"))
    }
}
