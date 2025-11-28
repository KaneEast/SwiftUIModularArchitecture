//
//  ModuleFactory.swift
//  KanjiDemo - Core Module: Centralized Module Factory
//
//  Purpose: Singleton factory for creating child/reusable modules
//  Eliminates duplicate module creation code across parent modules
//

import Foundation

/// Centralized factory for creating child modules
/// Benefits:
/// - No code duplication (DRY principle)
/// - Single source of truth for module instantiation
/// - Easy to add new reusable modules
public final class ModuleFactory {

    /// Shared singleton instance
    public static let shared = ModuleFactory()

    /// Dependencies injected during app initialization
    private var dependencies: (any DependencyProviding)?

    private init() {}

    /// Initialize factory with dependencies
    /// Should be called once during app setup
    public func initialize(dependencies: any DependencyProviding) {
        self.dependencies = dependencies
    }

    // MARK: - Module Creation Methods

    /// Create a new ExamModule instance
    /// Used by StudentModule and ClassModule to display exams
    public func createExamModule() -> ExamModule {
        guard let dependencies = dependencies else {
            fatalError("ModuleFactory not initialized. Call initialize(dependencies:) in AppModule.")
        }
        return ExamModule(dependencies: dependencies)
    }

    // MARK: - Future Modules

    // Add more factory methods here as you create new reusable modules:
    // public func createNotificationModule() -> NotificationModule { ... }
    // public func createSettingsModule() -> SettingsModule { ... }
}
