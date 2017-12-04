//
//  ProcessingViewController.swift
//  PINRemoteImage.tvOSExample
//
//  Created by Isaac Overacker on 2/6/16.
//
//

import UIKit
import PINRemoteImage

class ProcessingViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        if let url = URL(string: "https://i.pinimg.com/1200x/2e/0c/c5/2e0cc5d86e7b7cd42af225c29f21c37f.jpg") {
            imageView.pin_setImage(from: url,
                processorKey: "rounded",
                processor: { (result, cost) -> UIImage? in
                    if let image = result.image {
                        let radius = CGFloat(7.0)
                        let targetSize = CGSize(width: 200, height: 300)
                        let imageRect = CGRect(x: 0, y: 0, width: targetSize.width, height: targetSize.height)
                        UIGraphicsBeginImageContext(imageRect.size)
                        let bezierPath = UIBezierPath(roundedRect: imageRect, cornerRadius: radius)
                        bezierPath.addClip()

                        let widthMultiplier = CGFloat(targetSize.width / image.size.width)
                        let heightMultiplier = CGFloat(targetSize.height / image.size.height)
                        let sizeMultiplier = max(widthMultiplier, heightMultiplier)

                        var drawRect = CGRect(x: 0, y: 0, width: image.size.width * sizeMultiplier, height: image.size.height * sizeMultiplier)
                        if drawRect.maxX > imageRect.maxX {
                            drawRect.origin.x -= (drawRect.maxX - imageRect.maxX) / 2.0
                        }
                        if drawRect.maxY > imageRect.maxY {
                            drawRect.origin.y -= (drawRect.maxY - imageRect.maxY) / 2.0
                        }

                        image.draw(in: drawRect)

                        UIColor.red.setStroke()
                        bezierPath.lineWidth = 5.0
                        bezierPath.stroke()

                        let ctx = UIGraphicsGetCurrentContext()!
                        ctx.setBlendMode(.overlay)
                        ctx.setAlpha(0.5)

                        if let logo = UIImage(named: "white-pinterest-logo") {
                            ctx.scaleBy(x: 1.0, y: -1.0)
                            ctx.translateBy(x: 0.0, y: -drawRect.size.height)
                            logo.draw(in: CGRect(x: 0, y: 0, width: logo.size.width, height: logo.size.height))
                        }

                        let processedImage = UIGraphicsGetImageFromCurrentImageContext()
                        UIGraphicsEndImageContext()
                        return processedImage
                    }

                    return nil
            })
        }
    }
}
