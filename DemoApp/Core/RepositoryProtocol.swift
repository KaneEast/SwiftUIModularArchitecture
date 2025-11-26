//
//  RepositoryProtocol.swift
//  KanjiDemo - Core Module: Repository Protocol for Dependency Injection
//
//  Purpose: Protocol abstraction for repositories to enable mock implementations in tests
//

import Foundation
import SwiftData
import Combine

/// Protocol defining the contract for repository operations
/// Benefits:
/// - Enables dependency injection
/// - Allows mock implementations for testing
/// - Provides consistent API across all repositories
public protocol RepositoryProtocol {
    associatedtype Model

    // MARK: - CRUD Operations
    func create(_ model: Model) throws
    func fetchAll() throws -> [Model]
    func update(_ model: Model) throws
    func delete(_ model: Model) throws
    func deleteAll() throws
    func count(predicate: Predicate<Model>?) throws -> Int

    // MARK: - Reactive Observation
    func observeAll() -> AnyPublisher<[Model], Never>
}

/// Protocol for Student-specific repository operations
public protocol StudentRepositoryProtocol: RepositoryProtocol where Model == Student {
    func fetchByGrade(_ grade: Int) throws -> [Student]
    func fetchByName(_ name: String) throws -> Student?
    func fetchStudentsInClass(_ classItem: Class) -> [Student]
}

/// Protocol for Class-specific repository operations
public protocol ClassRepositoryProtocol: RepositoryProtocol where Model == Class {
    // Class-specific methods can be added here as needed
}
