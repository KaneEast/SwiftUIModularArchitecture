# SwiftUI Modular Architecture

## Why Module-First Architecture?

In **UIKit**, the `ViewController` was the first-class citizen - it orchestrated business logic, navigation, and lifecycle management.

In **SwiftUI**, the `View` became the natural first-class citizen - but this creates problems for advanced and complex projects:
- Views are meant to be lightweight and declarative
- Business logic scattered across views becomes hard to maintain
- Cross-feature navigation and coordination becomes tangled
- Testing and reusability suffer

**This architecture introduces Modules as the first-class citizen** - a pattern that scales naturally for production apps.

---

## Demo: Student-Class Management

Complete production architecture demo with **many-to-many relationships** and **cross-module navigation**.

## Features Demonstrated

### ✅ SwiftData with Repository Pattern (Dataset Observable)
- No Database related code on SwfitUI View

### ✅ Modular Navigation
- Programatic Navigation
- DeepLink Handling

### ✅ AppModule Orchestration
- Coordinates multiple feature modules

## Architecture: Module as First Class

### What is a Module?

A **Module** is a self-contained feature unit that owns:
- **Navigation Logic** (Router with type-safe routes)
- **Multiple ViewModels** (not just one like ViewController)
- **Multiple Views** (List, Detail, etc. - all lightweight UI)
- **Public Interface** (closure-based contracts for cross-module communication)

**Modules are NOT just ViewControllers renamed** - they're an evolution:
- ViewController = 1 controller : 1 view (tight coupling)
- **Module = 1 orchestrator : N viewmodels : M views** (clean separation)

Modules orchestrate **entire features**, not individual screens.

```
App
    ↓
DependencyContainer
    ├── Repository
    └── APIService
    ↓
AppModule (Orchestrates cross-module communication)
    ├── StudentModule (First-class feature)
    │   ├── Router (Navigation logic)
    │   ├── ViewModel (Business logic)
    │   ├── ListView (Lightweight UI)
    │   └── DetailView (Lightweight UI)
    │
    └── ClassModule (First-class feature)
        ├── Router (Navigation logic)
        ├── ViewModel (Business logic)
        ├── ListView (Lightweight UI)
        └── DetailView (Lightweight UI)
```

## Cross-Module Navigation

The key innovation is **cross-module navigation via closures**:

```swift
// In AppModule.setupCrossModuleNavigation()

// Student → Class
studentModule.onNavigateToClass = { [weak self] classItem in
    self?.selectedTab = .classes  // Switch tab
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        self?.classModule.router.navigate(to: .classDetail(classItem))
    }
}

// Class → Student
classModule.onNavigateToStudent = { [weak self] student in
    self?.selectedTab = .students  // Switch tab
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        self?.studentModule.router.navigate(to: .studentDetail(student))
    }
}
```

## Module-First: Beyond ViewController and View-First

| Aspect | UIKit ViewController | SwiftUI View-First | **Module-First** |
|--------|---------------------|-------------------|------------------|
| **Granularity** | 1 screen | Single View | **Entire feature** |
| **Navigation** | Mixed in controller | Scattered in Views | **Centralized Router** |
| **Scope** | 1 ViewController : 1 View | N Views (no coordinator) | **1 Module : N ViewModels : M Views** |
| **Cross-Feature Nav** | Tight coupling via protocols | Direct View dependencies | **Closure-based contracts** |
| **Business Logic** | Mixed in ViewController | Mixed in Views | **Isolated in ViewModels** |
| **Testing** | Need to test controller+view | Need to render Views | **Test Module independently** |
| **Coordinator** | Manual Coordinator pattern | No standard solution | **Built-in AppModule** |

**Key Insight**: Module is not ViewController++, it's a **feature-level orchestrator** that scales beyond screen-level control.

### Example: The Problem with View-First

```swift
// ❌ View-First: Navigation logic leaks into Views
struct StudentDetailView: View {
    var body: some View {
        NavigationLink(destination: ClassDetailView(class: student.class)) {
            // Now StudentDetailView depends on ClassDetailView!
            // Business logic mixed with UI!
        }
    }
}
```

### Solution: Module-First Pattern

```swift
// ✅ Module-First: Module owns navigation, View stays pure
class StudentModule {
    var onNavigateToClass: ((Class) -> Void)?  // Public contract

    func handleClassTap(_ classItem: Class) {
        onNavigateToClass?(classItem)  // Module handles logic
    }
}

// View is just UI
struct StudentDetailView: View {
    let onClassTap: (Class) -> Void  // Receives closure

    var body: some View {
        Button("View Class") { onClassTap(student.class) }
    }
}
```

## Architecture Benefits

