//
//  TestDataFactory.swift
//  DemoAppTests - Test Data Factory
//
//  Purpose: Helper methods to create test data quickly and consistently
//  IMPORTANT: SwiftData models MUST be inserted into context immediately
//

import Foundation
import SwiftData
@testable import DemoApp

/// Factory for creating test data with context awareness
/// Benefits:
/// - Consistent test data across tests
/// - Reduces test boilerplate
/// - Handles SwiftData context requirements automatically
@MainActor
public enum TestDataFactory {

    // MARK: - Student Factory

    /// Create a test student and insert into the provided repository's context
    public static func createStudent(
        in repository: StudentRepository,
        name: String = "Test Student",
        email: String = "test@student.com",
        grade: Int = 10,
        classes: [Class] = []
    ) -> Student {
        let student = Student(name: name, email: email, grade: grade)
        student.classes = classes
        repository.context.insert(student)
        return student
    }

    /// Create multiple test students in the repository's context
    public static func createStudents(
        in repository: StudentRepository,
        count: Int,
        grade: Int = 10
    ) -> [Student] {
        return (1...count).map { index in
            createStudent(
                in: repository,
                name: "Student \(index)",
                email: "student\(index)@test.com",
                grade: grade
            )
        }
    }

    // MARK: - Class Factory

    /// Create a test class and insert into the provided repository's context
    public static func createClass(
        in repository: ClassRepository,
        title: String = "Test Class",
        subject: String = "Mathematics",
        room: String = "101",
        students: [Student] = []
    ) -> Class {
        let classItem = Class(title: title, subject: subject, room: room)
        classItem.students = students
        repository.context.insert(classItem)
        return classItem
    }

    /// Create multiple test classes in the repository's context
    public static func createClasses(
        in repository: ClassRepository,
        count: Int
    ) -> [Class] {
        let subjects = ["Mathematics", "Science", "History", "English", "Art"]
        return (1...count).map { index in
            createClass(
                in: repository,
                title: "Class \(index)",
                subject: subjects[(index - 1) % subjects.count],
                room: "Room \(100 + index)"
            )
        }
    }

    // MARK: - Complex Scenarios

    /// Create a student enrolled in multiple classes
    public static func createStudentWithClasses(
        in studentRepo: StudentRepository,
        classRepo: ClassRepository,
        name: String = "Enrolled Student",
        classCount: Int = 3
    ) -> (student: Student, classes: [Class]) {
        let classes = createClasses(in: classRepo, count: classCount)
        let student = createStudent(
            in: studentRepo,
            name: name,
            email: "\(name.lowercased().replacingOccurrences(of: " ", with: "."))@test.com"
        )
        student.classes = classes

        // Also add student to classes' student arrays (bidirectional relationship)
        classes.forEach { $0.students.append(student) }

        return (student, classes)
    }

    /// Create a class with multiple enrolled students
    public static func createClassWithStudents(
        in classRepo: ClassRepository,
        studentRepo: StudentRepository,
        title: String = "Popular Class",
        studentCount: Int = 10
    ) -> (classItem: Class, students: [Student]) {
        let students = createStudents(in: studentRepo, count: studentCount)
        let classItem = createClass(in: classRepo, title: title)
        classItem.students = students

        // Also add class to students' classes arrays (bidirectional relationship)
        students.forEach { $0.classes.append(classItem) }

        return (classItem, students)
    }

    /// Create a full class (at capacity of 30 students)
    public static func createFullClass(
        in classRepo: ClassRepository,
        studentRepo: StudentRepository,
        title: String = "Full Class"
    ) -> (classItem: Class, students: [Student]) {
        return createClassWithStudents(
            in: classRepo,
            studentRepo: studentRepo,
            title: title,
            studentCount: 30
        )
    }
}
