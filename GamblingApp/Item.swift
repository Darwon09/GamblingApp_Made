//
//  Item.swift
//  GamblingApp
//
//  Created by Darren Ich on 12/5/25.
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
