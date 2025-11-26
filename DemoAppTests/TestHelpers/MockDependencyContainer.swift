//
//  MockDependencyContainer.swift
//  DemoAppTests - Mock Dependency Container
//
//  Purpose: Provides mock implementations of dependencies for testing
//  Benefits:
//  - Easy to create test doubles
//  - Can control behavior for specific test scenarios
//  - Conforms to DependencyProviding protocol
//

import Foundation
import SwiftData
@testable import DemoApp

/// Mock dependency container for testing
/// Provides in-memory repositories and mock services
@MainActor
public final class MockDependencyContainer: @preconcurrency DependencyProviding {
    public let studentRepository: any StudentRepositoryProtocol
    public let classRepository: any ClassRepositoryProtocol
    public let networkService: NetworkService
    public let randomUserAPI: any RandomUserAPIServiceProtocol

    private let container: ModelContainer  // Keep alive

    public init(
        studentRepository: (any StudentRepositoryProtocol)? = nil,
        classRepository: (any ClassRepositoryProtocol)? = nil,
        randomUserAPI: (any RandomUserAPIServiceProtocol)? = nil
    ) {
        // Create in-memory container for default repositories
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Student.self, Class.self, configurations: config)
        self.container = container

        let context = container.mainContext

        // Use provided repositories or create defaults
        self.studentRepository = studentRepository ?? StudentRepository(context: context)
        self.classRepository = classRepository ?? ClassRepository(context: context)

        // Create mock network service
        self.networkService = NetworkService()

        // Use provided API or create mock
        self.randomUserAPI = randomUserAPI ?? MockRandomUserAPIService()
    }

    /// Convenience initializer for quick mock creation
    /// Returns both repositories sharing the same context
    public static func create() -> (
        container: MockDependencyContainer,
        studentRepo: any StudentRepositoryProtocol,
        classRepo: any ClassRepositoryProtocol
    ) {
        let mock = MockDependencyContainer()
        return (mock, mock.studentRepository, mock.classRepository)
    }
}
