//
//  ExamService.swift
//  DemoApp - Exam Business Logic Service
//
//  Purpose: Centralizes all business logic for Exam operations
//  Responsibilities: Validation, business rules, and data orchestration
//

import Foundation
import Combine

/// Core business logic service for Exam module
/// Handles all exam-related business operations
public final class ExamService {
    private let repository: any ExamRepositoryProtocol

    public init(repository: any ExamRepositoryProtocol) {
        self.repository = repository
    }

    // MARK: - Core Business Logic

    /// Observe all exams (reactive)
    public func observeExams() -> AnyPublisher<[Exam], Never> {
        return repository.observeAll()
    }

    /// Create new exam (Business rules: validate data, check for duplicates)
    public func createExam(
        title: String,
        subject: String,
        date: Date,
        maxScore: Int,
        classItem: Class?
    ) throws {
        // Business rule: Validate title is not empty
        guard !title.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw ExamServiceError.emptyTitle
        }

        // Business rule: Validate subject is not empty
        guard !subject.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw ExamServiceError.emptySubject
        }

        // Business rule: Validate max score is positive
        guard maxScore > 0 else {
            throw ExamServiceError.invalidMaxScore
        }

        // Business rule: Validate date is not too far in the past
        let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        guard date >= oneYearAgo else {
            throw ExamServiceError.dateTooOld
        }

        let newExam = Exam(
            title: title,
            subject: subject,
            date: date,
            maxScore: maxScore,
            classItem: classItem
        )
        try repository.create(newExam)
    }

    /// Delete exam (Business logic: remove from all students)
    public func deleteExam(_ exam: Exam) throws {
        // Business logic: Remove exam from all students first
        if !exam.students.isEmpty {
            exam.students.removeAll()
        }

        try repository.delete(exam)
    }

    /// Get students registered for this exam
    public func getStudentsInExam(_ exam: Exam) -> [Student] {
        return exam.students.sorted { $0.name < $1.name }
    }

    /// Register student for exam (Business rules: check duplicates, capacity)
    public func registerStudent(_ student: Student, for exam: Exam) throws {
        // Business rule: Check if student is already registered
        guard !exam.students.contains(where: { $0.persistentModelID == student.persistentModelID }) else {
            throw ExamServiceError.alreadyRegistered
        }

        // Business rule: Check if exam is in the past
        guard exam.date >= Date() else {
            throw ExamServiceError.examHasPassed
        }

        // Add student to exam
        exam.students.append(student)
        try repository.update(exam)
    }

    /// Unregister student from exam
    public func unregisterStudent(_ student: Student, from exam: Exam) throws {
        // Business rule: Check if exam is in the past
        guard exam.date >= Date() else {
            throw ExamServiceError.examHasPassed
        }

        exam.students.removeAll(where: { $0.persistentModelID == student.persistentModelID })
        try repository.update(exam)
    }

    /// Get upcoming exams (business logic: filter by date)
    public func getUpcomingExams() throws -> [Exam] {
        return try repository.fetchUpcomingExams()
    }

    /// Get past exams (business logic: filter by date)
    public func getPastExams() throws -> [Exam] {
        return try repository.fetchPastExams()
    }

    /// Get exams for a specific class
    public func getExamsForClass(_ classItem: Class) throws -> [Exam] {
        return try repository.fetchByClass(classItem)
    }

    /// Search exams (business logic: support fuzzy search)
    public func searchExams(by query: String, from exams: [Exam]) -> [Exam] {
        guard !query.isEmpty else { return exams }

        return exams.filter { exam in
            exam.title.localizedCaseInsensitiveContains(query) ||
            exam.subject.localizedCaseInsensitiveContains(query)
        }
    }

    /// Calculate exam statistics
    public func getExamStats(_ exam: Exam) -> ExamStats {
        return ExamStats(
            totalStudents: exam.students.count,
            isUpcoming: exam.isUpcoming,
            isPast: exam.isPast,
            formattedDate: exam.formattedDate
        )
    }
}

// MARK: - Supporting Types

public struct ExamStats {
    public let totalStudents: Int
    public let isUpcoming: Bool
    public let isPast: Bool
    public let formattedDate: String
}

// MARK: - Errors

public enum ExamServiceError: LocalizedError {
    case emptyTitle
    case emptySubject
    case invalidMaxScore
    case dateTooOld
    case alreadyRegistered
    case examHasPassed

    public var errorDescription: String? {
        switch self {
        case .emptyTitle:
            return "Exam title cannot be empty"
        case .emptySubject:
            return "Exam subject cannot be empty"
        case .invalidMaxScore:
            return "Max score must be greater than 0"
        case .dateTooOld:
            return "Exam date cannot be more than 1 year in the past"
        case .alreadyRegistered:
            return "Student is already registered for this exam"
        case .examHasPassed:
            return "Cannot modify exam that has already passed"
        }
    }
}
