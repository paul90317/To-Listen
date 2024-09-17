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
    @Query(sort: \Item.index) private var items: [Item]
    @State private var current_audio_id :Int = 0
    @State private var notificationHandlers: [NSObjectProtocol] = []
    @State private var player = AVPlayer()
    @State private var isPlaying :Bool = true
    @State private var KVOs: [NSKeyValueObservation] = []
    private let first_audio_id: Int
    static let resetPlayerEvent = Notification.Name("resetPlayerEvent")
    init (audio_id: Int) {
        try! AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
        first_audio_id = audio_id
    }
    
    var body: some View {
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
