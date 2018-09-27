//
//  UIHeadGazeView.swift
//  BrooklynTestApp
//
//  Created by William Savary on 2018-09-25.
//  Copyright © 2018 William Savary. All rights reserved.
//

import Foundation
import ARKit

protocol UIHeadGazeViewDelegate: class {
    func update(_ uiHeadGazeView: UIHeadGazeView, didUpdate headGazes: Set<UIHeadGaze>)
}

protocol UIHeadGazeViewDataSource: class {
    func getARFaceAnchor() -> ARFaceAnchor?
}

protocol UIHeadGazeCallback where Self: UIView {
    var previousGaze: UIHeadGaze? { get set }
    func gazeBegan(_ gazes: Set<UIHeadGaze>, with event: UIHeadGazeEvent?)
    func gazeMoved(_ gazes: Set<UIHeadGaze>, with event: UIHeadGazeEvent?)
    func gazeEnded(_ gazes: Set<UIHeadGaze>, with event: UIHeadGazeEvent?)
    func gazeCancelled(_ gazes: Set<UIHeadGaze>, with event: UIHeadGazeEvent?)
}

class UIHeadGazeView: SKView, UIHeadGazeCallback {
    var previousGaze: UIHeadGaze?
    
    weak var delegateHeadGaze: UIHeadGazeViewDelegate?
    weak var dataSourceHeadGaze: UIHeadGazeViewDataSource?
    
    private var headGazeRecognizer: UIHeadGazeRecognizer?
    private var previousHeadGazePos = CGPoint(x: 0, y: 0)
    private var twoStepPrevHeadGazePos = CGPoint(x: 0, y: 0)
    var moThresholdX = CGFloat(0.01)
    var moThresholdY = CGFloat(0.01)
    var moSpeedX = CGFloat(1)
    var moSpeedY = CGFloat(1)
    var xStop = true
    var yStop = true
    var preXStop = true
    var preYStop = true
    
