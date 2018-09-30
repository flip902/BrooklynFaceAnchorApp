//
//  UIBubbleButton.swift
//  BrooklynTestApp
//
//  Created by William Savary on 2018-09-27.
//  Copyright © 2018 William Savary. All rights reserved.
//

import UIKit

class UIBubbleButton: UIHoverableButton {
    
    internal var darkFillView: UIView? = nil
    internal var button: UIButton? = nil
    
    public var darkFillColor: UIColor {
        get { return (darkFillView?.backgroundColor)! }
        set { darkFillView?.backgroundColor = newValue }
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI(frame: self.frame)
    }
    
    internal func setupUI(frame: CGRect) {
        
        let w = frame.width
        let h = frame.height
        self.clipsToBounds = true
        super.outAlpha = 0.1 // alpha of the button when it's been hovered over
        self.hoverScale = Float(max(w, h))
        
        self.layer.cornerRadius = min(w, h) / 5.0
        // TODO: - Change Button Color
        self.setTitleColor(UIColor.black, for: .normal)
        self.backgroundColor = UIColor.white
        self.alpha = 1.0
        
        let dummyFrame = CGRect(x: w/2, y: h/2, width: 1, height: 1)
        darkFillView = UIView(frame: dummyFrame)
        darkFillView?.backgroundColor = UIColor.blue
        darkFillView?.layer.cornerRadius = 0.5
        addSubview(darkFillView!)
    }
    
    /// **Overridable**. Define the animation when cursor is hovering over the button
    override func hoverAnimation() {
        self.darkFillView!.alpha = self.inAlpha
        self.darkFillView!.transform = CGAffineTransform(scaleX: CGFloat(hoverScale), y: CGFloat(hoverScale))
    }
    
    /// **Overridable**. Define the animation when cursor leaves the button
    override func deHoverAnimation() {
        self.darkFillView!.alpha = self.outAlpha
        self.darkFillView!.transform = .identity
    }
}
