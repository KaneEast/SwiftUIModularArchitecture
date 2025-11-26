//
//  ClassServiceTests.swift
//  DemoAppTests - Class Service Tests
//
//  Purpose: Test all business logic in ClassService
//  Using Swift Testing framework with in-memory mocks
//

import Testing
import Foundation
import Combine
import SwiftData
@testable import DemoApp

@Suite("ClassService Tests")
@MainActor
struct ClassServiceTests {

    // MARK: - Test Dependencies

    /// Container for test services and dependencies
    struct TestServices {
        let service: ClassService
        let repository: ClassRepository
        let repos: TestDependencyContainer.Repositories  // Keeps container alive
    }

    /// Creates a fresh service with in-memory dependencies for each test
    /// Uses real repository with isStoredInMemoryOnly: true
    private func createService() -> TestServices {
        let repos = TestDependencyContainer.createRepositories()
        let service = ClassService(repository: repos.classRepo)
        return TestServices(service: service, repository: repos.classRepo, repos: repos)
    }

    // MARK: - Create Class Tests

    @Test("Create class successfully")
    func createClass_success() throws {
        // Given
        let testServices = createService()

        // When
        try testServices.service.createClass(title: "Mathematics 101", subject: "Math", room: "Room 201")

        // Then
        let classes = try testServices.repository.fetchAll()
        #expect(classes.count == 1)
        #expect(classes.first?.title == "Mathematics 101")
        #expect(classes.first?.subject == "Math")
        #expect(classes.first?.room == "Room 201")
    }

    @Test("Create class throws error for empty title")
    func createClass_emptyTitle() throws {
        // Given
        let testServices = createService()

        // When/Then
        #expect(throws: ClassServiceError.emptyTitle) {
            try testServices.service.createClass(title: "", subject: "Math", room: "201")
        }

