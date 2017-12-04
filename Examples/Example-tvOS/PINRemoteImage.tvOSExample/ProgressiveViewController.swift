//
//  ProgressiveViewController.swift
//  PINRemoteImage.tvOSExample
//
//  Created by Isaac Overacker on 2/6/16.
//
//

import UIKit
import PINRemoteImage

class ProgressiveViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        imageView.pin_updateWithProgress = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if let url = URL(string: "https://i.pinimg.com/1200x/2e/0c/c5/2e0cc5d86e7b7cd42af225c29f21c37f.jpg") {
            PINRemoteImageManager.shared().setProgressThresholds([0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9], completion: nil)
            
            imageView.pin_setImage(from: url)
            
            var progress = [UIImage]()
            PINRemoteImageManager.shared().downloadImage(with: url,
                options: [],
                progressImage: { result in
                    if let image = result.image {
                        progress.append(image)
                    }
                }, completion: { result in
                    if let image = result.image {
                        progress.append(image)
                    }
            })
        }
    }

}

