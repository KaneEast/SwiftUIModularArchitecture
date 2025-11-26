//
//  DemoApp.swift
//  Student-Class Management Demo
//
//  Demonstrates:
//  - Many-to-many relationships (Student ↔ Class)
//  - Cross-module navigation
//  - AppModule orchestration
//  - Shared repository instances
//  - Reactive Combine updates
//

import SwiftUI
import SwiftData

@main
struct DemoApp: App {
    let modelContainer: ModelContainer
    let authState: AuthenticationState
    let appModule: AppModule

    init() {
        do {
            // Setup SwiftData with both models
            modelContainer = try ModelContainer(for: Student.self, Class.self)

            // Create authentication state
            authState = AuthenticationState()

            // Create dependency container
            let dependencyContainer = DependencyContainer(
                modelContext: modelContainer.mainContext
            )

            // Create app module (orchestrates everything)
            appModule = AppModule(
                dependencies: dependencyContainer,
                authState: authState
            )

            print("🚀 Student-Class Demo initialized")
        } catch {
            fatalError("Failed to initialize app: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            appModule.rootView()
        }
        .modelContainer(modelContainer)
    }
}

/*
 ARCHITECTURE FEATURES:
 
 ✅ Many-to-Many Relationships
    - Student has many Classes
    - Class has many Students
    - Bidirectional navigation
 
 ✅ Cross-Module Navigation
    - StudentModule → ClassModule (tap class from student detail)
    - ClassModule → StudentModule (tap student from class detail)
    - Switches tabs automatically!
 
 ✅ AppModule Orchestration
    - Coordinates both feature modules
    - Sets up cross-navigation closures
    - Manages shared dependencies
 
 ✅ Reactive Updates (Combine)
    - Shared repository instances
    - observeAll() auto-updates views
    - No manual refresh needed
 
 SAMPLE DATA:
 
 Students:
 - Alice (Grade 10): Math, Physics, English
 - Bob (Grade 11): Math, Chemistry
 - Charlie (Grade 10): Physics, Chemistry, English
 - Diana (Grade 12): Math, Physics, Chemistry, English
 
 Classes:
 - Advanced Mathematics (Room 101): Alice, Bob, Diana
 - Physics I (Room 202): Alice, Charlie, Diana
 - Chemistry Fundamentals (Room 303): Bob, Charlie, Diana
 - English Literature (Room 104): Alice, Charlie
 
 TRY IT:
 1. Tap Alice → See her 3 classes
 2. Tap "Physics I" → Switches to Classes tab, shows Physics detail
 3. See Charlie and Diana also enrolled
 4. Tap "Charlie" → Switches back to Students tab, shows Charlie's detail
 */
