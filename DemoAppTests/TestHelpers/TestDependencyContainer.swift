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

    /// Creates test repositories directly with in-memory storage
    /// Each call creates a FRESH ModelContainer to ensure test isolation
    /// IMPORTANT: Returns the container to keep it alive (context needs it)
    public static func createRepositories() -> (student: StudentRepository, class: ClassRepository, container: ModelContainer) {
        // Create a fresh in-memory ModelContainer for each test
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Student.self, Class.self, configurations: config)
        let context = container.mainContext

        // Create fresh repositories with this isolated context
        let studentRepo = StudentRepository(context: context)
        let classRepo = ClassRepository(context: context)

        // MUST return container to keep it alive!
        // If container is deallocated, context.container becomes nil
        return (studentRepo, classRepo, container)
    }
}
