# SwiftData Testing Solution - Container Lifetime Issue

## The Problem

Tests were crashing with `context.container == nil` even though `context.mainContainer != nil`.

### Root Cause

The `ModelContainer` was being created locally in `TestDependencyContainer.createRepositories()` and immediately going out of scope:

```swift
// WRONG - Container gets deallocated immediately!
public static func createRepositories() -> (student: StudentRepository, class: ClassRepository) {
    let container = try! ModelContainer(for: Student.self, Class.self, configurations: config)
    let context = container.mainContext

    let studentRepo = StudentRepository(context: context)
    let classRepo = ClassRepository(context: context)

    return (studentRepo, classRepo)
    // ❌ Container is deallocated here!
    // ❌ context.container becomes nil
    // ❌ All SwiftData operations crash
}
```

When the container was deallocated, `context.container` became `nil`, causing all SwiftData operations (insert, fetch, save) to crash.

## The Solution

**Return and hold the container reference** to keep it alive for the duration of the test:

### 1. Return Container from Helper

```swift
// CORRECT - Return container to keep it alive
public static func createRepositories() -> (
    student: StudentRepository,
    class: ClassRepository,
    container: ModelContainer  // ← Return it!
) {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: Student.self, Class.self, configurations: config)
    let context = container.mainContext

    let studentRepo = StudentRepository(context: context)
    let classRepo = ClassRepository(context: context)

    return (studentRepo, classRepo, container)  // ← Container stays alive!
}
```

### 2. Hold Container Reference in Tests

```swift
@Test("Create class successfully")
func createClass_success() throws {
    // Hold the container reference (even with _ prefix)
    let (service, repository, _container) = createService()

    // Now context.container is NOT nil
    // All SwiftData operations work correctly!
}
```

Even though we use `_container` (underscore prefix to indicate unused), **the variable still holds a strong reference** to the container, keeping it alive for the test's duration.

### 3. Update Helper Methods

```swift
private func createService() -> (
    service: ClassService,
    repository: ClassRepository,
    container: ModelContainer  // ← Return container
) {
    let (_, classRepo, container) = TestDependencyContainer.createRepositories()
    let service = ClassService(repository: classRepo)
    return (service, classRepo, container)  // ← Pass it along
}
```

## Why This Works

1. **Strong Reference**: The `_container` variable holds a strong reference to the `ModelContainer`
2. **ARC (Automatic Reference Counting)**: Swift's ARC keeps the container in memory as long as there's a reference
3. **Test Scope**: The container stays alive for the entire test function scope
4. **Context Validity**: `context.container` remains non-nil throughout the test

## Additional Fixes Applied

### A. Context-Aware TestDataFactory

TestDataFactory immediately inserts models into context:

```swift
public static func createStudent(
    in repository: StudentRepository,  // ← Requires repository
    name: String = "Test Student",
    email: String = "test@student.com",
    grade: Int = 10,
    classes: [Class] = []
) -> Student {
    let student = Student(name: name, email: email, grade: grade)
    student.classes = classes
    repository.context.insert(student)  // ← Immediate insert
    return student
}
```

### B. Double-Insert Prevention

BaseRepository checks if model is already in context:

```swift
public func create(_ model: Model) throws {
    // Only insert if model is not already in this context
    if model.modelContext !== context {
        context.insert(model)
    }
    try save()
    changeSubject.send(.created(model))
}
```

### C. Shared Context for Relationships

Tests with Student-Class relationships use the same context:

```swift
// ✅ CORRECT - Same context
let (studentRepo, classRepo, _container) = TestDependencyContainer.createRepositories()
let service = StudentService(repository: studentRepo, apiService: apiService)

// ❌ WRONG - Different contexts!
let (studentRepo, _, _container1) = TestDependencyContainer.createRepositories()
let (_, classRepo, _container2) = TestDependencyContainer.createRepositories()
// These two contexts can't share relationships!
```

## Summary

The crash was caused by **premature deallocation** of the `ModelContainer`. The solution is to:

1. Return the container from helper functions
2. Hold a reference to it in test functions (even with `_container`)
3. Ensure related models share the same context

This is a fundamental requirement when working with SwiftData's in-memory containers in tests.
