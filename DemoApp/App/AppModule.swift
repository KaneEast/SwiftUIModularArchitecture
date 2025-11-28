//
//  AppModule.swift
//  KanjiDemo - App Module: Orchestrates Student & Class modules
//

import SwiftUI
import SwiftData
import Observation

@Observable
public final class AppModule {
    public let dependencies: any DependencyProviding
    public let deepLinkRouter = DeepLinkRouter()

    // MARK: - Authentication
    public let authState: AuthenticationState

    // MARK: - Feature Modules
    public let studentModule: StudentModule
    public let classModule: ClassModule
    public let loginModule: LoginModule
    public let onboardingModule: OnboardingModule

    // MARK: - App State
    public var selectedTab: Tab = .students

    public init(dependencies: any DependencyProviding, authState: AuthenticationState) {
        self.dependencies = dependencies
        self.authState = authState

        // Initialize ModuleFactory with dependencies
        ModuleFactory.shared.initialize(dependencies: dependencies)

        // Initialize authentication modules
        self.loginModule = LoginModule(authState: authState)
        self.onboardingModule = OnboardingModule(authState: authState)

        // Initialize feature modules with dependencies
        self.studentModule = StudentModule(dependencies: dependencies)
        self.classModule = ClassModule(dependencies: dependencies)

        // Setup cross-module navigation
        setupCrossModuleNavigation()

        // Setup logout callback
        setupLogoutCallback()

        // Register modules for deep links
        deepLinkRouter.register(studentModule)
        deepLinkRouter.register(classModule)

        // Setup sample data with relationships (only if authenticated)
        if authState.status == .authenticated {
            populateSampleDataIfNeeded()
        }
    }

    // MARK: - Cross-Module Navigation Setup

    private func setupCrossModuleNavigation() {
        // Student → Class navigation
        studentModule.onNavigateToClass = { [weak self] classItem in
            guard let self = self else { return }
            print("📍 Cross-nav: Student → Class: \(classItem.title)")
            // Switch to classes tab and navigate to detail
            self.selectedTab = .classes
            self.classModule.router.popToRoot()
            self.classModule.router.navigate(to: .classDetail(classItem))
        }

        // Class → Student navigation
        classModule.onNavigateToStudent = { [weak self] student in
            guard let self = self else { return }
            print("📍 Cross-nav: Class → Student: \(student.name)")
            // Switch to students tab and navigate to detail
            self.selectedTab = .students
            self.studentModule.router.popToRoot()
            self.studentModule.router.navigate(to: .studentDetail(student))
        }
    }

    // MARK: - Logout Setup

    private func setupLogoutCallback() {
        studentModule.onLogout = { [weak self] in
            guard let self = self else { return }
            print("🔓 Logout requested")
            self.authState.logout()
        }
    }

    // MARK: - Root View
    @ViewBuilder
    public func rootView() -> some View {
        AppRootView(appModule: self)
    }

    // MARK: - Tab Management
    public enum Tab: Hashable {
        case students
        case classes
    }
    
    public func selectTab(_ tab: Tab) {
        selectedTab = tab
    }

    // MARK: - Sample Data Population
    private func populateSampleDataIfNeeded() {
        let studentRepo = dependencies.studentRepository
        let classRepo = dependencies.classRepository
        let examRepo = dependencies.examRepository

        let studentCount = (try? studentRepo.count(predicate: nil)) ?? 0
        let classCount = (try? classRepo.count(predicate: nil)) ?? 0
        let examCount = (try? examRepo.count(predicate: nil)) ?? 0

        if studentCount == 0 && classCount == 0 && examCount == 0 {
            print("🚀 AppModule: Populating sample data with relationships...")

            // Create classes FIRST
            let math = Class(title: "Advanced Mathematics", subject: "Mathematics", room: "101")
            let physics = Class(title: "Physics I", subject: "Physics", room: "202")
            let chemistry = Class(title: "Chemistry Fundamentals", subject: "Chemistry", room: "303")
            let english = Class(title: "English Literature", subject: "English", room: "104")

            // Save classes first
            do {
                try classRepo.create(math)
                try classRepo.create(physics)
                try classRepo.create(chemistry)
                try classRepo.create(english)
                print("  ✅ Created 4 classes")
            } catch {
                print("  ❌ Failed to create classes: \(error)")
                return
            }

            // Create students
            let alice = Student(name: "Alice Johnson", email: "alice@school.edu", grade: 10)
            let bob = Student(name: "Bob Smith", email: "bob@school.edu", grade: 11)
            let charlie = Student(name: "Charlie Brown", email: "charlie@school.edu", grade: 10)
            let diana = Student(name: "Diana Prince", email: "diana@school.edu", grade: 12)

            // Set up relationships
            alice.classes = [math, physics, english]
            bob.classes = [math, chemistry]
            charlie.classes = [physics, chemistry, english]
            diana.classes = [math, physics, chemistry, english]

            // Save students
            do {
                try studentRepo.create(alice)
                try studentRepo.create(bob)
                try studentRepo.create(charlie)
                try studentRepo.create(diana)

                print("  ✅ Created 4 students with class enrollments")
            } catch {
                print("  ❌ Failed to create students: \(error)")
                return
            }

            // Create exams with relationships
            let futureDate1 = Calendar.current.date(byAdding: .day, value: 7, to: Date()) ?? Date()
            let futureDate2 = Calendar.current.date(byAdding: .day, value: 14, to: Date()) ?? Date()
            let pastDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()

            let mathMidterm = Exam(title: "Math Midterm Exam", subject: "Mathematics", date: futureDate1, maxScore: 100, classItem: math)
            let physicsFinal = Exam(title: "Physics Final Exam", subject: "Physics", date: futureDate2, maxScore: 150, classItem: physics)
            let chemistryQuiz = Exam(title: "Chemistry Quiz", subject: "Chemistry", date: pastDate, maxScore: 50, classItem: chemistry)

            // Assign students to exams
            mathMidterm.students = [alice, bob, diana]
            physicsFinal.students = [alice, charlie, diana]
            chemistryQuiz.students = [bob, charlie, diana]

            // Save exams
            do {
                try examRepo.create(mathMidterm)
                try examRepo.create(physicsFinal)
                try examRepo.create(chemistryQuiz)

                print("  ✅ Created 3 exams with student registrations")
                print("🎉 AppModule: Sample data population complete")
            } catch {
                print("  ❌ Failed to create exams: \(error)")
            }
        } else {
            print("📊 AppModule: Found \(studentCount) students, \(classCount) classes, \(examCount) exams")
        }
    }
}

