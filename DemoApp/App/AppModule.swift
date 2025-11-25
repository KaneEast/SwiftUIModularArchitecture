//
//  AppModule.swift
//  KanjiDemo - App Module: Orchestrates Student & Class modules
//

import SwiftUI
import SwiftData
import Observation

@Observable
public final class AppModule {
    public let dependencyContainer: DependencyContainer
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

    public init(dependencyContainer: DependencyContainer, authState: AuthenticationState) {
        self.dependencyContainer = dependencyContainer
        self.authState = authState

        // Initialize authentication modules
        self.loginModule = LoginModule(authState: authState)
        self.onboardingModule = OnboardingModule(authState: authState)

        // Initialize feature modules with network services
        self.studentModule = StudentModule(
            dependencyContainer: dependencyContainer,
            randomUserAPI: dependencyContainer.randomUserAPI
        )
        self.classModule = ClassModule(dependencyContainer: dependencyContainer)

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
        let studentRepo = dependencyContainer.studentRepository
        let classRepo = dependencyContainer.classRepository

        let studentCount = (try? studentRepo.count()) ?? 0
        let classCount = (try? classRepo.count()) ?? 0

        if studentCount == 0 && classCount == 0 {
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
                print("🎉 AppModule: Sample data population complete")
            } catch {
                print("  ❌ Failed to create students: \(error)")
            }
        } else {
            print("📊 AppModule: Found \(studentCount) students, \(classCount) classes")
        }
    }
}

// MARK: - Root View (Matches MarkdownAI's AppView pattern)

struct AppRootView: View {
    @Bindable var appModule: AppModule

    var body: some View {
        // Switch based on authentication state
        switch appModule.authState.status {
        case .onboarding:
            appModule.onboardingModule.rootView()
                .transition(.opacity)

        case .unauthenticated:
            appModule.loginModule.rootView()
                .transition(.opacity)

        case .authenticated:
            authenticatedView
                .transition(.opacity)
        }
    }

    @ViewBuilder
    private var authenticatedView: some View {
        let tabBinding = Binding(
            get: { appModule.selectedTab },
            set: { appModule.selectTab($0) }
        )

        TabView(selection: tabBinding) {
            studentTabView
                .tabItem {
                    Label("Students", systemImage: "person.2.fill")
                }
                .tag(AppModule.Tab.students)

            classTabView
                .tabItem {
                    Label("Classes", systemImage: "book.fill")
                }
                .tag(AppModule.Tab.classes)
        }
        .onOpenURL { url in
            appModule.deepLinkRouter.handleURL(url)
        }
    }
    
    // MARK: - Tab Views (Matches MarkdownAI pattern)
    
    @ViewBuilder
    private var studentTabView: some View {
        @Bindable var router = appModule.studentModule.router.pathRouter
        NavigationStack(path: $router.path) {
            appModule.studentModule.rootView()
        }
    }
    
    @ViewBuilder
    private var classTabView: some View {
        @Bindable var router = appModule.classModule.router.pathRouter
        NavigationStack(path: $router.path) {
            appModule.classModule.rootView()
        }
    }
}
