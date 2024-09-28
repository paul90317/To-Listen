//
//  ContentView.swift
//  To Listen List
//
//  Created by paul on 2024/9/7.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Item.order) private var items: [Item]
    @State private var addShow = false
    var body: some View {
        NavigationView {
            List {
                ForEach(Array(items.enumerated()), id:\.offset) { index, item in
                    NavigationLink {
                        MusicPlayer(trackId: index)
                    } label: {
                        HStack {
                            if let image = UIImage(data: item.image) {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 80, height: 45)
                            }
                            
                            
                            VStack(alignment: .leading) {
                                Text(item.title)
                                    .font(.headline)
                                    .lineLimit(2)
                                    .truncationMode(.tail)
                                Text(item.artist)
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                                    .lineLimit(1)
                                    .truncationMode(.tail)
                            }
                        }
                    }
                }
                .onDelete(perform: deleteItems)
                .onMove(perform: moveItems)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        withAnimation {
                            for item in items {
                                modelContext.delete(item)
                            }
                        }
                    }) {
                        Text("Clear")
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    EditButton()
                }
                ToolbarItem {
                    Button(action: {addShow.toggle()}) {
                        Label("Add Item", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $addShow, content: {
                AddItemView()
                    .presentationDetents([.medium])
            })
        }
    }
    
    private func moveItems(from source: IndexSet, to destination: Int) {
        withAnimation {
            var reorderedItems = items
            reorderedItems.move(fromOffsets: source, toOffset: destination)
            for (i,item) in reorderedItems.enumerated() {
                item.order = i;
            }
        }
        
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(items[index])
            }
        }
    }
}

/* #Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}*/
