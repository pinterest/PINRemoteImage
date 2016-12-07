//
//  DegradedViewController.swift
//  Swift-Example
//
//  Created by Marius Landwehr on 23.01.16.
//  Copyright © 2016 Marius Landwehr. All rights reserved.
//

import UIKit
import PINRemoteImage

class DegradedViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        PINRemoteImageManager.shared().setShouldUpgradeLowQualityImages(true, completion: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        imageView.pin_setImage(from: [
            URL(string: "https://placekitten.com/101/101")!,
            URL(string: "https://placekitten.com/401/401")!,
            URL(string: "https://placekitten.com/801/801")!])
    }
}
