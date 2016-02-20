//
//  ProcessingViewController.swift
//  Swift-Example
//
//  Created by Marius Landwehr on 23.01.16.
//  Copyright © 2016 Marius Landwehr. All rights reserved.
//

import UIKit
import PINRemoteImage

class ProcessingViewController: UIViewController {

    @IBOutlet weak var imageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        imageView.pin_setImageFromURL(NSURL(string: "https://s-media-cache-ak0.pinimg.com/736x/5b/c6/c5/5bc6c5387ff6f104fd642f2b375efba3.jpg")!, processorKey: "rounded") { (result :PINRemoteImageManagerResult!, cost :UnsafeMutablePointer<UInt>) -> UIImage! in
            if let image = result.image {
                let radius : CGFloat = 7.0
                let targetSize = CGSize(width: 200, height: 300)
                let imageRect = CGRect(x: 0, y: 0, width: targetSize.width, height: targetSize.height)
                
                UIGraphicsBeginImageContext(imageRect.size)
                
                let bezierPath = UIBezierPath(roundedRect: imageRect, cornerRadius: radius)
                bezierPath.addClip()
                
                let widthMultiplier : CGFloat = targetSize.width / image.size.width
                let heightMultiplier : CGFloat = targetSize.height / image.size.height
                let sizeMultiplier = max(widthMultiplier, heightMultiplier)
                
                var drawRect = CGRect(x: 0, y: 0, width: image.size.width * sizeMultiplier, height: image.size.height * sizeMultiplier)
                if (CGRectGetMaxX(drawRect) > CGRectGetMaxX(imageRect)) {
                    drawRect.origin.x -= (CGRectGetMaxX(drawRect) - CGRectGetMaxX(imageRect)) / 2
                }
                if (CGRectGetMaxY(drawRect) > CGRectGetMaxY(imageRect)) {
                    drawRect.origin.y -= (CGRectGetMaxY(drawRect) - CGRectGetMaxY(imageRect)) / 2
                }
                
                image.drawInRect(drawRect)
                
                UIColor.redColor().setStroke()
                bezierPath.lineWidth = 5.0
                bezierPath.stroke()
                
                let ctx = UIGraphicsGetCurrentContext()
                CGContextSetBlendMode(ctx, CGBlendMode.Overlay)
                CGContextSetAlpha(ctx, 0.5)
                
                let logo = UIImage(named: "white-pinterest-logo")
                CGContextScaleCTM(ctx, 1.0, -1.0)
                CGContextTranslateCTM(ctx, 0.0, -drawRect.size.height)
                CGContextDrawImage(ctx, CGRect(x: 90, y: 10, width: logo!.size.width, height: logo!.size.height), logo!.CGImage)
                
                let processedImage = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                
                return processedImage
            } else {
                return UIImage()
            }
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
