//
//  ProgressiveViewController.swift
//  Swift-Example
//
//  Created by Marius Landwehr on 23.01.16.
//  Copyright © 2016 Marius Landwehr. All rights reserved.
//

import UIKit
import PINRemoteImage
import PINCache

class ProgressiveViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        imageView.pin_updateWithProgress = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
       
        guard let imageURL = URL(string: "https://s-media-cache-ak0.pinimg.com/1200x/2e/0c/c5/2e0cc5d86e7b7cd42af225c29f21c37f.jpg") else {
            return
        }
        
        PINRemoteImageManager.shared().setProgressThresholds([0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9, 1.0], completion: nil)
        PINRemoteImageManager.shared().cache.removeObject(forKey: PINRemoteImageManager.shared().cacheKey(for: imageURL, processorKey: nil))
        
        imageView.pin_setImage(from: imageURL)
    }
}
