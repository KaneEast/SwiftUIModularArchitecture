//
//  Student.swift
//  KanjiDemo - Student Model
//

import Foundation
import SwiftData

@Model
public final class Student {
    public var name: String
    public var email: String
    public var grade: Int
    
    // Many-to-many relationship with Class
    @Relationship(deleteRule: .nullify, inverse: \Class.students)
    public var classes: [Class]

    // Many-to-many relationship with Exam
    @Relationship(deleteRule: .nullify)
    public var exams: [Exam]

    public var createdAt: Date

    public init(name: String, email: String, grade: Int, createdAt: Date = Date()) {
        self.name = name
        self.email = email
        self.grade = grade
        self.classes = []
        self.exams = []
        self.createdAt = createdAt
    }
}
