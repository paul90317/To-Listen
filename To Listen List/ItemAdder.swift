//
//  AddItemView.swift
//  To Listen List
//
//  Created by paul on 2024/9/7.
//

import SwiftUI
import SwiftData

struct ItemAdder: View {
    @Environment(\.dismiss) private var dismiss
    @Binding public var items: [Item]
    @State var link = ""
    @State var adding: Bool = false
    static let addItemEvent = Notification.Name("addItemEvent")
    var body: some View {
        NavigationView {
            List {
                if adding {
                    Text(link)
                } else {
                    TextField("Link", text: $link)
                }
            }
            .toolbar{
                if adding {
                    ToolbarItem {
                        Button(action: {dismiss()}) {
                            Text("Cancel")
                        }
                    }
                } else {
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
            }
            .onDisappear {
                adding = false
            }
        }
    }
    
    private func importPlaylist(playlistId: String) async throws {
        let playlist = try await fetchPlaylist(playlistId: playlistId)
        try await addItems(videoIds: playlist)
    }
    
    private func addItems(videoIds: [String]) async throws {
        for videoId in videoIds {
            if !adding {
                break
            }
            let image = try await fetchImage(videoId: videoId)
            let title = try await fetchTitle(videoId: videoId)
            let author = try await fetchAuthor(videoId: videoId)
            let newItem = Item(videoId: videoId, title: title, image: image, author: author)
            items.append(newItem)
        }
    }
    
    private func addItem() {
        adding = true
        guard let url = URL(string: link), let components = URLComponents(url: url, resolvingAgainstBaseURL: false), let queryItems = components.queryItems else {
            print("unvalid URL")
            dismiss()
            return;
        }
        Task {
            defer {
                dismiss()
            }
            if url.host == "youtu.be" {
                try await addItems(videoIds: [String(url.path.dropFirst())])
            }
            else if url.path == "/watch", let videoId = queryItems.first(where: { $0.name == "v" })?.value {
                try await addItems(videoIds: [videoId])
            }
            else if url.path == "/playlist", let playlistId = queryItems.first(where: { $0.name == "list" })?.value {
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
