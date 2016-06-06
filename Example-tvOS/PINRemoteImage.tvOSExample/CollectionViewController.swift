//
//  CollectionViewController.swift
//  PINRemoteImage.tvOSExample
//
//  Created by Isaac Overacker on 2/6/16.
//
//

import UIKit
import PINRemoteImage

private let reuseIdentifier = "Cell"

class CollectionViewController: UICollectionViewController {

    let kittenURLs = [
        NSURL(string: "https://s-media-cache-ak0.pinimg.com/736x/92/5d/5a/925d5ac74db0dcfabc238e1686e31d16.jpg"),
        NSURL(string: "https://s-media-cache-ak0.pinimg.com/736x/ff/b3/ae/ffb3ae40533b7f9463cf1c04d7ab69d1.jpg"),
        NSURL(string: "https://s-media-cache-ak0.pinimg.com/736x/e4/b7/7c/e4b77ca06e1d4a401b1a49d7fadd90d9.jpg"),
        NSURL(string: "https://s-media-cache-ak0.pinimg.com/736x/46/e1/59/46e159d76b167ed9211d662f95e7bf6f.jpg"),
        NSURL(string: "https://s-media-cache-ak0.pinimg.com/736x/7a/72/77/7a72779329942c06f888c148eb8d7e34.jpg"),
        NSURL(string: "https://s-media-cache-ak0.pinimg.com/736x/60/21/8f/60218ff43257fb3b6d7c5b888f74a5bf.jpg"),
        NSURL(string: "https://s-media-cache-ak0.pinimg.com/736x/90/e8/e4/90e8e47d53e71e0d97691dd13a5617fb.jpg"),
        NSURL(string: "https://s-media-cache-ak0.pinimg.com/736x/96/ae/31/96ae31fbc52d96dd3308d2754a6ca37e.jpg"),
        NSURL(string: "https://s-media-cache-ak0.pinimg.com/736x/9b/7b/99/9b7b99ff63be31bba8f9863724b3ebbc.jpg"),
        NSURL(string: "https://s-media-cache-ak0.pinimg.com/736x/80/23/51/802351d953dd2a8b232d0da1c7ca6880.jpg"),
        NSURL(string: "https://s-media-cache-ak0.pinimg.com/736x/f5/c4/f0/f5c4f04fa2686338dc3b08420d198484.jpg"),
        NSURL(string: "https://s-media-cache-ak0.pinimg.com/736x/2b/06/4f/2b064f3e0af984a556ac94b251ff7060.jpg"),
        NSURL(string: "https://s-media-cache-ak0.pinimg.com/736x/17/1f/c0/171fc02398143269d8a507a15563166a.jpg"),
        NSURL(string: "https://s-media-cache-ak0.pinimg.com/736x/8a/35/33/8a35338bbf67c86a198ba2dd926edd82.jpg"),
        NSURL(string: "https://s-media-cache-ak0.pinimg.com/736x/4d/6e/3c/4d6e3cf970031116c57486e85c2a4cab.jpg"),
        NSURL(string: "https://s-media-cache-ak0.pinimg.com/736x/54/25/ee/5425eeccba78731cf7be70f0b8808bd2.jpg"),
        NSURL(string: "https://s-media-cache-ak0.pinimg.com/736x/04/f1/3f/04f13fdb7580dcbe8c4d6b7d5a0a5ec2.jpg"),
        NSURL(string: "https://s-media-cache-ak0.pinimg.com/736x/dc/16/4e/dc164ed33af9d899e5ed188e642f00e9.jpg"),
        NSURL(string: "https://s-media-cache-ak0.pinimg.com/736x/c1/06/13/c106132936189b6cb654671f2a2183ed.jpg"),
        NSURL(string: "https://s-media-cache-ak0.pinimg.com/736x/46/43/ed/4643eda4e1be4273721a76a370b90346.jpg")
    ]

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: UICollectionViewDataSource

    override func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }


    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return kittenURLs.count
    }

    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier(reuseIdentifier, forIndexPath: indexPath) as! CollectionViewCell
        cell.imageView.pin_setImageFromURL(kittenURLs[indexPath.row])
        return cell
    }

}
