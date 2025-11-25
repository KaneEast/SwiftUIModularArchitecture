//
//  StudentServiceTests.swift
//  DemoAppTests - Student Service Tests
//
//  Purpose: Test all business logic in StudentService
//  Using Swift Testing framework with in-memory mocks
//

import Testing
import Foundation
import Combine
import SwiftData
@testable import DemoApp

@Suite("StudentService Tests")
@MainActor
struct StudentServiceTests {

    // MARK: - Test Dependencies

    /// Creates a fresh service with in-memory dependencies for each test
    /// Uses real repositories with isStoredInMemoryOnly: true
    private func createService(
        shouldThrowAPIError: Bool = false
    ) -> (service: StudentService, repository: StudentRepository, api: MockRandomUserAPIService, container: ModelContainer) {
        let (studentRepo, _, container) = TestDependencyContainer.createRepositories()
        let apiService = MockRandomUserAPIService(shouldThrowError: shouldThrowAPIError)
        let service = StudentService(repository: studentRepo, apiService: apiService)
        return (service, studentRepo, apiService, container)
    }

    // MARK: - Fetch and Save Tests

    @Test("Fetch and save random students successfully")
    func fetchAndSaveRandomStudents_success() async throws {
        // Given
        let (service, repository, _, _container) = createService()

        // When
        let students = try await service.fetchAndSaveRandomStudents(count: 3)

        // Then
        #expect(students.count == 3)

        let savedStudents = try repository.fetchAll()
        #expect(savedStudents.count == 3)
        #expect(savedStudents[0].name == "John Doe")
        #expect(savedStudents[0].email == "john.doe@test.com")
    }

    @Test("Fetch and save random students handles API error")
    func fetchAndSaveRandomStudents_apiError() async throws {
        // Given
        let (service, repository, _, _container) = createService(shouldThrowAPIError: true)

        // When/Then
        await #expect(throws: (any Error).self) {
            try await service.fetchAndSaveRandomStudents(count: 5)
        }

