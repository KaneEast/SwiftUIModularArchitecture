//
//  TestDependencyContainer.swift
//  DemoAppTests - Test Dependency Container
//
//  Purpose: Create in-memory dependency container for testing
//  Uses SwiftData's isStoredInMemoryOnly for fast, isolated tests
//

import Foundation
import SwiftData
@testable import DemoApp

/// Helper to create test dependencies with in-memory storage
@MainActor
public enum TestDependencyContainer {

    /// Container for test repositories
    /// Keeps ModelContainer alive to prevent context.container from becoming nil
    public struct Repositories {
        public let studentRepo: StudentRepository
        public let classRepo: ClassRepository
        private let container: ModelContainer  // Keep alive

        fileprivate init(studentRepo: StudentRepository, classRepo: ClassRepository, container: ModelContainer) {
            self.studentRepo = studentRepo
            self.classRepo = classRepo
            self.container = container
        }
    }

    /// Creates test repositories directly with in-memory storage
    /// Each call creates a FRESH ModelContainer to ensure test isolation
    ///
    /// Why fresh container per test?
    /// - Each test = independent "app launch" with empty database
    /// - Mirrors how DemoApp holds its own container for its lifetime
    /// - Each test's container lives only for that test's duration
    ///
    /// Usage:
    /// ```
    /// let repos = TestDependencyContainer.createRepositories()
    /// try repos.studentRepo.create(student)
    /// let students = try repos.classRepo.fetchAll()
    /// ```
    public static func createRepositories() -> Repositories {
        // Create a fresh in-memory ModelContainer for each test
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Student.self, Class.self, configurations: config)
        let context = container.mainContext

        // Create fresh repositories with this isolated context
        let studentRepo = StudentRepository(context: context)
        let classRepo = ClassRepository(context: context)

        // Container is kept alive by the Repositories struct
        return Repositories(studentRepo: studentRepo, classRepo: classRepo, container: container)
    }
}
