//
//  Item.swift
//  To Listen List
//
//  Created by paul on 2024/9/7.
//

import Foundation
import SwiftData

@Model
final class Item {
    var index: Int
    var videoId: String
    var title: String
    var streamURL: String?
    var image: Data
    init(index: Int, videoId: String, title: String, image: Data) {
        self.index = index
        self.videoId = videoId
        self.title = title
        self.image = image
    }
}
