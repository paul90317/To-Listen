//
//  ContentView.swift
//  To Listen List
//
//  Created by paul on 2024/9/7.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Query(sort: \Item.order) private var diskItems: [Item]
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.modelContext) private var modelContext
    
    @State private var items: [Item] = []
    @State private var addShow = false
    @State private var clear = false
    var body: some View {
        NavigationView {
            List {
                ForEach(Array(items.enumerated()), id:\.offset) { index, item in
                    NavigationLink {
                        MusicPlayer(items: $items, trackId: index)
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
                        clear = true
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
            .sheet(isPresented: $addShow) {
                ItemAdder(items: $items)
                    .presentationDetents([.medium])
            }
            .confirmationDialog("Clear all songs?", isPresented: $clear) {
                Button("Confirm") {
                    withAnimation {
                        items = []
                    }
                }
            } message: {
                Text("Are you sure you want to clear all songs? This action cannot be undone.")
            }
            .onAppear {
                items = diskItems
                for item in items {
                    print(item.order, item.title)
                }
                
            }
            .onChange(of: scenePhase) { newScenePhase in
                if newScenePhase == .inactive {
                    saveItemsToDisk()
                }
            }
        }
    }
    
    private func moveItems(from source: IndexSet, to destination: Int) {
        withAnimation {
            items.move(fromOffsets: source, toOffset: destination)
        }
    }
    
    private func saveItemsToDisk() {
        for diskItem in diskItems {
            modelContext.delete(diskItem)
        }
        try! modelContext.save()
        
        for (i, item) in items.enumerated() {
            item.order = i
            modelContext.insert(item)
        }
        
        try! modelContext.save()
        print("saved")
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            items.remove(atOffsets: offsets)
        }
    }
}

/* #Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}*/
