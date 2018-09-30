//
//  ViewController.swift
//  BrooklynTestApp
//
//  Created by William Savary on 2018-09-24.
//  Copyright © 2018 William Savary. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIHeadGazeViewController {
    
    lazy var testButton: UIHoverableButton = {
        let button = UIHoverableButton()
        button.backgroundColor = .green
        button.layer.cornerRadius = button.frame.height / 2
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(testButtonAction), for: .touchUpInside)
        button.setTitle("Test", for: .normal)
        return button
    }()
    
    @objc func testButtonAction() {
        print("Button Pressed")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupVC()
    }
    
    private func setupVC() {
        view.addSubview(testButton)
        testButton.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        testButton.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
        testButton.widthAnchor.constraint(equalToConstant: 100)
        testButton.heightAnchor.constraint(equalToConstant: 50)
        
    }


}

