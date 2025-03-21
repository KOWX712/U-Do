//
//  Task.swift
//  U Do
//
//  Created by yoyojun on 24/12/2024.
//

// Task.swift
import Foundation


struct Task: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var isHighPriority: Bool
    var isVisibleInMenubar: Bool  // New property
    
    init(id: UUID = UUID(), title: String, isHighPriority: Bool = false, isVisibleInMenubar: Bool = false) {
        self.id = id
        self.title = title
        self.isHighPriority = isHighPriority
        self.isVisibleInMenubar = isVisibleInMenubar
    }
    
    static func == (lhs: Task, rhs: Task) -> Bool {
        return lhs.id == rhs.id &&
               lhs.title == rhs.title &&
               lhs.isHighPriority == rhs.isHighPriority &&
               lhs.isVisibleInMenubar == rhs.isVisibleInMenubar
    }
}
