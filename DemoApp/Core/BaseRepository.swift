//
//  BaseRepository.swift
//  KanjiDemo - Core Module: Repository Pattern with Change Observation
//

import SwiftData
import Foundation
import Combine

// MARK: - Repository Change Types

/// Tracks what kind of change happened in the repository
public enum RepositoryChange<Model: PersistentModel> {
    case created(Model)
    case updated(Model)
    case deleted(PersistentIdentifier)
    case batchChange
}

// MARK: - Base Repository

/// Generic repository providing CRUD operations and reactive change observation
/// Benefits:
/// - Consistent API across all repositories
/// - Reactive updates via Combine publishers
/// - Abstracted from SwiftData implementation
public class BaseRepository<Model: PersistentModel> {
    public let context: ModelContext

    // MARK: - Change Observation (Reactive Pattern)

    private let changeSubject = PassthroughSubject<RepositoryChange<Model>, Never>()
    private let updateSubject = PassthroughSubject<Model, Never>()

    /// Publishes all repository changes (create, update, delete)
    public var changePublisher: AnyPublisher<RepositoryChange<Model>, Never> {
        changeSubject.eraseToAnyPublisher()
    }

    /// Publishes only update events with the updated model
    public var updatePublisher: AnyPublisher<Model, Never> {
        updateSubject.eraseToAnyPublisher()
    }

    /// Observe all models - reactive data stream
    /// - Returns: Publisher that emits fresh data on every repository change
    /// - Usage: viewModel can subscribe to auto-update when data changes
    public func observeAll() -> AnyPublisher<[Model], Never> {
        // Start with current data
        let currentData = (try? fetchAll()) ?? []

        // React to create/delete events (full fetch needed)
        let createDeletePublisher = changePublisher
            .filter { change in
                switch change {
                case .created, .deleted, .batchChange: return true
                case .updated: return false
                }
            }
            .throttle(for: .milliseconds(100), scheduler: DispatchQueue.main, latest: true)
            .compactMap { [weak self] _ in
                try? self?.fetchAll()
            }

        // React to update events (optimized: scan maintains state immutably)
        let updateEventsPublisher = updatePublisher
            .scan(currentData) { models, updatedModel -> [Model] in
                var mutableModels = models
                if let index = mutableModels.firstIndex(where: {
                    $0.persistentModelID == updatedModel.persistentModelID
                }) {
                    mutableModels[index] = updatedModel
                    return mutableModels
                }
                // Model not in current list, trigger full refresh via createDeletePublisher
                return models
            }

        return Just(currentData)
            .merge(with: createDeletePublisher)
            .merge(with: updateEventsPublisher)
            .removeDuplicates(by: { old, new in
                old.count == new.count &&
                old.map { $0.persistentModelID } == new.map { $0.persistentModelID }
            })
            .eraseToAnyPublisher()
    }

    // MARK: - Initialization

    public init(context: ModelContext) {
        self.context = context
    }

    // MARK: - CRUD Operations

    public func create(_ model: Model) throws {
        // Only insert if model is not already in this context
        // SwiftData crashes if you try to insert a model that's already inserted
        // Use identity comparison (===) to check if it's the exact same context
        if model.modelContext !== context {
            context.insert(model)
        }
        try save()
        changeSubject.send(.created(model))
    }

    public func fetch(
        predicate: Predicate<Model>? = nil,
        sortBy: [SortDescriptor<Model>] = []
    ) throws -> [Model] {
        let descriptor = FetchDescriptor<Model>(
            predicate: predicate,
            sortBy: sortBy
        )
        return try context.fetch(descriptor)
    }

    public func fetchAll() throws -> [Model] {
        return try fetch(predicate: nil, sortBy: [])
    }

    public func fetchById(_ id: PersistentIdentifier) throws -> Model? {
        return context.model(for: id) as? Model
    }

    public func update(_ model: Model) throws {
        try save()
        changeSubject.send(.updated(model))
        updateSubject.send(model)
    }

    public func delete(_ model: Model) throws {
        let modelId = model.persistentModelID
        context.delete(model)
        try save()
        changeSubject.send(.deleted(modelId))
    }

    public func deleteAll() throws {
        let all = try fetchAll()
        for model in all {
            context.delete(model)
        }
        try save()
        changeSubject.send(.batchChange)
    }

    public func count(predicate: Predicate<Model>? = nil) throws -> Int {
        let descriptor = FetchDescriptor<Model>(predicate: predicate)
        return try context.fetchCount(descriptor)
    }

    // MARK: - Private Methods

    private func save() throws {
        if context.hasChanges {
            try context.save()
        }
    }
}
