//
//  DependencyContainer.swift
//  KanjiDemo - Core Module: Dependency Injection
//
//  Purpose: Concrete implementation of DependencyProviding protocol
//  Provides real implementations of all dependencies for production use
//

import Foundation
import SwiftData

public final class DependencyContainer: DependencyProviding {
    public let modelContext: ModelContext

    // MARK: - Repositories (Lazy initialization)

    public lazy var studentRepository: any StudentRepositoryProtocol = {
        StudentRepository(context: modelContext)
    }()

    public lazy var classRepository: any ClassRepositoryProtocol = {
        ClassRepository(context: modelContext)
    }()

    public lazy var examRepository: any ExamRepositoryProtocol = {
        ExamRepository(context: modelContext)
    }()

    // MARK: - Network Services (Lazy initialization)

    public lazy var networkService: NetworkService = {
        NetworkService()
    }()

    public lazy var randomUserAPI: any RandomUserAPIServiceProtocol = {
        RandomUserAPIService(networkService: networkService)
    }()

    // MARK: - Initialization

    public init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }

    // MARK: - Mock Container for Testing

    @MainActor
    public static func mock() -> DependencyContainer {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try! ModelContainer(for: Student.self, Class.self, Exam.self, configurations: config)
        return DependencyContainer(modelContext: container.mainContext)
    }
}
