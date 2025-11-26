# SwiftUI Modular Architecture

**A Module-First SwiftUI Architecture** - Making project development as clear as building with LEGO blocks.

## Core Features

- **🎯 Feature-Level Encapsulation** - Each Module is a complete feature unit containing Service + ViewModel + Views
- **🔗 Decoupled Cross-Module Communication** - Closure-based contract design with zero inter-module dependencies
- **📂 Service Layer for Centralized Business Logic** - Open `Services/` to see all core business logic
- **🧪 Highly Testable** - Service and ViewModel can be tested independently without UI
- **📦 Module-Level Reusability** - Entire folders can be directly migrated to other projects
- **🔐 Complete Authentication Flow** - Onboarding → Login → Main App

**Module-First elevates your architecture from screen-level (ViewController) to feature-level (Module)**

---

## Demo App: Student-Class Management System

A complete production-grade SwiftUI application demonstrating:
- ✅ Many-to-many relationships (Student ↔ Class)
- ✅ Cross-module navigation (Student → Class → Student)
- ✅ Authentication flow (Onboarding → Login → Authenticated)
- ✅ API integration (RandomUser API)
- ✅ SwiftData reactive updates
- ✅ Deep Link support

---

## Project Structure

```
KanjiDemo/
├── Modules/                              ⭐ Organized by Module
│   ├── Student/                          ← All Student module files
│   │   ├── StudentModule.swift           ← Assembler (DI Container)
│   │   ├── StudentService.swift          ← Core business logic
│   │   ├── StudentViewModel.swift        ← UI state management
│   │   ├── StudentListView.swift         ← UI (pure presentation)
│   │   └── StudentDetailView.swift       ← UI (pure presentation)
│   │
│   ├── Class/                            ← All Class module files
│   │   ├── ClassModule.swift
│   │   ├── ClassService.swift
│   │   ├── ClassViewModel.swift
│   │   ├── ClassListView.swift
│   │   └── ClassDetailView.swift
│   │
│   ├── Login/                            ← Login module
│   │   ├── LoginModule.swift
│   │   └── LoginViewModel.swift
│   │
│   └── Onboarding/                       ← Onboarding module
│       ├── OnboardingModule.swift
│       └── OnboardingViewModel.swift
│
├── Core/                                 ← Shared infrastructure
│   ├── Navigation/
│   │   ├── ModuleRouter.swift            ← Unified navigation system
│   │   ├── RouterPath.swift
│   │   └── DeepLinkCapable.swift
│   ├── AuthenticationState.swift        ← Authentication state management
│   ├── BaseRepository.swift             ← Generic Repository base class
│   ├── DependencyContainer.swift        ← Dependency injection container
│   └── NetworkService.swift             ← Network service
│
├── Models/                               ← Shared data models
│   ├── Student.swift
│   └── Class.swift
│
├── Repository/                           ← Data access layer
│   ├── StudentRepository.swift
│   └── ClassRepository.swift
│
└── App/                                  ← Application entry
    ├── AppModule.swift                   ← Top-level module coordinator
    └── DemoApp.swift                     ← App entry point
```

---

## Architecture Layers

### Core Concept: Module-First + Service Layer

```
┌─────────────────────────────────────────────────────┐
│  View (Pure UI)                                     │
│  - Rendering only                                   │
│  - Binds to ViewModel state                         │
└────────────────────┬────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────┐
│  ViewModel (UI State Management - Optional)         │
│  - searchText, isLoading, errorMessage              │
│  - Calls Service methods                            │
│  - Contains NO business logic                       │
└────────────────────┬────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────┐
│  Service: Core Business Logic                       │
│  - fetchAndSaveRandomStudents()                     │
│  - enrollStudent(in: class)                         │
│  - deleteStudent() with business rules              │
│  - Composes Repository + API calls                  │
└────────────────────┬────────────────────────────────┘
                     │
┌────────────────────▼────────────────────────────────┐
│  Repository (Data Access)                           │
│  - create(), update(), delete(), observeAll()       │
│  - Encapsulates SwiftData operations                │
│  - Provides reactive data streams (Combine)         │
└─────────────────────────────────────────────────────┘
                     ▲
                     │
┌────────────────────┴────────────────────────────────┐
│  Module (Assembler - DI Container)                  │
│  1. Creates Service (injects Repository + API)      │
│  2. Creates ViewModel (injects Service)             │
│  3. Provides rootView()                             │
│  4. Exposes cross-module communication closures     │
└─────────────────────────────────────────────────────┘
```

