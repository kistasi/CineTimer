//
//  Item.swift
//  CineTimer
//
//  Created by tasi on 2026. 06. 09..
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
