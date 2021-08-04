//
//  ViewController.swift
//  Example-Xcode-SPM
//
//  Created by Petro Rovenskyy on 02.12.2020.
//

import UIKit
import PINRemoteImage

class ViewController: UIViewController {
    @IBOutlet weak var info: UILabel!
    @IBOutlet weak var imgView: PINAnimatedImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.info.text = "PINRemoteImage+SPM+Xcode=🥰"
        self.imgView.pin_updateWithProgress = true
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let imageURL = URL(string: "https://i.pinimg.com/originals/f5/23/f1/f523f141646b613f78566ba964208990.gif") else {
            return
        }
        self.imgView.pin_setImage(from: imageURL)
    }


}

