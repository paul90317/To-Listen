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
    init(index : Int, videoId : String) {
        self.index = index
        self.videoId = videoId
    }
}