    override func addGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        if let recognizer = gestureRecognizer as? UIHeadGazeRecognizer {
            headGazeRecognizer = recognizer
        } else {
            fatalError("recognizer is not a UIHeadGazeRecognizer")
        }
    }
    
    /// Call this method in the ARSession loop to update the gaze location on the screen.
    /// - Parameter frame: An ARFrame objuct whose world transformation matrix would be used to derive the gaze location on the screen.
    func update(frame: ARFrame) {
        let cursorPosNDC = updateGazeNDCLocationByARFaceAnchor(frame: frame)
        if let window = UIApplication.shared.keyWindow {
            // Generate head gaze event and invoke event callback methods
            var allGazes = Set<UIHeadGaze>()
            var curGaze = UIHeadGaze(type: UIHeadGazeType.glance, position: cursorPosNDC, view: self, window: window)
            if let lastGaze = previousGaze {
                curGaze = UIHeadGaze(type: UIHeadGazeType.glance, curPosition: cursorPosNDC, prevPosition: lastGaze.location(in: nil), view: self, window: window)
            }
            
            allGazes.insert(curGaze)
            previousGaze = curGaze
            let event = UIHeadGazeEvent(allGazes: allGazes)
            self.gazeMoved(allGazes, with: event)
            headGazeRecognizer?.gazeMoved(allGazes, with: event)
            delegateHeadGaze?.update(self, didUpdate: allGazes)
        }
    }
    
    public var enableDeviceControl: Bool = false {
        didSet {
            if enableDeviceControl {
                reset()
            }
        }
    }
    
    private var frameCount: Int = 0
    private var waitIMUwarmup: Bool = true
    private var initialCameraPitch: Float = 0
    
    func reset() {
        self.frameCount = 0
        self.waitIMUwarmup = true
        self.initialCameraPitch = 0
    }
    
    /// - Returns: A Head gaze projection in 2D NDC coordinate system where the origin is at the center of the screen
    internal func updateGazeNDCLocationByARFaceAnchor(frame: ARFrame) -> CGPoint {
        let viewMtx = frame.camera.viewMatrix(for: .portrait)
        var rotCamMtx = matrix_float4x4.identity
        if enableDeviceControl {
            rotCamMtx = viewMtx.transpose
            let a = viewMtx[1][1]
            let b = viewMtx[2][1]
            if waitIMUwarmup {
                if frameCount < 10 {
                    frameCount += 1
                } else {
                    initialCameraPitch = .pi/2.0 - atan2f(a, b)
                    waitIMUwarmup = false
                }
            }
        } else {
            initialCameraPitch = 0.0
        }
        
        let worldTransMtx = getFaceTransformationMatrix()
        let oHeadCenter = simd_float4(0, 0, 0, 1)
        let oHeadLookAtDir = simd_float4(0, 0, 1, 0)
        
        let rotMtx = simd_float4x4(SCNMatrix4MakeRotation(Float(10).degreesToRadians - initialCameraPitch, 1, 0, 0))
        var tranfMtx = matrix_float4x4.identity
        
        if !self.enableDeviceControl {
            tranfMtx = viewMtx * worldTransMtx * rotMtx
        } else {
            tranfMtx = worldTransMtx * rotCamMtx * rotMtx
        }
        
        let headCenterC = tranfMtx * oHeadCenter
        var lookAtDirC = tranfMtx * oHeadLookAtDir
        let t = (0.0 - headCenterC[2]) / lookAtDirC[2]
        let hitPos = headCenterC + lookAtDirC * t
        
        let hitPosNDC = float2([Float(hitPos[0]), Float(hitPos[1])])
        let filteredPos = smoothen(pos: hitPosNDC)
        
        let worldToSKSceneScale = Float(4.0)
        let hitPosSKScene = filteredPos * worldToSKSceneScale
        return CGPoint(x: CGFloat(hitPosSKScene[0]), y: CGFloat(hitPosSKScene[1]))
    }
    
    private var cumulativeCount: Int = 0
    private var avgNDCPos2D: float2 = float2([0,0])
    private var previousNDCPos2D: float2 = float2([0,0])
    private var internalSmoothness: Float = 9.0
    
    public let maxCumulativeCount: Int = 10
    
    public var smoothness: Float {
        get { return internalSmoothness }
        set {
            internalSmoothness = max(min(newValue, Float(maxCumulativeCount)), 0)
            cumulativeCount = 0
        }
    }
    
    private func smoothen(pos: float2) -> float2 {
        if cumulativeCount <= maxCumulativeCount {
            avgNDCPos2D = (avgNDCPos2D * Float(cumulativeCount) + pos) / Float(cumulativeCount + 1)
            cumulativeCount += 1
        } else {
            let maxCount = Float(maxCumulativeCount)
            avgNDCPos2D = ((smoothness) * avgNDCPos2D + (maxCount - smoothness) * pos) / maxCount
        }
        previousNDCPos2D = avgNDCPos2D
        return avgNDCPos2D
    }
    
    private func calibratedHeadGaze(hitPosSKScene: float4) -> CGPoint {
        var headGaze = CGPoint(x: CGFloat(hitPosSKScene[0]), y: CGFloat(hitPosSKScene[1]))
        if headGaze.x < -0.43 { headGaze.x = -0.43 } // set left edge boundary
        if headGaze.x > 0.43 { headGaze.x = 0.43 } // set right edge boundary
        if headGaze.y < -0.37 { headGaze.y = -0.37 } // set bottom edge boundary
        if headGaze.y > 0.36 { headGaze.y = 0.36 } // set top edge boundary
        
        // if three consecutive headGaze.x values are too close, between the range of threshold, don't apply update headGaze.x
        xStop = abs(headGaze.x - twoStepPrevHeadGazePos.x) < moThresholdX &&
            abs(previousHeadGazePos.x - twoStepPrevHeadGazePos.x) < moThresholdX &&
            abs(headGaze.x - previousHeadGazePos.x) < moThresholdX
        
        // if three consecutive headGaze.y values are too close, between the range of threshold, don't apply update headGaze.y
        yStop = abs(headGaze.y - twoStepPrevHeadGazePos.y) < moThresholdY &&
            abs(previousHeadGazePos.y - twoStepPrevHeadGazePos.y) < moThresholdY &&
            abs(headGaze.y - previousHeadGazePos.y) < moThresholdY
        
        if xStop {
            headGaze.x = previousHeadGazePos.x
            moThresholdX = CGFloat(0.03)
        } else {
            moThresholdX = CGFloat(0.005)
        }
        if yStop {
            headGaze.y = previousHeadGazePos.y
            moThresholdY = CGFloat(0.03)
        } else {
            moThresholdY = CGFloat(0.005)
        }
        
        // accelerate headGaze's horizontal movement if 3 consecutive headGaze linear, otherwise slow down
        if (twoStepPrevHeadGazePos.x > headGaze.x &&
        previousHeadGazePos.x > headGaze.x &&
        twoStepPrevHeadGazePos.x > previousHeadGazePos.x)
        ||
        (twoStepPrevHeadGazePos.x < headGaze.x &&
        twoStepPrevHeadGazePos.x < previousHeadGazePos.x &&
        previousHeadGazePos.x < headGaze.x) {
            if moSpeedX < CGFloat(2) { moSpeedX += 0.1 }
        } else {
            if moSpeedX > CGFloat(0.5) { moSpeedX -= 0.1 }
        }
        
        // accelerate headGaze's vertical movement if 3 consecutive headGaze linear, otherwise slow down
        if (twoStepPrevHeadGazePos.y > headGaze.y &&
        previousHeadGazePos.y > headGaze.y &&
        twoStepPrevHeadGazePos.y > previousHeadGazePos.y)
        ||
        (twoStepPrevHeadGazePos.y < headGaze.y &&
        twoStepPrevHeadGazePos.y < previousHeadGazePos.y &&
        previousHeadGazePos.y < headGaze.y) {
            if moSpeedY < CGFloat(2) { moSpeedY += 0.1 }
        } else {
            if moSpeedY > CGFloat(0.5) { moSpeedY -= 0.1 }
        }
        
        // dim first step to avoid jumps if headGaze is waiting, otherwise apply acceleration
        if preXStop {
            headGaze.x = previousHeadGazePos.x + (headGaze.x - previousHeadGazePos.x) * 0.1
        } else {
            headGaze.x = previousHeadGazePos.x + (headGaze.x - previousHeadGazePos.x) * moSpeedX
        }
        
        if preYStop {
            headGaze.y = previousHeadGazePos.y + (headGaze.y - previousHeadGazePos.y) * 0.1
        } else {
            headGaze.y = previousHeadGazePos.y + (headGaze.y - previousHeadGazePos.y) * moSpeedY
        }
        
        twoStepPrevHeadGazePos = previousHeadGazePos
        previousHeadGazePos = headGaze
        preXStop = xStop
        preYStop = yStop
        return headGaze
    }
    
    /// - Returns: The world transformation matrix of the ARFaceAnchor node.
    private func getFaceTransformationMatrix() -> simd_float4x4 {
        guard let dataSource = dataSourceHeadGaze else { return simd_float4x4.identity }
        guard let faceAnchor = dataSource.getARFaceAnchor() else { return simd_float4x4.identity }
        return faceAnchor.transform
    }
    
    /// - Returns: The translation components of the ARFaceAnchor node.
    func getFaceTranslation() -> simd_float3 {
        let m = getFaceTransformationMatrix()
        return simd_float3([m[3][0], m[3][1], m[3][2]])
    }
    
    /// - Returns: The scale components of the ARFaceAnchor node.
    func getFaceScale() -> simd_float3 {
        let m = getFaceTransformationMatrix()
        let sx = simd_float3([m[0][0], m[0][1], m[0][2]])
        let sy = simd_float3([m[1][0], m[1][1], m[1][2]])
        let sz = simd_float3([m[2][0], m[2][1], m[2][2]])
        let s = simd_float3([simd_length(sx), simd_length(sy), simd_length(sz)])
        return s
    }
    
    /// - Returns: The rotation components of the ARFaceAnchor node.
    func getFaceRotationMatrix() -> simd_float4x4 {
        let scale = getFaceScale()
        let mtx = getFaceTransformationMatrix()
        var (c0, c1, c2, c3) = mtx.columns
        c3 = simd_float4(0,0,0,1)
        c0 = c0 / scale[0]
        c1 = c1 / scale[1]
        c2 = c2 / scale[2]
        return simd_float4x4(c0, c1, c2, c3)
    }
    
    // - Mark: UIHeadGaze protocol stubs
    func gazeBegan(_ gazes: Set<UIHeadGaze>, with event: UIHeadGazeEvent?) {
        fatalError("gazeBegan is not implemented!")
    }
    
    func gazeMoved(_ gazes: Set<UIHeadGaze>, with event: UIHeadGazeEvent?) {
        fatalError("gazeMoved is not implemented!")
    }
    
    func gazeEnded(_ gazes: Set<UIHeadGaze>, with event: UIHeadGazeEvent?) {
        fatalError("gazeEnded is not implemented!")
    }
    
    func gazeCancelled(_ gazes: Set<UIHeadGaze>, with event: UIHeadGazeEvent?) {
        fatalError("gazeCancelled is not implemented!")
    }
}
