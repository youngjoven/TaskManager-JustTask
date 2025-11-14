//
//  Task.swift
//  GmailTaskManager
//
//  Created by Claude Code
//

import Foundation

struct EmailTask: Identifiable, Codable {
    let id: String
    let title: String
    let body: String
    let sender: String
    let date: Date
    let labelName: String
    var isCompleted: Bool
    var aiSummary: String? // Gemini로 생성된 업무 요약

    init(id: String = UUID().uuidString,
         title: String,
         body: String,
         sender: String,
         date: Date,
         labelName: String,
         isCompleted: Bool = false,
         aiSummary: String? = nil) {
        self.id = id
        self.title = title
        self.body = body
        self.sender = sender
        self.date = date
        self.labelName = labelName
        self.isCompleted = isCompleted
        self.aiSummary = aiSummary
    }
}
