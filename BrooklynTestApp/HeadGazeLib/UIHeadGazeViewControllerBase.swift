//
//  UIHeadGazeViewControllerBase.swift
//  BrooklynTestApp
//
//  Created by William Savary on 2018-09-26.
//  Copyright © 2018 William Savary. All rights reserved.
//

import UIKit
import ARKit

class UIHeadGazeViewControllerBase: UIViewController, ARSCNViewDelegate, UIHeadGazeViewDataSource {
    
    private var faceAnchor: ARFaceAnchor?
    
    func getARFaceAnchor() -> ARFaceAnchor? {
        return self.faceAnchor
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        self.faceAnchor = faceAnchor
    }
    
}
