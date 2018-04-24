//
//  GIFViewController.swift
//  Swift-Example
//
//  Created by Garrett Moon on 4/24/18.
//  Copyright © 2018 Marius Landwehr. All rights reserved.
//

import UIKit
import PINRemoteImage

class GIFViewController: UIViewController {
    
    @IBOutlet weak var imageView: PINAnimatedImageView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        imageView.pin_setImage(from: URL(string: "https://i.pinimg.com/originals/f5/23/f1/f523f141646b613f78566ba964208990.gif"))
    }
}
