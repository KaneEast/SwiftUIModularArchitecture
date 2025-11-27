//
//  ClassModule.swift
//  KanjiDemo - Class Feature Module
//

import SwiftUI
import SwiftData

public final class ClassModule {
    private let dependencies: any DependencyProviding
    private let service: ClassService
    private let viewModel: ClassViewModel
    public let router = ModuleRouter<ClassNavigationDestination>()

    public var onNavigateToStudent: ((Student) -> Void)?

    public init(dependencies: any DependencyProviding) {
        self.dependencies = dependencies
        self.service = ClassService(repository: dependencies.classRepository)
        self.viewModel = ClassViewModel(service: service)
    }

    // MARK: - Child Module Creation (按需创建)

    /// 创建 ExamModule 用于展示班级的 exams
    /// 这展示了模块间的灵活组合：父模块可以按需创建子模块
    public func createExamModule() -> ExamModule {
        return ExamModule(dependencies: dependencies)
    }

    public func rootView() -> some View {
        ClassListView(viewModel: viewModel, navigation: router.nav)
            .routerModifier(router: router) { destination in
                self.destinationView(for: destination)
            }
    }

    @ViewBuilder
    private func destinationView(for destination: ClassNavigationDestination) -> some View {
        switch destination {
        case .classDetail(let classItem):
            ClassDetailView(
                classItem: classItem,
                router: router,
                onNavigateToStudent: onNavigateToStudent
            )

        case .examList:
            // 按需创建 ExamModule - 展示父子模块的灵活装配
            // Parent module can create and present child module on demand
            createExamModule().rootView()
        }
    }
}

public enum ClassNavigationDestination: Hashable, Identifiable {
    case classDetail(Class)
    case examList  // 新增：Exam 列表导航

    public var id: String {
        switch self {
        case .classDetail(let classItem):
            return "classDetail_\(classItem.persistentModelID)"
        case .examList:
            return "examList"
        }
    }
}

extension ClassModule: DeepLinkCapable {
    public func handleDeepLink(_ url: URL) -> Bool {
        guard url.matches(host: "classes") || url.path.hasPrefix("/classes") else {
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
