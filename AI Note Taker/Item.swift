//
//  Item.swift
//  AI Note Taker
//
//  Created by Manohar Gadiraju on 11/26/25.
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
