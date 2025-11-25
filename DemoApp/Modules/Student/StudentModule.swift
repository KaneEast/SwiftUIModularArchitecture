//
//  StudentModule.swift
//  KanjiDemo - Student Feature Module
//

import SwiftUI
import SwiftData

public final class StudentModule {
    private let service: StudentService      // Service 层
    private let viewModel: StudentViewModel
    public let router = ModuleRouter<StudentNavigationDestination>()

    // Cross-module navigation closure
    public var onNavigateToClass: ((Class) -> Void)?

    // Logout closure (optional, injected by AppModule)
    public var onLogout: (() -> Void)?

    public init(dependencyContainer: DependencyContainer, randomUserAPI: RandomUserAPIService) {
        // 1. 创建 Service（业务逻辑层）
        self.service = StudentService(
            repository: dependencyContainer.studentRepository,
            apiService: randomUserAPI
        )

        // 2. 创建 ViewModel（UI 状态层）
        self.viewModel = StudentViewModel(service: service)
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
                onClassTap: { classItem in
                    // Cross-module navigation to ClassModule
                    self.onNavigateToClass?(classItem)
                }
            )
        }
    }
}

public enum StudentNavigationDestination: Hashable, Identifiable {
    case studentDetail(Student)

    public var id: String {
        switch self {
        case .studentDetail(let student):
            return "studentDetail_\(student.persistentModelID)"
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
