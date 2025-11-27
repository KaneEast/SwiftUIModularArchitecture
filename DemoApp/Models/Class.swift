//
//  Class.swift
//  KanjiDemo - Class Model
//

import Foundation
import SwiftData

@Model
public final class Class {
    public var title: String
    public var subject: String
    public var room: String
    
    // Many-to-many relationship with Student
    @Relationship(deleteRule: .nullify)
    public var students: [Student]

    // One-to-many relationship with Exam
    // Each class can have multiple exams
    @Relationship(deleteRule: .cascade)
    public var exams: [Exam]

    public var createdAt: Date

    public init(title: String, subject: String, room: String, createdAt: Date = Date()) {
        self.title = title
        self.subject = subject
        self.room = room
        self.students = []
        self.exams = []
        self.createdAt = createdAt
    }
}
