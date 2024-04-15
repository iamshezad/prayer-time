//
//  LaunchViewController.swift
//  PrayerTimes
//
//  Created by Admin on 23/03/24.
//

import UIKit

class LaunchViewController: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.setRootViewController()
        }
    }
    
    func setRootViewController() {
        // Get the scene delegate
        guard let sceneDelegate = UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate else {
            return
        }
        
        // Create your new root view controller
        let newRootViewController = HomeNavigationController()
        
        // Set the root view controller
        // Prepare for animation
        UIView.transition(with: sceneDelegate.window!, duration: 0.5, options: .transitionCrossDissolve, animations: {
            // Set the new root view controller
            sceneDelegate.window?.rootViewController = newRootViewController
        }, completion: nil)
    }
}
