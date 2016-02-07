//
//  WebPViewController.swift
//  PINRemoteImage.tvOSExample
//
//  Created by Isaac Overacker on 2/6/16.
//
//

import UIKit
import PINRemoteImage

class WebPViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        if let url = NSURL(string: "https://github.com/samdutton/simpl/blob/master/picturetype/kittens.webp") {
            imageView.pin_setImageFromURL(url)
        }
    }

}

