//
//  ViewController.swift
//  YouTube Background
//
//  Created by paul on 2024/9/5.
//

import UIKit
import AVFoundation

class ViewController: UIViewController {
    @IBOutlet weak var audio_id: UITextField!
    var player:AVPlayer?
    var playing:Bool = false
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    @IBAction func paly(_ sender: Any) {
        if let player = player {
            if playing {
                player.pause()
                playing = false
            } else {
                player.play()
                playing = true
            }
        } else {
            guard let text = audio_id.text, let url = URL(string: text) else {
                print("unvalid URL")
                return
            }
            do {
                try AVAudioSession.sharedInstance().setMode(.default)
                try AVAudioSession.sharedInstance().setActive(true, options: .notifyOthersOnDeactivation)
                player = AVPlayer(url: url)
                guard let player = player else {
                    print("can't visit URL")
                    return
                }
                playing = true
                player.play()
            }catch{
                print("can't play the music")
            }
        }
    }
    
    
}

