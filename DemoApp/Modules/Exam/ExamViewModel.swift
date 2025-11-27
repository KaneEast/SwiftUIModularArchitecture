//
//  ExamViewModel.swift
//  DemoApp - Exam ViewModel
//
//  Purpose: Manages UI state for Exam module
//  Business logic is handled by ExamService
//

import Foundation
import Observation
import Combine

@Observable
public class ExamViewModel {
    private let service: ExamService  // Only depends on Service, not Repository
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI State

    private(set) var exams: [Exam] = []
    public var searchText: String = "" {
        didSet { applyFilters() }
    }
    private(set) var filteredExams: [Exam] = []
    public var isLoadingData: Bool = true
    public var errorMessage: String?

    // Filter states
    public var showUpcomingOnly: Bool = false {
        didSet { applyFilters() }
    }
    public var showPastOnly: Bool = false {
        didSet { applyFilters() }
    }

    // MARK: - Initialization

    public init(service: ExamService) {
        self.service = service
        setupReactiveObservation()
    }

    // MARK: - Private Methods

    private func setupReactiveObservation() {
        service.observeExams()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedExams in
                guard let self = self else { return }
                self.isLoadingData = false
                self.exams = updatedExams.sorted { $0.date < $1.date }
                self.applyFilters()
            }
            .store(in: &cancellables)
    }

    private func applyFilters() {
        var result = exams

        // Apply search filter
        if !searchText.isEmpty {
            result = service.searchExams(by: searchText, from: result)
        }

        // Apply date filters
        if showUpcomingOnly {
            result = result.filter { $0.isUpcoming }
        } else if showPastOnly {
            result = result.filter { $0.isPast }
        }

        filteredExams = result
    }

    // MARK: - Public Actions (Call Service)

    /// Get students registered for an exam
    public func getStudents(in exam: Exam) -> [Student] {
        return service.getStudentsInExam(exam)
    }

    /// Get exams for a specific class
    public func getExamsForClass(_ classItem: Class) throws -> [Exam] {
        return try service.getExamsForClass(classItem)
    }

    /// Get exam statistics
    public func getStats(for exam: Exam) -> ExamStats {
        return service.getExamStats(exam)
    }

    /// Create new exam
    public func createExam(
        title: String,
        subject: String,
        date: Date,
        maxScore: Int,
        classItem: Class?
    ) {
        errorMessage = nil

        do {
            try service.createExam(
                title: title,
                subject: subject,
                date: date,
                maxScore: maxScore,
                classItem: classItem
            )
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Delete exam
    public func deleteExam(_ exam: Exam) {
        errorMessage = nil

        do {
            try service.deleteExam(exam)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Register student for exam
    public func registerStudent(_ student: Student, for exam: Exam) {
        errorMessage = nil

        do {
            try service.registerStudent(student, for: exam)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Unregister student from exam
    public func unregisterStudent(_ student: Student, from exam: Exam) {
        errorMessage = nil

        do {
            try service.unregisterStudent(student, from: exam)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
