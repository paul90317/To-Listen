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
    @Query(sort: \Item.index) private var items: [Item]
    @State var link = ""

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
        }
    }
    
    private func downloadImage(videoId: String) async throws -> Data {
        let link = "https://i.ytimg.com/vi/\(videoId)/mqdefault.jpg"
        guard let url = URL(string: link) else {
            throw URLError(.badServerResponse)
        }
        let (data, _) = try await URLSession.shared.data(from: url)
        return data
    }
    
    private func addItem(videoId: String) {
        Task {
            if let last = items.last {
                let image = try await downloadImage(videoId: videoId)
                let newItem = Item(index: last.index + 1, videoId: videoId, title: videoId, image: image)
                withAnimation {
                    modelContext.insert(newItem)
                }
            } else {
                let image = try await downloadImage(videoId: videoId)
                let newItem = Item(index: 0, videoId: videoId, title: videoId, image: image)
                withAnimation {
                    modelContext.insert(newItem)
                }
            }
            
        }
        
    }
    
    private func addItem() {
        guard let url = URL(string: link), let components = URLComponents(url: url, resolvingAgainstBaseURL: false), let queryItems = components.queryItems else {
            print("unvalid URL")
            dismiss()
            return;
        }
        if url.host == "youtu.be" {
            addItem(videoId: String(url.path.dropFirst()))
        }
        else if url.path == "/watch", let videoId = queryItems.first(where: { $0.name == "v" })?.value {
            addItem(videoId: videoId)
        }
        dismiss()
    }
    
    private func paste() {
        if let str = UIPasteboard.general.string {
            link = str
        }
    }
}
