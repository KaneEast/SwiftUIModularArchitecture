//
//  ExamRepository.swift
//  DemoApp - Exam Repository
//
//  Purpose: Data access layer for Exam model
//  Implements custom query methods for exam-specific operations
//

import Foundation
import SwiftData

public class ExamRepository: BaseRepository<Exam>, ExamRepositoryProtocol {

    // Fetch all exams for a specific class
    public func fetchByClass(_ classItem: Class) throws -> [Exam] {
        // Use the bidirectional relationship - more efficient
        // Class already has .exams populated by SwiftData
        return classItem.exams.sorted { $0.date < $1.date }
    }

    // Fetch all upcoming exams (date in the future)
    public func fetchUpcomingExams() throws -> [Exam] {
        let now = Date()
        let predicate = #Predicate<Exam> { exam in
            exam.date > now
        }
        let sortBy = [SortDescriptor(\Exam.date, order: .forward)]
        return try fetch(predicate: predicate, sortBy: sortBy)
    }

    // Fetch all past exams (date in the past)
    public func fetchPastExams() throws -> [Exam] {
        let now = Date()
        let predicate = #Predicate<Exam> { exam in
            exam.date < now
        }
        let sortBy = [SortDescriptor(\Exam.date, order: .reverse)]
        return try fetch(predicate: predicate, sortBy: sortBy)
    }
}
