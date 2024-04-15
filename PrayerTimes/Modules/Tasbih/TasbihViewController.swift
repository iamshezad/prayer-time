//
//  TasbihViewController.swift
//  PrayerTimes
//
//  Created by Admin on 04/04/24.
//

import UIKit
import AVFoundation

class TasbihViewController: UIViewController {
    
    @IBOutlet weak var counterLabel: UILabel!
    @IBOutlet weak var soundButton: UIBarButtonItem!
    
    var audioPlayer: AVAudioPlayer?
    
    var counter = 0 {
        didSet {
            counterLabel.text = "\(counter)"
            UserDefaults.standard.set(counter, forKey: "counter")
            
            if(soundButtonId == 0){
                // Play system sound
                playSystemSound()
            }
            
            // Vibrate (optional)
            vibrate()
        }
    }
    
    var soundButtonId: Int = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Tasbih"
        
        // Load counter value from UserDefaults
        counter = UserDefaults.standard.integer(forKey: "counter")
        
        // Add tap gesture recognizer
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(tapGesture)
        
        // Add swipe gesture recognizers
        let swipeRightGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeRight))
        swipeRightGesture.direction = .right
        view.addGestureRecognizer(swipeRightGesture)
        
        let swipeLeftGesture = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipeLeft))
        swipeLeftGesture.direction = .left
        view.addGestureRecognizer(swipeLeftGesture)
        
        // Load sound file
        if let soundURL = Bundle.main.url(forResource: "piano_click", withExtension: "mp3") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            } catch {
                print("Error loading sound file: \(error.localizedDescription)")
            }
        }
    }
    
    @objc func handleTap() {
        counter += 1
    }
    
    @objc func handleSwipeRight() {
        if counter > 0{
            counter -= 1
        }
    }
    
    @objc func handleSwipeLeft() {
        counter += 1
    }
    
    func playSystemSound() {
        audioPlayer?.stop()
        audioPlayer?.currentTime = 0
        audioPlayer?.play()
    }
    
    func vibrate() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.prepare()
        generator.impactOccurred()
    }
    
    
    func showAlert() {
        let alert = UIAlertController(title: "Reset Confirmation", message: "Are you sure you want to reset?", preferredStyle: .alert)
        
        let yesAction = UIAlertAction(title: "Yes", style: .destructive) { (_) in
            self.counter = 0
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (_) in
            // Handle "Cancel" action
            print("Cancel")
        }
        
        alert.addAction(yesAction)
        alert.addAction(cancelAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    
    @IBAction func resetButtonAction(_ sender: UIButton) {
        showAlert()
    }
    
    @IBAction func soundButtonAction(_ sender: UIBarButtonItem) {
        soundButtonId = soundButtonId == 0 ? 1 : 0
        soundButton.image = UIImage(systemName: soundButtonId == 0 ? "speaker.wave.1.fill" : "speaker.slash.fill")
    }
    
    @IBAction func infoButtonAction(_ sender: UIBarButtonItem) {
    }
}