---

## What is a Module?

**A Module is a feature-level self-contained unit**, not a screen-level ViewController.

### What a Module Contains:

1. **Service** - Core business logic for the feature
2. **ViewModel(s)** - UI state management (optional, simple Views can skip it)
3. **View(s)** - Multiple views (ListView, DetailView, etc.)
4. **Router** - Type-safe navigation system
5. **Public Interface** - Closure-based contracts for cross-module communication

### Comparison with ViewController:

| Dimension | ViewController | Module-First |
|------|----------------|--------------|
| **Granularity** | 1 screen | 1 complete feature |
| **Navigation** | Mixed in controller | Unified Router |
| **Business Logic** | Mixed in controller | Separate Service layer |
| **Composition** | 1:1 (controller:view) | 1:N:M (module:viewmodels:views) |
| **Cross-Feature Interaction** | Tightly coupled (protocol/delegate) | Loosely coupled (closure contracts) |
| **Testability** | Requires View rendering | Service can be tested independently |

---

## Example: Complete Flow of StudentModule

### 1. Service - Core Business Logic

```swift
// StudentService.swift - Centrally manages all Student business logic
public final class StudentService {
    private let repository: StudentRepository
    private let apiService: RandomUserAPIService

    // Business logic: Fetch from API and save
    func fetchAndSaveRandomStudents(count: Int) async throws -> [Student] {
        // 1. Call API
        let users = try await apiService.fetchRandomUsers(count: count)

        // 2. Transform data
        let students = users.map { Student(name: $0.name, ...) }

        // 3. Save to database
        for student in students {
            try repository.create(student)
        }

        return students
    }

    // Business logic: Enroll student in class (includes business rules)
    func enrollStudent(_ student: Student, in classItem: Class) throws {
        // Business rule: Check if already enrolled
        guard !student.classes.contains(classItem) else {
            throw StudentServiceError.alreadyEnrolled
        }

        // Business rule: Check class capacity
        guard classItem.students.count < 30 else {
            throw StudentServiceError.classIsFull
        }

        student.classes.append(classItem)
        try repository.update(student)
    }
}
```

### 2. ViewModel - UI State Management

```swift
// StudentViewModel.swift - Manages UI state only
@Observable
public class StudentViewModel {
    private let service: StudentService

    // UI state
    public var students: [Student] = []
    public var searchText: String = ""
    public var isLoadingFromAPI: Bool = false
    public var errorMessage: String?

    // UI logic: Call Service
    public func fetchRandomStudents(count: Int) {
        isLoadingFromAPI = true
        Task {
            do {
                _ = try await service.fetchAndSaveRandomStudents(count: count)
                isLoadingFromAPI = false
            } catch {
                errorMessage = error.localizedDescription
                isLoadingFromAPI = false
            }
        }
    }
}
```

### 3. Module - Assembler

```swift
// StudentModule.swift - Assembles Service + ViewModel + View
public final class StudentModule {
    private let service: StudentService
    private let viewModel: StudentViewModel
    public let router = ModuleRouter<StudentNavigationDestination>()

    // Cross-module communication interface
    public var onNavigateToClass: ((Class) -> Void)?
    public var onLogout: (() -> Void)?

    public init(dependencyContainer: DependencyContainer, randomUserAPI: RandomUserAPIService) {
        // 1. Create Service (business logic layer)
        self.service = StudentService(
            repository: dependencyContainer.studentRepository,
            apiService: randomUserAPI
        )

        // 2. Create ViewModel (UI state layer)
        self.viewModel = StudentViewModel(service: service)
    }

    public func rootView() -> some View {
        StudentListView(viewModel: viewModel, navigation: router.nav)
    }
}
```

### 4. View - Pure UI

```swift
// StudentListView.swift - Rendering only
struct StudentListView: View {
    @Bindable var viewModel: StudentViewModel
    let navigation: NavigationBuilder<StudentNavigationDestination>

    var body: some View {
        List(viewModel.filteredStudents) { student in
            Button(action: { navigation.push(.studentDetail(student)) }) {
                Text(student.name)
            }
        }
        .searchable(text: $viewModel.searchText)
    }
}
```

---