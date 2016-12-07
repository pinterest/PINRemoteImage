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
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let url = URL(string: "https://s-media-cache-ak0.pinimg.com/736x/5b/c6/c5/5bc6c5387ff6f104fd642f2b375efba3.jpg")
        
        imageView.pin_setImage(from: url, processorKey: "rounded") { (result, unsafePointer) -> UIImage? in
            
            guard let image = result.image else { return nil }
            
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
            if (drawRect.maxX > imageRect.maxX) {
                drawRect.origin.x -= (drawRect.maxX - imageRect.maxX) / 2
            }
            if (drawRect.maxY > imageRect.maxY) {
                drawRect.origin.y -= (drawRect.maxY - imageRect.maxY) / 2
            }
            
            image.draw(in: drawRect)
            
            UIColor.red.setStroke()
            bezierPath.lineWidth = 5.0
            bezierPath.stroke()
            
            let ctx = UIGraphicsGetCurrentContext()
            ctx?.setBlendMode(CGBlendMode.overlay)
            ctx?.setAlpha(0.5)
            
            let logo = UIImage(named: "white-pinterest-logo")
            ctx?.scaleBy(x: 1.0, y: -1.0)
            ctx?.translateBy(x: 0.0, y: -drawRect.size.height)
            
            if let coreGraphicsImage = logo?.cgImage {
                ctx?.draw(coreGraphicsImage, in: CGRect(x: 90, y: 10, width: logo!.size.width, height: logo!.size.height))
            }
            
            let processedImage = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
            
            return processedImage
            
        }
    }
}
