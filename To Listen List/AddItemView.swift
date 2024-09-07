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
    @State var videoId = "unknown"

    var body: some View {
        VStack {
            TextField("Link", text: $videoId)
            Button(action: addItem) {
                Text("Create")
            }
        }
    }
    
    private func addItem() {
        withAnimation {
            if let last = items.last {
                let newItem = Item(index: last.index + 1, videoId: videoId)
                modelContext.insert(newItem)
            } else {
                let newItem = Item(index: 0, videoId: videoId)
                modelContext.insert(newItem)
            }
            dismiss()
        }
    }
}
