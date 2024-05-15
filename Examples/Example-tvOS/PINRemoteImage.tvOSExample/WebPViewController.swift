//
//  WebPViewController.swift
//  PINRemoteImage.tvOSExample
//
//  Created by Garrett Moon on 4/24/18.
//

import UIKit
import PINRemoteImage

class WebPViewController: UIViewController {
    
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        imageView.pin_setImage(from: URL(string: "https://raw.githubusercontent.com/samdutton/simpl/main/picturetype/kittens.webp"))
    }
}
