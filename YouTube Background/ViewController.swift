//
//  ViewController.swift
//  YouTube Background
//
//  Created by paul on 2024/9/5.
//

import UIKit
import AVKit
import MediaPlayer

class ViewController: UIViewController {
    static let appGroupId = "group.com.paul90317.YouTube-Background"
    override func viewDidLoad() {
        super.viewDidLoad()
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        }catch{
            print("can't play the music")
        }
        
        // 激活遠程控制
        UIApplication.shared.beginReceivingRemoteControlEvents()
        self.becomeFirstResponder()  // 讓當前視圖成為第一響應者
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
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
    
    func downloadImage(videoId: String) async throws -> Data {
        let link = "https://i.ytimg.com/vi/\(videoId)/mqdefault.jpg"
        guard let url = URL(string: link) else {
            throw URLError(.badServerResponse)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }
    
    private func play(videoId : String) {
        Task {
            let (title, audioUrl) = try await fetchVideoInfo(id: videoId)
            guard let url = URL(string: audioUrl) else {
                print("unvalid URL")
                return
            }
            
            let asset = AVAsset(url: url)
            let duration = CMTimeGetSeconds(try await asset.load(.duration)) / 2
            
            // 创建播放器
            let playerItem = AVPlayerItem(asset: asset)
            playerItem.forwardPlaybackEndTime = CMTime(seconds: duration, preferredTimescale: 600)
            
            // Set metadata for the player item
            let titleMetadata = AVMutableMetadataItem()
            titleMetadata.key = AVMetadataKey.commonKeyTitle as NSString
            titleMetadata.keySpace = .common
            titleMetadata.value = title as NSString
            
            let data = try await downloadImage(videoId: videoId)
            let artworkMetadata = AVMutableMetadataItem()
            artworkMetadata.key = AVMetadataKey.commonKeyArtwork as NSString
            artworkMetadata.keySpace = .common
            artworkMetadata.value = data as NSData
            
            playerItem.externalMetadata = [titleMetadata, artworkMetadata]
            
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

