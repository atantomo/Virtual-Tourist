//
//  PlaceholderView.swift
//  Virtual Tourist
//
//  Created by Andrew Tantomo on 2016/03/10.
//  Copyright © 2016年 Andrew Tantomo. All rights reserved.
//

import UIKit

class PlaceholderView: UIView {

    override init(frame: CGRect) {

        super.init(frame: frame)
        setupBlockerView()
    }

    required init?(coder aDecoder: NSCoder) {

        super.init(coder: aDecoder)!
        setupBlockerView()
    }

    func setupBlockerView() {

        let backgroundShade = UIView()
        backgroundShade.frame = frame
        backgroundShade.backgroundColor = UIColor.lightGrayColor()
        addSubview(backgroundShade)

        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
        activityIndicator.center = center
        addSubview(activityIndicator)
        
        activityIndicator.startAnimating()
    }
    
}
