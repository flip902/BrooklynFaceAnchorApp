//
//  UIHeadGazeEvent.swift
//  BrooklynTestApp
//
//  Created by William Savary on 2018-09-24.
//  Copyright © 2018 William Savary. All rights reserved.
//

import UIKit

enum UIHeadGazeType: Int {
    case glance
    case gaze
}

class UIHeadGaze: UITouch {
    
    // MARK: Properties
    private weak var windowHGU: UIWindow?
    private let receiverHGU: UIView
    private let typeHGU: UIHeadGazeType
    private let positionHGU: CGPoint
    private let previousPositionHGU: CGPoint
    
    /// Time when event occurred
    private var internalTimeStamp: TimeInterval
    
    /// Returns the time when the event occurred
    public var timeStamp: TimeInterval {
        return internalTimeStamp
    }
    
    override public var description: String {
        return """
        UIHeadGazeEvent: type: \(typeHGU), position in NDC: \(positionHGU), previous position in NDC: \(previousPositionHGU), receiver: \(receiverHGU), window: \(windowHGU ?? UIWindow())
        """
    }
    
    // MARK: Initializers
    convenience init(type: UIHeadGazeType, position: CGPoint, view uiView: UIView, window: UIWindow? = nil) {
        self.init(type: type, curPosition: position, prevPosition: position, view: uiView, window: window)
    }
    
    init(type: UIHeadGazeType, curPosition: CGPoint, prevPosition: CGPoint, view uiView: UIView, window: UIWindow? = nil) {
        self.typeHGU = type
        self.windowHGU = window
        self.receiverHGU = uiView
        self.positionHGU = curPosition
        self.previousPositionHGU = prevPosition
        self.internalTimeStamp = Date().timeIntervalSince1970
    }
    
    // MARK: Class Methods
    
    /// Returns the position of gaze projected on the screen measured in the coordinates of given view.
    /// - Parameter view: The view you want the location for
    /// - Returns: The position of gaze projected on the screen as a CGPoint
    override func location(in view: UIView?) -> CGPoint {
        if let v = view {
            guard let window = UIApplication.shared.keyWindow else { fatalError("UIApplication.shared.keyWindow is nil!") }
            let winPos = CGPoint(x: (self.positionHGU.x + 0.5) * window.frame.width, y: (1.0 - (self.positionHGU.y + 0.5)) * window.frame.height)
            let viewPos = v.convert(winPos, from: window)
            return viewPos
        } else {
            return self.positionHGU
        }
    }
    
    /// Returns previous position of gaze projected on the screen measured in the coordinates of given view
    /// - Parameter view: The view you want the location for
    /// - Returns: The previous position of gaze projected on the screen as a CGPoint
    override func previousLocation(in view: UIView?) -> CGPoint {
        if let v = view {
            guard let window = UIApplication.shared.keyWindow else { fatalError("UIApplication.shared.keyWindow is nil!") }
            let winPos = CGPoint(x: (self.previousPositionHGU.x + 0.5) * window.frame.width, y: (1.0 - (self.previousPositionHGU.y + 0.5)) * window.frame.height)
            let viewPos = v.convert(winPos, from: window)
            return viewPos
        } else {
            return self.previousPositionHGU
        }
    }
}

// MARK: - HeadGazeEvent Class
class UIHeadGazeEvent: UIEvent {
    public var allGazes: Set<UIHeadGaze>?
    private var internalTimeStamp: TimeInterval
    public var timeStamp: TimeInterval { return internalTimeStamp }
    init(allGazes: Set<UIHeadGaze>? = nil) {
        self.allGazes = allGazes
        self.internalTimeStamp = Date().timeIntervalSince1970
    }
}
