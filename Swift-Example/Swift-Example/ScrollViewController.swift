//
//  ScrollViewController.swift
//  Swift-Example
//
//  Created by Marius Landwehr on 23.01.16.
//  Copyright © 2016 Marius Landwehr. All rights reserved.
//

import UIKit
import PINRemoteImage
import PINCache

struct Kitten {
    
    let imageUrl : URL
    let size : CGSize
    var dominantColor : UIColor?
    
    init(urlString : String, size : CGSize) {
        self.imageUrl = URL(string: urlString)!
        self.size = size
    }
}

class PinImageCell : UICollectionViewCell {
    
    let imageView : UIImageView
    
    override init(frame: CGRect) {
        imageView = UIImageView()
        
        super.init(frame: frame)
        
        imageView.translatesAutoresizingMaskIntoConstraints = false
        contentView.addSubview(imageView)
        
        let view = ["imageView" : imageView]
        
        let constraintsH = NSLayoutConstraint.constraints(withVisualFormat: "H:|-0-[imageView]-0-|", options: [], metrics: nil, views: view)
        let constraintsV = NSLayoutConstraint.constraints(withVisualFormat: "V:|-0-[imageView]-0-|", options: [], metrics: nil, views: view)
        contentView.addConstraints(constraintsH)
        contentView.addConstraints(constraintsV)
        
        layer.cornerRadius = 7
        layer.masksToBounds = true
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
    }
}

class ScrollViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    let kittens = [
        Kitten(urlString: "https://s-media-cache-ak0.pinimg.com/736x/92/5d/5a/925d5ac74db0dcfabc238e1686e31d16.jpg", size: CGSize(width: 503, height: 992)),
        Kitten(urlString: "https://s-media-cache-ak0.pinimg.com/736x/ff/b3/ae/ffb3ae40533b7f9463cf1c04d7ab69d1.jpg", size: CGSize(width: 500, height: 337)),
        Kitten(urlString: "https://s-media-cache-ak0.pinimg.com/736x/e4/b7/7c/e4b77ca06e1d4a401b1a49d7fadd90d9.jpg", size: CGSize(width: 522, height: 695)),
        Kitten(urlString: "https://s-media-cache-ak0.pinimg.com/736x/46/e1/59/46e159d76b167ed9211d662f95e7bf6f.jpg", size: CGSize(width: 557, height: 749)),
        Kitten(urlString: "https://s-media-cache-ak0.pinimg.com/736x/7a/72/77/7a72779329942c06f888c148eb8d7e34.jpg", size: CGSize(width: 710, height: 1069)),
        Kitten(urlString: "https://s-media-cache-ak0.pinimg.com/736x/60/21/8f/60218ff43257fb3b6d7c5b888f74a5bf.jpg", size: CGSize(width: 522, height: 676)),
        Kitten(urlString: "https://s-media-cache-ak0.pinimg.com/736x/90/e8/e4/90e8e47d53e71e0d97691dd13a5617fb.jpg", size: CGSize(width: 500, height: 688)),
        Kitten(urlString: "https://s-media-cache-ak0.pinimg.com/736x/96/ae/31/96ae31fbc52d96dd3308d2754a6ca37e.jpg", size: CGSize(width: 377, height: 700)),
        Kitten(urlString: "https://s-media-cache-ak0.pinimg.com/736x/9b/7b/99/9b7b99ff63be31bba8f9863724b3ebbc.jpg", size: CGSize(width: 334, height: 494)),
        Kitten(urlString: "https://s-media-cache-ak0.pinimg.com/736x/80/23/51/802351d953dd2a8b232d0da1c7ca6880.jpg", size: CGSize(width: 625, height: 469)),
        Kitten(urlString: "https://s-media-cache-ak0.pinimg.com/736x/f5/c4/f0/f5c4f04fa2686338dc3b08420d198484.jpg", size: CGSize(width: 625, height: 833)),
        Kitten(urlString: "https://s-media-cache-ak0.pinimg.com/736x/2b/06/4f/2b064f3e0af984a556ac94b251ff7060.jpg", size: CGSize(width: 625, height: 469)),
        Kitten(urlString: "https://s-media-cache-ak0.pinimg.com/736x/17/1f/c0/171fc02398143269d8a507a15563166a.jpg", size: CGSize(width: 625, height: 469)),
        Kitten(urlString: "https://s-media-cache-ak0.pinimg.com/736x/8a/35/33/8a35338bbf67c86a198ba2dd926edd82.jpg", size: CGSize(width: 625, height: 791)),
        Kitten(urlString: "https://s-media-cache-ak0.pinimg.com/736x/4d/6e/3c/4d6e3cf970031116c57486e85c2a4cab.jpg", size: CGSize(width: 625, height: 833)),
        Kitten(urlString: "https://s-media-cache-ak0.pinimg.com/736x/54/25/ee/5425eeccba78731cf7be70f0b8808bd2.jpg", size: CGSize(width: 605, height: 605)),
        Kitten(urlString: "https://s-media-cache-ak0.pinimg.com/736x/04/f1/3f/04f13fdb7580dcbe8c4d6b7d5a0a5ec2.jpg", size: CGSize(width: 504, height: 750)),
        Kitten(urlString: "https://s-media-cache-ak0.pinimg.com/736x/dc/16/4e/dc164ed33af9d899e5ed188e642f00e9.jpg", size: CGSize(width: 500, height: 500)),
        Kitten(urlString: "https://s-media-cache-ak0.pinimg.com/736x/c1/06/13/c106132936189b6cb654671f2a2183ed.jpg", size: CGSize(width: 640, height: 640)),
        Kitten(urlString: "https://s-media-cache-ak0.pinimg.com/736x/46/43/ed/4643eda4e1be4273721a76a370b90346.jpg", size: CGSize(width: 500, height: 473)),
    ]
    
    var collectionKittens = [Kitten]()
    
    var collectionView : UICollectionView?
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        PINRemoteImageManager.shared().cache.removeAllObjects()
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        PINRemoteImageManager.shared().cache.removeAllObjects()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView?.register(PinImageCell.self, forCellWithReuseIdentifier: String(describing: PinImageCell.self))
        collectionView?.delegate = self
        collectionView?.dataSource = self
        
        if let cView = collectionView {
            view.addSubview(cView)
        }
        
        createRandomKittens()
    }
    
    func createRandomKittens() {
        let dispatchGroup = DispatchGroup()
        if let bounds = collectionView?.bounds {
            var tmpKittens = [Kitten]()
            let scale = UIScreen.main.scale
            
            DispatchQueue.global(qos: DispatchQoS.QoSClass.default).async(group: dispatchGroup) { () -> Void in
            
                for _ in 1...500 {
                    let randGreen : CGFloat = CGFloat(drand48())
                    let randBlue : CGFloat = CGFloat(drand48())
                    let randRed : CGFloat = CGFloat(drand48())
                    
                    let randomColor = UIColor(red: randRed, green: randGreen, blue: randBlue, alpha: 1)
                    let kittenIndex : Int = Int(arc4random() % 20)
                    let randKitten = self.kittens[kittenIndex]
                    
                    var width = randKitten.size.width
                    var height = randKitten.size.height
                    
                    if width > (bounds.size.width) {
                        height = bounds.size.height / scale / width * height
                        width = bounds.size.width / scale / height * width
                    }
                    
                    var newKitten = Kitten(urlString: randKitten.imageUrl.absoluteString, size: CGSize(width: width, height: height))
                    newKitten.dominantColor = randomColor
                    
                    DispatchQueue.main.sync(execute: { () -> Void in
                        tmpKittens.append(newKitten)
                    })
                }
            }
            
            dispatchGroup.notify(queue: DispatchQueue.main, execute: { () -> Void in
                self.collectionKittens += tmpKittens
                self.collectionView?.reloadData()
            })
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let kitten = collectionKittens[indexPath.row]
        return kitten.size
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: String(describing: PinImageCell.self), for: indexPath)
        
        if let pinCell = cell as? PinImageCell {
            
            let kitten = collectionKittens[indexPath.row]
            pinCell.backgroundColor = kitten.dominantColor
            pinCell.alpha = 0
            
            weak var weakPinCell = pinCell
            
            pinCell.imageView.pin_setImage(from: kitten.imageUrl, completion: { (result) in
                if result.requestDuration > 0.25 {
                    UIView.animate(withDuration: 0.3, animations: { 
                        weakPinCell?.alpha = 1
                    })
                } else {
                    weakPinCell?.alpha = 1
                }
            })
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return collectionKittens.count
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
}
