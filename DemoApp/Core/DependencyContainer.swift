//
//  DependencyContainer.swift
//  KanjiDemo - Core Module: Dependency Injection
//

import Foundation
import SwiftData

public class DependencyContainer {
    public let modelContext: ModelContext

    // MARK: - Repositories (Lazy initialization)

    public lazy var studentRepository: StudentRepository = {
        StudentRepository(context: modelContext)
    }()
    
    public lazy var classRepository: ClassRepository = {
        ClassRepository(context: modelContext)
    }()

    // MARK: - Network Services (Lazy initialization)

    public lazy var networkService: NetworkService = {
        NetworkService()
    }()

    public lazy var randomUserAPI: RandomUserAPIService = {
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
        let container = try! ModelContainer(for: Student.self, Class.self, configurations: config)
        return DependencyContainer(modelContext: container.mainContext)
    }
}
