//
//  ViewController.swift
//  YouTube Background
//
//  Created by paul on 2024/9/5.
//

import UIKit
import AVKit

class ViewController: UIViewController {
    @IBOutlet weak var audio_id: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        }catch{
            print("can't play the music")
        }
    }
    
    @IBAction func paly(_ sender: Any) {
        
        guard let text = audio_id.text, let url = URL(string: text) else {
            print("unvalid URL")
            return
        }
        
        let asset = AVAsset(url: url)
        
        Task {  
            do {
                // 使用新的 async/await 加载属性
                try await asset.load(.duration)
                
                let duration = CMTimeGetSeconds(asset.duration) / 2
                
                // 创建播放器
                let playerItem = AVPlayerItem(asset: asset)
                playerItem.forwardPlaybackEndTime = CMTime(seconds: duration, preferredTimescale: 600)
                
                let player = AVPlayer(playerItem: playerItem)
                
                // 创建播放器控制器
                let playerViewController = AVPlayerViewController()
                playerViewController.player = player
                
                // 显示播放器并开始播放
                self.present(playerViewController, animated: true) {
                    player.play()
                }
            } catch {
                print("Failed to load duration: \(error)")
            }
        }
        
    }
}

