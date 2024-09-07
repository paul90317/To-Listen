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
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
