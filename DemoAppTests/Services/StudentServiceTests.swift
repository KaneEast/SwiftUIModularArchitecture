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

    /// Container for test services and dependencies
    struct TestServices {
        let service: StudentService
        let repository: StudentRepository
        let api: MockRandomUserAPIService
        let repos: TestDependencyContainer.Repositories  // Keeps container alive
    }

    /// Creates a fresh service with in-memory dependencies for each test
    /// Uses real repositories with isStoredInMemoryOnly: true
    private func createService(
        shouldThrowAPIError: Bool = false
    ) -> TestServices {
        let repos = TestDependencyContainer.createRepositories()
        let apiService = MockRandomUserAPIService(shouldThrowError: shouldThrowAPIError)
        let service = StudentService(repository: repos.studentRepo, apiService: apiService)
        return TestServices(service: service, repository: repos.studentRepo, api: apiService, repos: repos)
    }

    // MARK: - Fetch and Save Tests

    @Test("Fetch and save random students successfully")
    func fetchAndSaveRandomStudents_success() async throws {
        // Given
        let testServices = createService()

        // When
        let students = try await testServices.service.fetchAndSaveRandomStudents(count: 3)

        // Then
        #expect(students.count == 3)

        let savedStudents = try testServices.repository.fetchAll()
        #expect(savedStudents.count == 3)
        #expect(savedStudents[0].name == "John Doe")
        #expect(savedStudents[0].email == "john.doe@test.com")
    }

    @Test("Fetch and save random students handles API error")
    func fetchAndSaveRandomStudents_apiError() async throws {
        // Given
        let testServices = createService(shouldThrowAPIError: true)

        // When/Then
        await #expect(throws: (any Error).self) {
            try await testServices.service.fetchAndSaveRandomStudents(count: 5)
        }

        // Repository should remain empty
        let savedStudents = try testServices.repository.fetchAll()
        #expect(savedStudents.isEmpty)
    }

    // MARK: - Enroll Student Tests

    @Test("Enroll student in class successfully")
    func enrollStudent_success() throws {
        // Given
        let testServices = createService()

        // Create models - insert immediately into context
        let student = Student(name: "John", email: "john@test.com", grade: 10)
        testServices.repository.context.insert(student)

        let classItem = Class(title: "Math 101", subject: "Math", room: "101")
        testServices.repository.context.insert(classItem)

        try testServices.repository.context.save()

        // When
        try testServices.service.enrollStudent(student, in: classItem)

        // Then
        #expect(student.classes.count == 1)
        #expect(student.classes.first?.title == "Math 101")
    }

    @Test("Enroll student throws error when already enrolled")
    func enrollStudent_alreadyEnrolled() throws {
        // Given
        let testServices = createService()
        let student = Student(name: "John", email: "john@test.com", grade: 10)
        let classItem = Class(title: "Math 101", subject: "Math", room: "101")

        student.classes.append(classItem)
        try testServices.repository.create(student)

        // When/Then
        #expect(throws: StudentServiceError.alreadyEnrolled) {
            try testServices.service.enrollStudent(student, in: classItem)
        }
    }

    @Test("Enroll student throws error when class is full")
    func enrollStudent_classFull() throws {
        // Given
        let repos = TestDependencyContainer.createRepositories()
        let apiService = MockRandomUserAPIService()
        let service = StudentService(repository: repos.studentRepo, apiService: apiService)
        let (classItem, _) = TestDataFactory.createFullClass(in: repos.classRepo, studentRepo: repos.studentRepo, title: "Popular Class")
        let newStudent = TestDataFactory.createStudent(in: repos.studentRepo, name: "Late Student", email: "late@test.com")

        try repos.studentRepo.context.save()

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
        let repos = TestDependencyContainer.createRepositories()
        let apiService = MockRandomUserAPIService()
        let service = StudentService(repository: repos.studentRepo, apiService: apiService)
        let student = TestDataFactory.createStudent(in: repos.studentRepo, name: "John", email: "john@test.com")
        let classItem = TestDataFactory.createClass(in: repos.classRepo, title: "Math 101")

        try repos.studentRepo.context.save()

        // When
        try service.enrollStudent(student, in: classItem)

        // Then
        let fetchedStudent = try repos.studentRepo.fetchByName("John")
        #expect(fetchedStudent?.classes.count == 1)
    }

    // MARK: - Delete Student Tests

    @Test("Delete student successfully")
    func deleteStudent_success() throws {
        // Given
        let testServices = createService()
        let student = TestDataFactory.createStudent(in: testServices.repository, name: "John", email: "john@test.com")

        try testServices.repository.context.save()
        #expect(try testServices.repository.fetchAll().count == 1)

        // When
        try testServices.service.deleteStudent(student)

        // Then
        #expect(try testServices.repository.fetchAll().isEmpty)
    }

    @Test("Delete student removes from all classes")
    func deleteStudent_removesFromClasses() throws {
        // Given
        let repos = TestDependencyContainer.createRepositories()
        let apiService = MockRandomUserAPIService()
        let service = StudentService(repository: repos.studentRepo, apiService: apiService)
        let (student, _) = TestDataFactory.createStudentWithClasses(in: repos.studentRepo, classRepo: repos.classRepo, name: "John", classCount: 3)

        try repos.studentRepo.context.save()
        #expect(student.classes.count == 3)

        // When
        try service.deleteStudent(student)

        // Then
        #expect(try repos.studentRepo.fetchAll().isEmpty)
        // Note: Cannot check student.classes.isEmpty because student is deleted
        // Verify classes still exist but student is gone
        #expect(try repos.classRepo.fetchAll().count == 3)
    }

    // MARK: - Search Students Tests

    @Test("Search students by name")
    func searchStudents_byName() throws {
        // Given
        let testServices = createService()
        let students = [
            TestDataFactory.createStudent(in: testServices.repository, name: "John Doe", email: "john@test.com"),
            TestDataFactory.createStudent(in: testServices.repository, name: "Jane Smith", email: "jane@test.com"),
            TestDataFactory.createStudent(in: testServices.repository, name: "Bob Johnson", email: "bob@test.com")
        ]

        // When
        let results = testServices.service.searchStudents(by: "John", from: students)

        // Then
        #expect(results.count == 2) // "John Doe" and "Bob Johnson"
        #expect(results.contains { $0.name == "John Doe" })
        #expect(results.contains { $0.name == "Bob Johnson" })
    }

    @Test("Search students by email")
    func searchStudents_byEmail() throws {
        // Given
        let testServices = createService()
        let students = [
            TestDataFactory.createStudent(in: testServices.repository, name: "John Doe", email: "john@test.com"),
            TestDataFactory.createStudent(in: testServices.repository, name: "Jane Smith", email: "jane@test.com"),
            TestDataFactory.createStudent(in: testServices.repository, name: "Bob Johnson", email: "bob@test.com")
        ]

        // When
        let results = testServices.service.searchStudents(by: "jane@", from: students)

        // Then
        #expect(results.count == 1)
        #expect(results.first?.name == "Jane Smith")
    }

    @Test("Search students with empty query returns all")
    func searchStudents_emptyQuery() throws {
        // Given
        let testServices = createService()
        let students = TestDataFactory.createStudents(in: testServices.repository, count: 5)

        // When
        let results = testServices.service.searchStudents(by: "", from: students)

        // Then
        #expect(results.count == 5)
    }

    @Test("Search students is case insensitive")
    func searchStudents_caseInsensitive() throws {
        // Given
        let testServices = createService()
        let students = [
            TestDataFactory.createStudent(in: testServices.repository, name: "John Doe", email: "JOHN@TEST.COM")
        ]

        // When
        let results1 = testServices.service.searchStudents(by: "john", from: students)
        let results2 = testServices.service.searchStudents(by: "JOHN", from: students)

        // Then
        #expect(results1.count == 1)
        #expect(results2.count == 1)
    }

    // MARK: - Observe Students Tests

    @Test("Observe students returns current data")
    func observeStudents_returnsCurrentData() async throws {
        // Given
        let testServices = createService()
        let students = TestDataFactory.createStudents(in: testServices.repository, count: 3)

        for student in students {
            try testServices.repository.create(student)
        }

        // When
        var receivedStudents: [Student] = []
        let cancellable = testServices.service.observeStudents()
            .sink { students in
                receivedStudents = students
            }

        // Wait a bit for the publisher to emit
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Then
        #expect(receivedStudents.count == 3)

        cancellable.cancel()
    }

    @Test("Observe students emits updates on changes")
    func observeStudents_emitsOnChanges() async throws {
        // Given
        let testServices = createService()
        var emittedStudentCounts: [Int] = []

        let cancellable = testServices.service.observeStudents()
            .sink { students in
                emittedStudentCounts.append(students.count)
            }

        try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds

        // When - Add students
        try testServices.repository.create(TestDataFactory.createStudent(in: testServices.repository, name: "Student 1"))
        try await Task.sleep(nanoseconds: 50_000_000)

        try testServices.repository.create(TestDataFactory.createStudent(in: testServices.repository, name: "Student 2"))
        try await Task.sleep(nanoseconds: 50_000_000)

        // Then
        #expect(emittedStudentCounts.count >= 3) // Initial (0) + 2 adds
        #expect(emittedStudentCounts.last == 2)

        cancellable.cancel()
    }
}
