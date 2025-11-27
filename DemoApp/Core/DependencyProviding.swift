//
//  DependencyProviding.swift
//  KanjiDemo - Core Module: Dependency Injection Protocol
//
//  Purpose: Protocol for dependency injection
//  Benefits:
//  - Enables easy mocking for tests
//  - Allows swapping implementations (local DB, remote API, etc.)
//  - Better for multi-environment setups (dev/staging/prod)
//

import Foundation
import SwiftData

/// Protocol that defines all dependencies available in the app
/// This allows modules to depend on abstractions rather than concrete types
public protocol DependencyProviding {
    // MARK: - Repositories
    var studentRepository: any StudentRepositoryProtocol { get }
    var classRepository: any ClassRepositoryProtocol { get }
    var examRepository: any ExamRepositoryProtocol { get }

    // MARK: - Network Services
    var networkService: NetworkService { get }
    var randomUserAPI: any RandomUserAPIServiceProtocol { get }
}

/// Extension to provide convenient access to shared dependencies
extension DependencyProviding {
    /// Access to the underlying ModelContext (if available)
    /// This is useful for operations that need direct context access
    public var modelContext: ModelContext? {
        // Try to get context from repository
        if let repo = studentRepository as? StudentRepository {
            return repo.context
        }
        return nil
    }
}