        // Repository should remain empty
        let savedStudents = try repository.fetchAll()
        #expect(savedStudents.isEmpty)
    }

    // MARK: - Enroll Student Tests

    @Test("Enroll student in class successfully")
    func enrollStudent_success() throws {
        // Given
        let (service, repository, _, _container) = createService()

        // Create models - insert immediately into context
        let student = Student(name: "John", email: "john@test.com", grade: 10)
        repository.context.insert(student)

        let classItem = Class(title: "Math 101", subject: "Math", room: "101")
        repository.context.insert(classItem)

        try repository.context.save()

        // When
        try service.enrollStudent(student, in: classItem)

        // Then
        #expect(student.classes.count == 1)
        #expect(student.classes.first?.title == "Math 101")
    }

    @Test("Enroll student throws error when already enrolled")
    func enrollStudent_alreadyEnrolled() throws {
        // Given
        let (service, repository, _, _container) = createService()
        let student = Student(name: "John", email: "john@test.com", grade: 10)
        let classItem = Class(title: "Math 101", subject: "Math", room: "101")

        student.classes.append(classItem)
        try repository.create(student)

        // When/Then
        #expect(throws: StudentServiceError.alreadyEnrolled) {
            try service.enrollStudent(student, in: classItem)
        }
    }

    @Test("Enroll student throws error when class is full")
    func enrollStudent_classFull() throws {
        // Given
        let (studentRepo, classRepo, _container) = TestDependencyContainer.createRepositories()
        let apiService = MockRandomUserAPIService()
        let service = StudentService(repository: studentRepo, apiService: apiService)
        let (classItem, _) = TestDataFactory.createFullClass(in: classRepo, studentRepo: studentRepo, title: "Popular Class")
        let newStudent = TestDataFactory.createStudent(in: studentRepo, name: "Late Student", email: "late@test.com")

        try studentRepo.context.save()

        // When/Then
        #expect(throws: StudentServiceError.classIsFull) {
            try service.enrollStudent(newStudent, in: classItem)
        }

        // Student should not be enrolled
        #expect(newStudent.classes.isEmpty)
    }

    @Test("Enroll student updates repository")
    func enrollStudent_updatesRepository() throws {
        // Given
        let (studentRepo, classRepo, _container) = TestDependencyContainer.createRepositories()
        let apiService = MockRandomUserAPIService()
        let service = StudentService(repository: studentRepo, apiService: apiService)
        let student = TestDataFactory.createStudent(in: studentRepo, name: "John", email: "john@test.com")
        let classItem = TestDataFactory.createClass(in: classRepo, title: "Math 101")

        try studentRepo.context.save()

        // When
        try service.enrollStudent(student, in: classItem)

        // Then
        let fetchedStudent = try studentRepo.fetchByName("John")
        #expect(fetchedStudent?.classes.count == 1)
    }

    // MARK: - Delete Student Tests

    @Test("Delete student successfully")
    func deleteStudent_success() throws {
        // Given
        let (service, studentRepo, _, _) = createService()
        let student = TestDataFactory.createStudent(in: studentRepo, name: "John", email: "john@test.com")

        try studentRepo.context.save()
        #expect(try studentRepo.fetchAll().count == 1)

        // When
        try service.deleteStudent(student)

        // Then
        #expect(try studentRepo.fetchAll().isEmpty)
    }

    @Test("Delete student removes from all classes")
    func deleteStudent_removesFromClasses() throws {
        // Given
        let (studentRepo, classRepo, _container) = TestDependencyContainer.createRepositories()
        let apiService = MockRandomUserAPIService()
        let service = StudentService(repository: studentRepo, apiService: apiService)
        let (student, classes) = TestDataFactory.createStudentWithClasses(in: studentRepo, classRepo: classRepo, name: "John", classCount: 3)

        try studentRepo.context.save()
        #expect(student.classes.count == 3)

        // When
        try service.deleteStudent(student)

        // Then
        #expect(try studentRepo.fetchAll().isEmpty)
        #expect(student.classes.isEmpty)
    }

    // MARK: - Search Students Tests

    @Test("Search students by name")
    func searchStudents_byName() throws {
        // Given
        let (service, studentRepo, _, _) = createService()
        let students = [
            TestDataFactory.createStudent(in: studentRepo, name: "John Doe", email: "john@test.com"),
            TestDataFactory.createStudent(in: studentRepo, name: "Jane Smith", email: "jane@test.com"),
            TestDataFactory.createStudent(in: studentRepo, name: "Bob Johnson", email: "bob@test.com")
        ]

        // When
        let results = service.searchStudents(by: "John", from: students)

        // Then
        #expect(results.count == 2) // "John Doe" and "Bob Johnson"
        #expect(results.contains { $0.name == "John Doe" })
        #expect(results.contains { $0.name == "Bob Johnson" })
    }

    @Test("Search students by email")
    func searchStudents_byEmail() throws {
        // Given
        let (service, studentRepo, _, _) = createService()
        let students = [
            TestDataFactory.createStudent(in: studentRepo, name: "John Doe", email: "john@test.com"),
            TestDataFactory.createStudent(in: studentRepo, name: "Jane Smith", email: "jane@test.com"),
            TestDataFactory.createStudent(in: studentRepo, name: "Bob Johnson", email: "bob@test.com")
        ]

        // When
        let results = service.searchStudents(by: "jane@", from: students)

        // Then
        #expect(results.count == 1)
        #expect(results.first?.name == "Jane Smith")
    }

    @Test("Search students with empty query returns all")
    func searchStudents_emptyQuery() throws {
        // Given
        let (service, studentRepo, _, _) = createService()
        let students = TestDataFactory.createStudents(in: studentRepo, count: 5)

        // When
        let results = service.searchStudents(by: "", from: students)

        // Then
        #expect(results.count == 5)
    }

    @Test("Search students is case insensitive")
    func searchStudents_caseInsensitive() throws {
        // Given
        let (service, studentRepo, _, _) = createService()
        let students = [
            TestDataFactory.createStudent(in: studentRepo, name: "John Doe", email: "JOHN@TEST.COM")
        ]

        // When
        let results1 = service.searchStudents(by: "john", from: students)
        let results2 = service.searchStudents(by: "JOHN", from: students)

        // Then
        #expect(results1.count == 1)
        #expect(results2.count == 1)
    }

    // MARK: - Observe Students Tests

//    @Test("Observe students returns current data")
//    func observeStudents_returnsCurrentData() async throws {
//        // Given
//        let (service, repository, _, _container) = createService()
//        let students = TestDataFactory.createStudents(count: 3)
//
//        for student in students {
//            try repository.create(student)
//        }
//
//        // When
//        var receivedStudents: [Student] = []
//        let cancellable = service.observeStudents()
//            .sink { students in
//                receivedStudents = students
//            }
//
//        // Wait a bit for the publisher to emit
//        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
//
//        // Then
//        #expect(receivedStudents.count == 3)
//
//        cancellable.cancel()
//    }

//    @Test("Observe students emits updates on changes")
//    func observeStudents_emitsOnChanges() async throws {
//        // Given
//        let (service, repository, _, _container) = createService()
//        var emittedStudentCounts: [Int] = []
//
//        let cancellable = service.observeStudents()
//            .sink { students in
//                emittedStudentCounts.append(students.count)
//            }
//
//        try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds
//
//        // When - Add students
//        try repository.create(TestDataFactory.createStudent(name: "Student 1"))
//        try await Task.sleep(nanoseconds: 50_000_000)
//
//        try repository.create(TestDataFactory.createStudent(name: "Student 2"))
//        try await Task.sleep(nanoseconds: 50_000_000)
//
//        // Then
//        #expect(emittedStudentCounts.count >= 3) // Initial (0) + 2 adds
//        #expect(emittedStudentCounts.last == 2)
//
//        cancellable.cancel()
//    }
}
