//
//  UIHeadGazeViewController.swift
//  BrooklynTestApp
//
//  Created by William Savary on 2018-09-26.
//  Copyright © 2018 William Savary. All rights reserved.
//

import Foundation
import ARKit

class UIHeadGazeViewController: UIHeadGazeViewControllerBase, ARSessionDelegate {
    
    private var sceneview: ARSCNView?
    
    // An instance of UIVirtualCursorView that is responsible for visualizing the gaze location on the screen with a cursor/crosshair
    public var virtualCursorView: UIVirtualCursorView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupARSceneView()
    }
    
    private func setupARSceneView() {
        let frame = super.view.frame
        
        sceneview = ARSCNView(frame: frame)
        self.view.addSubview(sceneview!)
        
        virtualCursorView = UIVirtualCursorView(frame: frame)
        self.view.addSubview(virtualCursorView!)
        
        sceneview?.delegate = self
        sceneview?.session.delegate = self
        sceneview?.isHidden = true
        
        virtualCursorView?.dataSourceHeadGaze = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
        resetTracking()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneview?.session.pause()
    }
    
    private func resetTracking() {
        guard ARFaceTrackingConfiguration.isSupported else {
            let alertController = UIAlertController(title: "iPhone X is not detected", message: "You need an iPhone X to run the example.", preferredStyle: UIAlertController.Style.alert)
            alertController.addAction(UIAlertAction(title: "Dismiss", style: .default, handler: nil))
            self.present(alertController, animated: true, completion: nil)
            fatalError("ARFaceTracking is not supported on your device!")
        }
        
        let configuration = ARFaceTrackingConfiguration()
        sceneview?.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
    
    /// AR tracking loop, the virtual cursor position is updated here
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        virtualCursorView?.update(frame: frame)
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("AR session failed")
    }
}
