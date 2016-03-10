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

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        if let url = NSURL(string: "https://s-media-cache-ak0.pinimg.com/1200x/2e/0c/c5/2e0cc5d86e7b7cd42af225c29f21c37f.jpg") {
            imageView.pin_setImageFromURL(url,
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
                        if CGRectGetMaxX(drawRect) > CGRectGetMaxX(imageRect) {
                            drawRect.origin.x -= (CGRectGetMaxX(drawRect) - CGRectGetMaxX(imageRect)) / 2.0;
                        }
                        if CGRectGetMaxY(drawRect) > CGRectGetMaxY(imageRect) {
                            drawRect.origin.y -= (CGRectGetMaxY(drawRect) - CGRectGetMaxY(imageRect)) / 2.0;
                        }

                        image.drawInRect(drawRect)

                        UIColor.redColor().setStroke()
                        bezierPath.lineWidth = 5.0
                        bezierPath.stroke()

                        let ctx = UIGraphicsGetCurrentContext();
                        CGContextSetBlendMode(ctx, .Overlay);
                        CGContextSetAlpha(ctx, 0.5);

                        if let logo = UIImage(named: "white-pinterest-logo") {
                            CGContextScaleCTM(ctx, 1.0, -1.0);
                            CGContextTranslateCTM(ctx, 0.0, -drawRect.size.height);
                            CGContextDrawImage(ctx, CGRect(x: 0, y: 0, width: logo.size.width, height: logo.size.height), logo.CGImage);
                        }

                        let processedImage = UIGraphicsGetImageFromCurrentImageContext();
                        UIGraphicsEndImageContext();
                        return processedImage;
                    }

                    return nil
            })
        }
    }
}
