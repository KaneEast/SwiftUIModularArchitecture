//
//  StudentModule.swift
//  KanjiDemo - Student Feature Module
//

import SwiftUI
import SwiftData

public final class StudentModule {
    private let dependencies: any DependencyProviding
    private let service: StudentService      // Service 层
    private let viewModel: StudentViewModel
    public let router = ModuleRouter<StudentNavigationDestination>()

    // Cross-module navigation closure
    public var onNavigateToClass: ((Class) -> Void)?

    // Logout closure (optional, injected by AppModule)
    public var onLogout: (() -> Void)?

    public init(dependencies: any DependencyProviding) {
        self.dependencies = dependencies

        // 1. 创建 Service（业务逻辑层）
        self.service = StudentService(
            repository: dependencies.studentRepository,
            apiService: dependencies.randomUserAPI
        )

        // 2. 创建 ViewModel（UI 状态层）
        self.viewModel = StudentViewModel(service: service)
    }

    // MARK: - Child Module Creation (按需创建)

    /// 创建 ExamModule 用于展示学生的 exams
    /// 这展示了模块间的灵活组合：父模块可以按需创建子模块
    public func createExamModule() -> ExamModule {
        return ExamModule(dependencies: dependencies)
    }

    public func rootView() -> some View {
        StudentListView(
            viewModel: viewModel,
            navigation: router.nav,
            onLogout: onLogout
        )
        .routerModifier(router: router) { destination in
            self.destinationView(for: destination)
        }
    }

    @ViewBuilder
    private func destinationView(for destination: StudentNavigationDestination) -> some View {
        switch destination {
        case .studentDetail(let student):
            StudentDetailView(
                student: student,
                router: router,
                onNavigateToClass: onNavigateToClass
            )

        case .examList:
            // 按需创建 ExamModule - 展示父子模块的灵活装配
            // Parent module can create and present child module on demand
            createExamModule().rootView()
        }
    }
}

public enum StudentNavigationDestination: Hashable, Identifiable {
    case studentDetail(Student)
    case examList  // 新增：Exam 列表导航

    public var id: String {
        switch self {
        case .studentDetail(let student):
            return "studentDetail_\(student.persistentModelID)"
        case .examList:
            return "examList"
        }
    }
}

extension StudentModule: DeepLinkCapable {
    public func handleDeepLink(_ url: URL) -> Bool {
        guard url.matches(host: "students") || url.path.hasPrefix("/students") else {
            return false
        }
        let pathComponents = url.cleanPathComponents
        if pathComponents.isEmpty {
            router.popToRoot()
            return true
        }
        return false
    }
}
