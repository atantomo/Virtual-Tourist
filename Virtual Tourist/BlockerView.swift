//
//  BlockerView.swift
//  On The Map
//
//  Created by Andrew Tantomo on 2016/02/20.
//  Copyright © 2016年 Andrew Tantomo. All rights reserved.
//

import UIKit

class BlockerView: UIView {

    var backgroundShade = UIView()
    var overlayWidth: CGFloat = 88

    
    override init(frame: CGRect) {

        super.init(frame: frame)
        setupBlockerView()
    }

    required init?(coder aDecoder: NSCoder) {

        super.init(coder: aDecoder)!
        setupBlockerView()
    }

    func setupBlockerView() {

        backgroundShade.frame = frame
        backgroundShade.backgroundColor = UIColor.clearColor()
        backgroundShade.alpha = 0.3
        addSubview(backgroundShade)

        let overlayFrame = CGRectMake(0, 0, overlayWidth, overlayWidth)
        let overlayView = UIView(frame: overlayFrame)
        overlayView.backgroundColor = UIColor.blackColor()
        overlayView.alpha = 0.7
        overlayView.layer.cornerRadius = 4.0
        overlayView.center = center
        addSubview(overlayView)

        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
        activityIndicator.center = CGPointMake(center.x, center.y - 8.0)
        addSubview(activityIndicator)

        let activityLabel = UILabel(frame: CGRectMake(0, 0, overlayWidth, overlayWidth))
        activityLabel.text = "Loading..."
        activityLabel.textAlignment = .Center
        activityLabel.textColor = UIColor.whiteColor()
        activityLabel.sizeToFit()

        activityLabel.center = CGPointMake(center.x, center.y + 24.0)
        addSubview(activityLabel)

        activityIndicator.startAnimating()
    }
    
}
