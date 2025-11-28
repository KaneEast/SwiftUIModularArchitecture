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

    public func rootView() -> some View {
        ClassListView(viewModel: viewModel, router: router)
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
            // 按需创建 ExamModule - 通过 ModuleFactory 创建
            // Create ExamModule on-demand via centralized factory
            ModuleFactory.shared.createExamModule().rootView()
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
