//
//  CDPlayer.swift
//  To Listen List
//
//  Created by paul on 2024/9/7.
//

import AVKit
import SwiftUI
import SwiftData

struct CDPlayer: View {
    @Query(sort: \Item.order) private var items: [Item]
    @State private var current_audio_id :Int = 0
    @State private var notificationHandlers: [NSObjectProtocol] = []
    @State private var player = AVPlayer()
    @State private var isPlaying :Bool = true
    @State private var KVOs: [NSKeyValueObservation] = []
    private let first_audio_id: Int
    static let resetPlayerEvent = Notification.Name("resetPlayerEvent")
    init (audio_id: Int) {
        print("player init")
        try! AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        first_audio_id = audio_id
    }
    
    var body: some View {
        if current_audio_id < items.count {
            VStack {
                if let image = UIImage(data: items[current_audio_id].image) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .padding(.horizontal)
                        .cornerRadius(10)
                        .padding(.top, 20)
                }
                
                // Song information
                VStack(alignment: .leading) {
                    Text(items[current_audio_id].title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .padding(.top, 10)
                    
                    Text(items[current_audio_id].artist)
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .padding(.top, 2)
                }
                .padding(.horizontal)
                

                // Playback controls
                HStack(spacing: 40) {
                    Button(action: {
                        current_audio_id = (current_audio_id - 1  + items.count) % items.count
                        NotificationCenter.default.post(name: CDPlayer.resetPlayerEvent, object: nil)
                    }) {
                        Image(systemName: "backward.fill")
                            .font(.largeTitle)
                    }
                    
                    Button(action: {
                        if isPlaying {
                            player.pause()
                        } else {
                            player.play()
                        }
                    }) {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.largeTitle)
                    }
                    
                    Button(action: {
                        current_audio_id = (current_audio_id + 1) % items.count
                        NotificationCenter.default.post(name: CDPlayer.resetPlayerEvent, object: nil)
                    }) {
                        Image(systemName: "forward.fill")
                            .font(.largeTitle)
                    }
                }
                .padding(.top, 30)
                
                VideoPlayer(player: player)
                    .frame(height: 0)
                    .onDisappear {
                        print("bye")
                        for handler in notificationHandlers {
                            NotificationCenter.default.removeObserver(handler)
                        }
                        notificationHandlers.removeAll()
                        for handler in KVOs {
                            handler.invalidate()
                        }
                        KVOs.removeAll()
                        
                        player.replaceCurrentItem(with: nil)
                                        }
                    .onAppear {
                        print("hi")
                        notificationHandlers.append(NotificationCenter.default.addObserver(
                            forName: CDPlayer.resetPlayerEvent,
                            object: nil,
                            queue: .main
                        ){_ in
                            print("play")
                            Task {
                                let newItem = try await getAVPlayerItem(item: items[current_audio_id])
                                player.replaceCurrentItem(with: newItem)
                                player.play()
                            }
                        })
                        notificationHandlers.append(NotificationCenter.default.addObserver(
                            forName: .AVPlayerItemDidPlayToEndTime,
                            object: nil,
                            queue: .main
                        ) { _ in
                            print("next")
                            current_audio_id = (current_audio_id + 1) % items.count
                            NotificationCenter.default.post(name: CDPlayer.resetPlayerEvent, object: nil)
                        })
                        KVOs.append(player.observe(\.rate, options: [.new]) { _, change in
                            guard let rate = change.newValue else {
                                return
                            }
                            print("change")
                            isPlaying = rate > 0
                        })
                        
                        current_audio_id = first_audio_id
                        NotificationCenter.default.post(name: CDPlayer.resetPlayerEvent, object: nil)
                    }
            }
        }
    }
}

private func getAVPlayerItem(item: Item) async throws -> AVPlayerItem {
    let asset :AVAsset!
    let duration :Double
    if let streamURL = item.streamURL, let url = URL(string: streamURL) {
        let temp = AVAsset(url: url)
        do{
            duration = CMTimeGetSeconds(try await temp.load(.duration)) / 2
            asset = temp
            print("load success")
        } catch {
            let streamURL = try await fetchStreamURL(videoId: item.videoId)
            guard let url = URL(string: streamURL) else {
                throw URLError(.badURL)
            }
            asset = AVAsset(url: url)
            duration = CMTimeGetSeconds(try await asset.load(.duration)) / 2
            item.streamURL = streamURL
        }
    } else {
        let streamURL = try await fetchStreamURL(videoId: item.videoId)
        guard let url = URL(string: streamURL) else {
            throw URLError(.badURL)
        }
        asset = AVAsset(url: url)
        duration = CMTimeGetSeconds(try await asset.load(.duration)) / 2
        item.streamURL = streamURL
    }
    
    // 创建播放器
    let playerItem = AVPlayerItem(asset: asset)
    playerItem.forwardPlaybackEndTime = CMTime(seconds: duration, preferredTimescale: 600)
    
    // Set title
    let titleMetadata = AVMutableMetadataItem()
    titleMetadata.key = AVMetadataKey.commonKeyTitle as NSString
    titleMetadata.keySpace = .common
    titleMetadata.value = item.title as NSString
    
    // Set artwork
    let artworkMetadata = AVMutableMetadataItem()
    artworkMetadata.key = AVMetadataKey.commonKeyArtwork as NSString
    artworkMetadata.keySpace = .common
    artworkMetadata.value = item.image as NSData
    
    playerItem.externalMetadata = [titleMetadata, artworkMetadata]
    
    return playerItem
}
