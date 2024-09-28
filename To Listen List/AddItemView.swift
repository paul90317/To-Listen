//
//  AddItemView.swift
//  To Listen List
//
//  Created by paul on 2024/9/7.
//

import SwiftUI
import SwiftData

struct AddItemView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Item.order) private var items: [Item]
    @State var link = ""
    @State private var notificationHandlers: [NSObjectProtocol] = []
    static let addItemEvent = Notification.Name("addItemEvent")
    var body: some View {
        NavigationView {
            List {
                TextField("Link", text: $link)
            }
            .toolbar{
                ToolbarItem {
                    Button(action: paste) {
                        Label("Paste", systemImage: "doc.on.clipboard")
                    }
                }
                ToolbarItem {
                    Button(action: addItem) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .onDisappear {
                print("bye 0")
                for handler in notificationHandlers {
                    NotificationCenter.default.removeObserver(handler)
                }
                notificationHandlers.removeAll()
            }
            .onAppear {
                print("hihi 0")
                notificationHandlers.append(NotificationCenter.default.addObserver(
                    forName: AddItemView.addItemEvent,
                    object: nil,
                    queue: .main
                ){notification in
                    print("hihi")
                    let userInfos = notification.userInfo!["userInfos"] as! [[String: Any]]
                    for userInfo in userInfos {
                        let videoId = userInfo["videoId"] as! String
                        let title = userInfo["title"] as! String
                        let image = userInfo["image"] as! Data
                        let author = userInfo["author"] as! String
                        if let last = items.last {
                            let newItem = Item(order: last.order + 1, videoId: videoId, title: title, image: image, author: author)
                            modelContext.insert(newItem)
                        } else {
                            let newItem = Item(order: 0, videoId: videoId, title: title, image: image, author: author)
                            modelContext.insert(newItem)
                        }
                    }
                    
                    dismiss()
                })
            }
        }
    }
    
    private func importPlaylist(playlistId: String) async throws {
        let playlist = try await fetchPlaylist(playlistId: playlistId)
        try await addItems(videoIds: playlist)
    }
    
    private func addItems(videoIds: [String]) async throws {
        var userInfos: [Any] = []
        for videoId in videoIds {
            let userInfo: [String: Any] = [
                "image": try await fetchImage(videoId: videoId),
                "title": try await fetchTitle(videoId: videoId),
                "videoId": videoId,
                "author": try await fetchAuthor(videoId: videoId)
            ]
            userInfos.append(userInfo)
        }
        NotificationCenter.default.post(name: AddItemView.addItemEvent, object: nil, userInfo: ["userInfos": userInfos])
    }
    
    private func addItem() {
        guard let url = URL(string: link), let components = URLComponents(url: url, resolvingAgainstBaseURL: false), let queryItems = components.queryItems else {
            print("unvalid URL")
            dismiss()
            return;
        }
        if url.host == "youtu.be" {
            Task {
                try await addItems(videoIds: [String(url.path.dropFirst())])
            }
        }
        else if url.path == "/watch", let videoId = queryItems.first(where: { $0.name == "v" })?.value {
            Task {
                try await addItems(videoIds: [videoId])
            }
        }
        else if url.path == "/playlist", let playlistId = queryItems.first(where: { $0.name == "list" })?.value {
            Task {
                try await importPlaylist(playlistId: playlistId)
            }
        }
    }
    
    private func paste() {
        if let str = UIPasteboard.general.string {
            link = str
        }
    }
}
