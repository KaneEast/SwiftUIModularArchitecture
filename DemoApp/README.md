# Student-Class Management Demo

Complete production architecture demo with **many-to-many relationships** and **cross-module navigation**.

## Features Demonstrated

### ✅ Many-to-Many Relationships
- Student ↔ Class bidirectional relationship
- SwiftData `@Relationship` with inverse
- Cascading operations

### ✅ Cross-Module Navigation
- StudentModule → ClassModule (tap class from student detail)
- ClassModule → StudentModule (tap student from class detail)
- **Automatic tab switching!**

### ✅ AppModule Orchestration
- Coordinates multiple feature modules
- Sets up cross-navigation via closures
- Manages shared dependencies

### ✅ Reactive Architecture (Combine)
- Shared repository instances via DependencyContainer
- `observeAll()` auto-updates views
- No manual refresh needed

## Architecture

```
KanjiDemoApp
    ↓
DependencyContainer
    ├── studentRepository (shared)
    └── classRepository (shared)
    ↓
AppModule
    ├── StudentModule
    │   ├── StudentViewModel (observes studentRepository)
    │   ├── StudentListView
    │   └── StudentDetailView → onClassTap → ClassModule
    │
    └── ClassModule
        ├── ClassViewModel (observes classRepository)
        ├── ClassListView
        └── ClassDetailView → onStudentTap → StudentModule
```

## Models

### Student
```swift
@Model
class Student {
    var name: String
    var email: String
    var grade: Int
    
    @Relationship(deleteRule: .nullify, inverse: \Class.students)
    var classes: [Class]  // Many-to-many
}
```

### Class
```swift
@Model
class Class {
    var title: String
    var subject: String
    var room: String
    
    @Relationship(deleteRule: .nullify)
    var students: [Student]  // Many-to-many
}
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

### Why This Works:

1. **Module Independence**: Each module doesn't know about the other
2. **AppModule Coordination**: AppModule wires them together
3. **Closure-Based**: Clean, testable, decoupled
4. **Tab Switching**: AppModule controls selectedTab
5. **Type-Safe**: Compiler enforces correct types

## Sample Data

### Students:
- **Alice** (Grade 10): Math, Physics, English
- **Bob** (Grade 11): Math, Chemistry
- **Charlie** (Grade 10): Physics, Chemistry, English
- **Diana** (Grade 12): Math, Physics, Chemistry, English

### Classes:
- **Advanced Mathematics** (Room 101): Alice, Bob, Diana
- **Physics I** (Room 202): Alice, Charlie, Diana
- **Chemistry Fundamentals** (Room 303): Bob, Charlie, Diana
- **English Literature** (Room 104): Alice, Charlie

## Try It!

1. **Launch app** → See 4 students
2. **Tap "Alice Johnson"** → See her details with 3 classes
3. **Tap "Physics I"** → **Switches to Classes tab**, shows Physics detail
4. **See enrolled students**: Alice, Charlie, Diana
5. **Tap "Charlie Brown"** → **Switches back to Students tab**, shows Charlie
6. **See Charlie's classes**: Physics, Chemistry, English

## Architecture Benefits

### ❌ Without AppModule:
```swift
// Student detail needs to know about ClassModule
struct StudentDetailView {
    let classModule: ClassModule  // ❌ Tight coupling!
    
    Button("View Class") {
        classModule.navigate(to: classItem)  // ❌ Direct dependency
    }
}
```

### ✅ With AppModule (This Demo):
```swift
// Student detail only knows about callback
struct StudentDetailView {
    let onClassTap: (Class) -> Void  // ✅ Decoupled!
    
    Button("View Class") {
        onClassTap(classItem)  // ✅ Module doesn't know where it goes
    }
}

// AppModule wires it up
studentModule.onNavigateToClass = { classItem in
    // AppModule decides what happens
    self.selectedTab = .classes
    self.classModule.router.navigate(to: .classDetail(classItem))
}
```

## File Structure

```
KanjiDemo/
├── App/
│   └── AppModule.swift           # Orchestrator with cross-navigation
│
├── Core/
│   ├── DependencyContainer.swift # Shared repositories
│   ├── BaseRepository.swift      # Generic repo + Combine
│   └── Navigation/               # Router system
│
├── Models/
│   ├── Student.swift             # Many-to-many with Class
│   └── Class.swift               # Many-to-many with Student
│
├── Repository/
│   ├── StudentRepository.swift
│   └── ClassRepository.swift
│
├── ViewModels/
│   ├── StudentViewModel.swift    # Reactive with observeAll()
│   └── ClassViewModel.swift      # Reactive with observeAll()
│
├── Views/
│   ├── StudentListView.swift
│   ├── StudentDetailView.swift   # Shows classes, navigates
│   ├── ClassListView.swift
│   └── ClassDetailView.swift     # Shows students, navigates
│
└── Module/
    ├── StudentModule.swift        # onNavigateToClass closure
    └── ClassModule.swift          # onNavigateToStudent closure
```

## Key Patterns

### 1. Shared Repository Instances
```swift
// DependencyContainer ensures ONE instance per model
lazy var studentRepository: StudentRepository = {
    StudentRepository(context: modelContext)
}()

// All modules use THE SAME instance
// This is critical for observeAll() to work!
```

### 2. Reactive Updates
```swift
// ViewModel subscribes once
repository.observeAll()
    .sink { students in
        self.students = students  // Auto-update!
    }

// Anywhere in app:
repository.create(student)  // ViewModel updates automatically!
```

### 3. Cross-Module Navigation
```swift
// Module exposes navigation closure
var onNavigateToClass: ((Class) -> Void)?

// AppModule wires it up
studentModule.onNavigateToClass = { classItem in
    self.classModule.router.navigate(to: .classDetail(classItem))
}
```

## This is Production Architecture! 🎉

Same patterns as MarkdownAI:
- ✅ AppModule orchestration
- ✅ DependencyContainer
- ✅ BaseRepository with Combine
- ✅ Module pattern
- ✅ Type-safe navigation
- ✅ Cross-module coordination
- ✅ Many-to-many relationships

**Enterprise-grade. Battle-tested. Scalable.** 🚀
