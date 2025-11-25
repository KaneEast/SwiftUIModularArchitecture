# Testing Strategy

## Overview

This project uses **Swift Testing** framework with **in-memory SwiftData storage** for fast, isolated unit tests.

## Key Approach: `isStoredInMemoryOnly: true`

Instead of creating custom mock repositories, we use the **actual repository implementations** with SwiftData's in-memory storage:

```swift
let config = ModelConfiguration(isStoredInMemoryOnly: true)
let container = try! ModelContainer(for: Student.self, Class.self, configurations: config)
```

### Benefits

1. **Tests real code** - We test the actual repository implementation, not mocks
2. **Fast execution** - No disk I/O, everything in memory
3. **Isolated tests** - Each test gets a fresh database
4. **Relationships work** - SwiftData's many-to-many relationships function correctly
5. **No duplication** - Don't need separate mock repository classes

## Test Structure

```
DemoAppTests/
├── Mocks/
│   └── MockRandomUserAPIService.swift       ← Mock API (no network calls)
├── Services/
│   ├── StudentServiceTests.swift            ← Business logic tests (14 tests)
│   └── ClassServiceTests.swift              ← Business logic tests (18 tests)
└── TestHelpers/
    ├── TestDependencyContainer.swift        ← Creates in-memory dependencies
    └── TestDataFactory.swift                ← Helper to create test data
```

## Writing Tests

### Service Tests Example

```swift
@Suite("StudentService Tests")
struct StudentServiceTests {

    private func createService() -> (service: StudentService, repository: StudentRepository, api: MockRandomUserAPIService) {
        // Use real repository with in-memory storage
        let (studentRepo, _) = TestDependencyContainer.createRepositories()
        let apiService = MockRandomUserAPIService()
        let service = StudentService(repository: studentRepo, apiService: apiService)
        return (service, studentRepo, apiService)
    }

    @Test("Enroll student successfully")
    func enrollStudent_success() throws {
        // Given
        let (service, repository, _) = createService()
        let student = TestDataFactory.createStudent(name: "John")
        let classItem = TestDataFactory.createClass(title: "Math 101")
        try repository.create(student)

        // When
        try service.enrollStudent(student, in: classItem)

        // Then
        #expect(student.classes.count == 1)
        #expect(student.classes.first?.title == "Math 101")
    }
}
```

### Key Testing Patterns

1. **Arrange-Act-Assert (Given-When-Then)**
   - Given: Set up test data
   - When: Execute the operation
   - Then: Verify the results

2. **Test Isolation**
   - Each test creates fresh dependencies
   - No shared state between tests
   - Tests can run in parallel

3. **Error Testing**
   ```swift
   #expect(throws: StudentServiceError.alreadyEnrolled) {
       try service.enrollStudent(student, in: classItem)
   }
   ```

4. **Async Testing**
   ```swift
   @Test("Fetch from API")
   func fetchFromAPI() async throws {
       let students = try await service.fetchAndSaveRandomStudents(count: 3)
       #expect(students.count == 3)
   }
   ```

## Mock API Service

The `MockRandomUserAPIService` simulates API calls without network requests:

```swift
let mockAPI = MockRandomUserAPIService()

// Configure success scenario
mockAPI.setMockUsers([/* custom users */])

// Configure error scenarios
mockAPI.simulateNetworkError()
mockAPI.simulateServerError(code: 500)
mockAPI.simulateDecodingError()
```

## Test Data Factory

Use `TestDataFactory` to create consistent test data:

```swift
// Single student
let student = TestDataFactory.createStudent(name: "John", grade: 10)

// Multiple students
let students = TestDataFactory.createStudents(count: 10, grade: 9)

// Student with classes
let (student, classes) = TestDataFactory.createStudentWithClasses(classCount: 3)

// Full class (30 students)
let (classItem, students) = TestDataFactory.createFullClass()
```

## Running Tests

### Via Xcode
1. Open `DemoApp.xcodeproj`
2. Press `Cmd + U` to run all tests
3. Or click the diamond icon next to individual tests

### Via Command Line
```bash
xcodebuild test \
  -project DemoApp.xcodeproj \
  -scheme DemoApp \
  -destination 'platform=iOS Simulator,name=iPhone 15'
```

## Test Coverage

### StudentService (14 tests)
- ✅ Fetch and save from API
- ✅ API error handling
- ✅ Enroll student (success, already enrolled, class full)
- ✅ Delete student (with/without classes)
- ✅ Search students (by name, email, empty query, case insensitive)
- ✅ Observe students (reactive updates)

### ClassService (18 tests)
- ✅ Create class (success, validation errors)
- ✅ Delete class (with/without students)
- ✅ Get students in class
- ✅ Capacity calculations
- ✅ Class full checks
- ✅ Observe classes (reactive updates)

### StudentViewModel (planned)
- ✅ Initialization and data loading
- ✅ Search filtering
- ✅ API call state management
- ✅ Error handling
- ✅ Reactive updates

### ClassViewModel (planned)
- ✅ Initialization and data loading
- ✅ Search filtering
- ✅ Get students for class
- ✅ Reactive updates

## Why This Approach is Better

### ❌ Custom Mock Repositories (what we avoided)
```swift
// Bad: Separate mock implementation
class MockStudentRepository: StudentRepositoryProtocol {
    var storage: [Student] = []
    // Duplicate all repository logic...
}
```

**Problems:**
- Code duplication
- Mocks can diverge from real implementation
- Relationship handling is tricky
- More code to maintain

### ✅ In-Memory Real Repositories (what we use)
```swift
// Good: Use real repositories with in-memory storage
let config = ModelConfiguration(isStoredInMemoryOnly: true)
let container = try! ModelContainer(for: Student.self, Class.self, configurations: config)
let repository = StudentRepository(context: container.mainContext)
```

**Benefits:**
- Tests actual production code
- Relationships work automatically
- Zero code duplication
- Fast and isolated

## Best Practices

1. **One assertion per logical concept**
   ```swift
   #expect(students.count == 3)
   #expect(students[0].name == "John Doe")
   ```

2. **Descriptive test names**
   ```swift
   @Test("Enroll student throws error when already enrolled")
   ```

3. **Test both happy path and error cases**
   - Success scenarios
   - Validation errors
   - Edge cases (empty, full, null)

4. **Use factory methods for test data**
   - Keeps tests clean and readable
   - Consistent data across tests

5. **Clean up is automatic**
   - Each test gets fresh dependencies
   - No manual cleanup needed
   - Memory is freed after each test

## Architecture Benefits for Testing

The **Module-First + Service Layer** architecture makes testing easy:

```
View → ViewModel → Service → Repository
         ↑          ↑          ↑
      Test here  Test here  In-memory
```

1. **Service Layer** - Pure business logic, easy to test
2. **Protocol-based** - Dependency injection ready
3. **No UI dependency** - Test without rendering views
4. **Reactive** - Test data flow with Combine publishers

## Continuous Integration

Tests are designed to run in CI/CD:
- Fast execution (no network, no disk)
- Deterministic results (no flaky tests)
- Parallel execution safe
- No external dependencies

```yaml
# Example CI configuration
- name: Run Tests
  run: |
    xcodebuild test \
      -project DemoApp.xcodeproj \
      -scheme DemoApp \
      -destination 'platform=iOS Simulator,name=iPhone 15' \
      -enableCodeCoverage YES
```
