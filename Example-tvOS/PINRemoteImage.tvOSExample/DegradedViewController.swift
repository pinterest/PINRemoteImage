//
//  DegradedViewController.swift
//  PINRemoteImage.tvOSExample
//
//  Created by Isaac Overacker on 2/6/16.
//
//

import UIKit
import PINRemoteImage

class DegradedViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        PINRemoteImageManager.sharedImageManager().setShouldUpgradeLowQualityImages(true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        imageView.pin_setImageFromURLs([
            NSURL(string: "https://placekitten.com/101/101")!,
            NSURL(string: "https://placekitten.com/401/401")!,
            NSURL(string: "https://placekitten.com/801/801")!
        ])
    }
}
