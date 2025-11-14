//
//  GmailLabel.swift
//  GmailTaskManager
//
//  Created by Claude Code
//

import Foundation

struct GmailLabel: Identifiable, Codable {
    let id: String
    let name: String
    var isSelected: Bool = false
    var latestEmailDate: Date?

    init(id: String, name: String, isSelected: Bool = false, latestEmailDate: Date? = nil) {
        self.id = id
        self.name = name
        self.isSelected = isSelected
        self.latestEmailDate = latestEmailDate
    }
}
