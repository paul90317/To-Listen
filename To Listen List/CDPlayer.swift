//
//  CDPlayer.swift
//  To Listen List
//
//  Created by paul on 2024/9/7.
//

import AVKit
import SwiftUI

struct CDPlayer: View {
    @State private var player = AVPlayer();
    @State private var title = "Loading ...";
    var body: some View {
        VideoPlayer(player: player)
            .navigationBarBackButtonHidden(false) // 强制显示返回按钮
            .navigationBarTitle(title)
            .navigationBarTitleDisplayMode(.automatic)
            .onAppear {
                Task {
                    try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
                    try await play()
                }
            }
            .onDisappear {
                player.pause()
            }
        }
    var videoId : String = ""
    init(videoId : String) {
        self.videoId = videoId
    }
    private func fetchVideoInfo() async throws -> (title: String, audioUrl: String){
        let url = URL(string: "https://downloader.freemake.com/api/videoinfo/\(videoId)")!
        var request = URLRequest(url: url)
        request.setValue("UA-18256617-1", forHTTPHeaderField: "x-analytics-header")

        let (data, _) = try await URLSession.shared.data(for: request)
        
        if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
           let testId = json["videoId"] as? String,
           let metaInfo = json["metaInfo"] as? [String: Any],
           let title = metaInfo["title"] as? String,
           let qualities = json["qualities"] as? [[String: Any]],
           let lastQuality = qualities.last,
           let audioUrl = lastQuality["url"] as? String {
            if videoId == testId {
                return (title, audioUrl)
            }
        }
        throw URLError(.badServerResponse)
    }
        
    private func downloadImage() async throws -> Data {
        let link = "https://i.ytimg.com/vi/\(videoId)/mqdefault.jpg"
        guard let url = URL(string: link) else {
            throw URLError(.badServerResponse)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }
    
    private func play() async throws {
        let (title, audioUrl) = try await fetchVideoInfo()
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
        
        let data = try await downloadImage()
        let artworkMetadata = AVMutableMetadataItem()
        artworkMetadata.key = AVMetadataKey.commonKeyArtwork as NSString
        artworkMetadata.keySpace = .common
        artworkMetadata.value = data as NSData
        
        playerItem.externalMetadata = [titleMetadata, artworkMetadata]
        
        // 显示播放器并开始播放
        self.title = title
        player = AVPlayer(playerItem: playerItem)
        player.play()
    }
}