        // Repository should be empty
        #expect(try testServices.repository.fetchAll().isEmpty)
    }

    @Test("Create class throws error for whitespace-only title")
    func createClass_whitespaceTitle() throws {
        // Given
        let testServices = createService()

        // When/Then
        #expect(throws: ClassServiceError.emptyTitle) {
            try testServices.service.createClass(title: "   ", subject: "Math", room: "201")
        }

        #expect(try testServices.repository.fetchAll().isEmpty)
    }

    @Test("Create class throws error for empty room")
    func createClass_emptyRoom() throws {
        // Given
        let testServices = createService()

        // When/Then
        #expect(throws: ClassServiceError.emptyRoom) {
            try testServices.service.createClass(title: "Math 101", subject: "Math", room: "")
        }

        #expect(try testServices.repository.fetchAll().isEmpty)
    }

    @Test("Create class throws error for whitespace-only room")
    func createClass_whitespaceRoom() throws {
        // Given
        let testServices = createService()

        // When/Then
        #expect(throws: ClassServiceError.emptyRoom) {
            try testServices.service.createClass(title: "Math 101", subject: "Math", room: "   ")
        }

        #expect(try testServices.repository.fetchAll().isEmpty)
    }

    // MARK: - Delete Class Tests

    @Test("Delete class successfully")
    func deleteClass_success() throws {
        // Given
        let testServices = createService()
        let classItem = TestDataFactory.createClass(in: testServices.repository, title: "Math 101")

        try testServices.repository.context.save()
        #expect(try testServices.repository.fetchAll().count == 1)

        // When
        try testServices.service.deleteClass(classItem)

        // Then
        #expect(try testServices.repository.fetchAll().isEmpty)
    }

    @Test("Delete class removes all student relationships")
    func deleteClass_removesStudentRelationships() throws {
        // Given
        // IMPORTANT: Both repos must share the same context for relationships to work!
        let repos = TestDependencyContainer.createRepositories()
        let service = ClassService(repository: repos.classRepo)
        let (classItem, students) = TestDataFactory.createClassWithStudents(in: repos.classRepo, studentRepo: repos.studentRepo, title: "Popular Class", studentCount: 5)

        try repos.classRepo.context.save()
        #expect(classItem.students.count == 5)

        // When
        try service.deleteClass(classItem)

        // Then
        #expect(try repos.classRepo.fetchAll().isEmpty)
        // Note: Cannot check classItem.students.isEmpty because classItem is deleted
        // Verify students still exist but class is gone
        #expect(try repos.studentRepo.fetchAll().count == 5)
    }

    @Test("Delete empty class succeeds")
    func deleteClass_emptyClass() throws {
        // Given
        let testServices = createService()
        let classItem = TestDataFactory.createClass(in: testServices.repository, title: "Empty Class")

        try testServices.repository.context.save()

        // When
        try testServices.service.deleteClass(classItem)

        // Then
        #expect(try testServices.repository.fetchAll().isEmpty)
    }

    // MARK: - Get Students Tests

    @Test("Get students in class returns correct list")
    func getStudentsInClass_returnsCorrectList() throws {
        // Given
        let repos = TestDependencyContainer.createRepositories()
        let service = ClassService(repository: repos.classRepo)
        let (classItem, students) = TestDataFactory.createClassWithStudents(in: repos.classRepo, studentRepo: repos.studentRepo, title: "Math 101", studentCount: 10)

        // When
        let result = service.getStudentsInClass(classItem)

        // Then
        #expect(result.count == 10)
        #expect(result == classItem.students)
    }

    @Test("Get students in empty class returns empty array")
    func getStudentsInClass_emptyClass() throws {
        // Given
        let testServices = createService()
        let classItem = TestDataFactory.createClass(in: testServices.repository, title: "Empty Class")

        // When
        let result = testServices.service.getStudentsInClass(classItem)

        // Then
        #expect(result.isEmpty)
    }

    // MARK: - Capacity Tests

    @Test("Get capacity usage calculates correctly")
    func getCapacityUsage_calculatesCorrectly() throws {
        // Given
        let repos = TestDependencyContainer.createRepositories()
        let service = ClassService(repository: repos.classRepo)
        let (classItem, _) = TestDataFactory.createClassWithStudents(in: repos.classRepo, studentRepo: repos.studentRepo, title: "Class", studentCount: 15)

        // When
        let usage = service.getCapacityUsage(for: classItem, maxCapacity: 30)

        // Then
        #expect(usage == 0.5) // 15/30 = 0.5
    }

    @Test("Get capacity usage with full class")
    func getCapacityUsage_fullClass() throws {
        // Given
        let repos = TestDependencyContainer.createRepositories()
        let service = ClassService(repository: repos.classRepo)
        let (classItem, _) = TestDataFactory.createFullClass(in: repos.classRepo, studentRepo: repos.studentRepo, title: "Full Class")

        // When
        let usage = service.getCapacityUsage(for: classItem, maxCapacity: 30)

        // Then
        #expect(usage == 1.0) // 30/30 = 1.0
    }

    @Test("Get capacity usage with empty class")
    func getCapacityUsage_emptyClass() throws {
        // Given
        let testServices = createService()
        let classItem = TestDataFactory.createClass(in: testServices.repository, title: "Empty Class")

        // When
        let usage = testServices.service.getCapacityUsage(for: classItem, maxCapacity: 30)

        // Then
        #expect(usage == 0.0) // 0/30 = 0.0
    }

    @Test("Is class full returns true when at capacity")
    func isClassFull_returnsTrue() throws {
        // Given
        let repos = TestDependencyContainer.createRepositories()
        let service = ClassService(repository: repos.classRepo)
        let (classItem, _) = TestDataFactory.createFullClass(in: repos.classRepo, studentRepo: repos.studentRepo, title: "Full Class")

        // When
        let isFull = service.isClassFull(classItem, maxCapacity: 30)

        // Then
        #expect(isFull == true)
    }

    @Test("Is class full returns false when under capacity")
    func isClassFull_returnsFalse() throws {
        // Given
        let repos = TestDependencyContainer.createRepositories()
        let service = ClassService(repository: repos.classRepo)
        let (classItem, _) = TestDataFactory.createClassWithStudents(in: repos.classRepo, studentRepo: repos.studentRepo, title: "Class", studentCount: 20)

        // When
        let isFull = service.isClassFull(classItem, maxCapacity: 30)

        // Then
        #expect(isFull == false)
    }

    @Test("Is class full with custom capacity")
    func isClassFull_customCapacity() throws {
        // Given
        let repos = TestDependencyContainer.createRepositories()
        let service = ClassService(repository: repos.classRepo)
        let (classItem, _) = TestDataFactory.createClassWithStudents(in: repos.classRepo, studentRepo: repos.studentRepo, title: "Class", studentCount: 10)

        // When
        let isFull = service.isClassFull(classItem, maxCapacity: 10)

        // Then
        #expect(isFull == true)
    }

    // MARK: - Observe Classes Tests

    @Test("Observe classes returns current data")
    func observeClasses_returnsCurrentData() async throws {
        // Given
        let testServices = createService()
        let classes = TestDataFactory.createClasses(in: testServices.repository, count: 3)

        try testServices.repository.context.save()

        // When
        var receivedClasses: [Class] = []
        let cancellable = testServices.service.observeClasses()
            .sink { classes in
                receivedClasses = classes
            }

        // Wait a bit for the publisher to emit
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds

        // Then
        #expect(receivedClasses.count == 3)

        cancellable.cancel()
    }

    @Test("Observe classes emits updates on changes")
    func observeClasses_emitsOnChanges() async throws {
        // Given
        let testServices = createService()
        var emittedClassCounts: [Int] = []

        let cancellable = testServices.service.observeClasses()
            .sink { classes in
                emittedClassCounts.append(classes.count)
            }

        try await Task.sleep(nanoseconds: 50_000_000) // 0.05 seconds

        // When - Add classes
        try testServices.service.createClass(title: "Class 1", subject: "Math", room: "101")
        try await Task.sleep(nanoseconds: 50_000_000)

        try testServices.service.createClass(title: "Class 2", subject: "Science", room: "102")
        try await Task.sleep(nanoseconds: 50_000_000)

        // Then
        #expect(emittedClassCounts.count >= 3) // Initial (0) + 2 adds
        #expect(emittedClassCounts.last == 2)

        cancellable.cancel()
    }
}