### Reactive Updates
```swift
// ViewModel subscribes once
repository.observeAll()
    .sink { students in
        self.students = students  // Auto-update!
    }

// Anywhere in app:
repository.create(student)  // ViewModel updates automatically!
```

### Cross-Module Navigation
```swift
// Module exposes navigation closure
var onNavigateToClass: ((Class) -> Void)?

// AppModule wires it up
studentModule.onNavigateToClass = { classItem in
    self.classModule.router.navigate(to: .classDetail(classItem))
}
```

## Why This Matters for Production Apps

### SwiftUI's View-First Limitation

Apple's SwiftUI naturally promotes **View as the first-class citizen** because:
- Views are structs (lightweight, value types)
- SwiftUI's declarative syntax makes Views easy to compose
- Samples and tutorials focus on View-centric patterns

**This works great for simple apps**, but falls apart when you need:
- Deep linking across features
- Complex multi-step workflows
- Shared business logic
- Independent module development
- Comprehensive testing

### Module-First: The Missing Pattern

By elevating **Module to first-class citizen**, we get:

1. **Clear Separation of Concerns**
   - Views = UI declaration only
   - Modules = Feature orchestration
   - AppModule = Cross-feature coordination

2. **Beyond ViewController Limitations**
   - ViewController: Orchestrates 1 screen with tight View coupling
   - **Module: Orchestrates entire feature** with multiple ViewModels/Views
   - Better separation: Router (navigation) + ViewModels (logic) + Views (UI)

3. **Production-Ready Patterns**
   - ✅ AppModule orchestration
   - ✅ DependencyContainer for injection
   - ✅ BaseRepository with Combine
   - ✅ Type-safe navigation via Router
   - ✅ Cross-module communication via closures
   - ✅ Testable without UI rendering

**This is the architecture that scales from demo to production.**

---

## How Does This Compare to TCA (The Composable Architecture)?

Both architectures solve the "SwiftUI View-First" problem, but with fundamentally different philosophies:

### Philosophy & Approach

| Aspect | Module-First (This) | TCA |
|--------|-------------------|-----|
| **Core Abstraction** | Feature-level Module orchestrator | Store + Reducer state machine |
| **State Management** | Observable ViewModels + Combine | Single Store with Actions/Reducers |
| **Paradigm** | **Object-Oriented + Reactive** | **Functional + Unidirectional** |
| **Learning Curve** | Gentle (familiar OOP patterns) | Steep (requires functional thinking) |
| **Boilerplate** | Minimal (classes + closures) | Significant (Actions, Reducers, Effects) |
| **Navigation** | Module Router + closures | NavigationStack reducers |
| **Cross-Module Communication** | Direct closure calls | Effects + Actions |
| **Testing** | Standard XCTest + mocks | Reducer logic tests (deterministic) |
| **Dependencies** | DependencyContainer (any DI) | TCA's Dependency system (controlled) |

### Code Comparison: Adding a Student

#### Module-First (This Architecture)
```swift
// In ViewModel - simple, direct
func addStudent(name: String) {
    let student = Student(name: name, email: "\(name)@school.edu", grade: 10)
    try? repository.create(student)
    // Observable repository automatically updates UI
}

// Cross-module navigation - just a closure
onNavigateToClass?(selectedClass)
```

#### TCA
```swift
// 1. Define Action
enum Action {
    case addStudent(name: String)
    case studentAdded(Student)
    case navigateToClass(Class)
}

// 2. Define Reducer
func reduce(into state: inout State, action: Action) -> Effect<Action> {
    switch action {
    case .addStudent(let name):
        let student = Student(name: name, ...)
        return .run { send in
            try await repository.create(student)
            await send(.studentAdded(student))
        }
    case .studentAdded(let student):
        state.students.append(student)
        return .none
    case .navigateToClass(let class):
        // More reducer logic...
        return .none
    }
}
```

### When to Choose Each?

#### Choose Module-First if you want:
- ✅ **Fast development** - Less ceremony, familiar OOP patterns
- ✅ **Gradual adoption** - Easy to integrate into existing projects
- ✅ **Flexible state** - ViewModels + Combine + any data layer
- ✅ **Simple navigation** - Closures and routers feel natural
- ✅ **Team familiarity** - Most iOS devs know OOP + MVVM patterns

#### Choose TCA if you want:
- ✅ **Complete testability** - Every state change is deterministic
- ✅ **Time travel debugging** - TCA provides built-in tooling
- ✅ **Strict unidirectional flow** - Enforced at compile time
- ✅ **Complex state machines** - Reducers excel at complex logic
- ✅ **Functional paradigm** - Team comfortable with FP concepts