//
//  Exam.swift
//  DemoApp - Exam Model
//
//  Purpose: SwiftData model representing an exam
//  Demonstrates many-to-many relationships with Student and many-to-one with Class
//

import Foundation
import SwiftData

@Model
public final class Exam {
    public var title: String
    public var subject: String
    public var date: Date
    public var maxScore: Int

    // Many-to-many relationship with Student
    // Students can take multiple exams, exams can have multiple students
    @Relationship(deleteRule: .nullify, inverse: \Student.exams)
    public var students: [Student]

    // Many-to-one relationship with Class
    // Each exam belongs to one class
    @Relationship(deleteRule: .nullify, inverse: \Class.exams)
    public var classItem: Class?

    public var createdAt: Date

    public init(
        title: String,
        subject: String,
        date: Date = Date(),
        maxScore: Int = 100,
        classItem: Class? = nil,
        createdAt: Date = Date()
    ) {
        self.title = title
        self.subject = subject
        self.date = date
        self.maxScore = maxScore
        self.classItem = classItem
        self.students = []
        self.createdAt = createdAt
    }
}

// MARK: - Computed Properties
extension Exam {
    /// Number of students registered for this exam
    public var studentCount: Int {
        students.count
    }

    /// Formatted date string
    public var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }

    /// Check if exam is in the future
    public var isUpcoming: Bool {
        date > Date()
    }

    /// Check if exam is in the past
    public var isPast: Bool {
        date < Date()
    }
}
