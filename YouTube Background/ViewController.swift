//
//  ViewController.swift
//  YouTube Background
//
//  Created by paul on 2024/9/5.
//

import UIKit
import AVKit

class ViewController: UIViewController {
    static let appGroupId = "group.com.paul90317.YouTube-Background"
    @IBOutlet weak var audio_id: UITextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        }catch{
            print("can't play the music")
        }
    }
    
    private func fetchVideoInfo(id : String) async throws -> (title: String, audioUrl: String){
        let url = URL(string: "https://downloader.freemake.com/api/videoinfo/\(id)")!
        var request = URLRequest(url: url)
        request.setValue("UA-18256617-1", forHTTPHeaderField: "x-analytics-header")

        let (data, _) = try await URLSession.shared.data(for: request)
        
        if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
           let videoId = json["videoId"] as? String,
           let metaInfo = json["metaInfo"] as? [String: Any],
           let title = metaInfo["title"] as? String,
           let qualities = json["qualities"] as? [[String: Any]],
           let lastQuality = qualities.last,
           let audioUrl = lastQuality["url"] as? String {
            if videoId == id {
                return (title, audioUrl)
            }
        }
        throw URLError(.badServerResponse)
    }
    
    private func play(videoId : String) {
        Task {
            let (title, audioUrl) = try await fetchVideoInfo(id: videoId)
            guard let url = URL(string: audioUrl) else {
                print("unvalid URL")
                return
            }
            print(title)
            let asset = AVAsset(url: url)
            let duration = CMTimeGetSeconds(try await asset.load(.duration)) / 2
            
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
        }
    }
    
    @IBAction func play(_ sender: Any) {
        guard let userDefaults = UserDefaults(suiteName: ViewController.appGroupId), let videoId = userDefaults.string(forKey: "videoId") else
        {
            print("unvalid key")
            return
        }
        print(videoId)
        play(videoId: videoId)
    }
}

