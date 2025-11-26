//
//  ClassModule.swift
//  KanjiDemo - Class Feature Module
//

import SwiftUI
import SwiftData

public final class ClassModule {
    private let service: ClassService
    private let viewModel: ClassViewModel
    public let router = ModuleRouter<ClassNavigationDestination>()

    public var onNavigateToStudent: ((Student) -> Void)?

    public init(dependencies: any DependencyProviding) {
        self.service = ClassService(repository: dependencies.classRepository)
        self.viewModel = ClassViewModel(service: service)
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
                onStudentTap: { student in
                    // Cross-module navigation to StudentModule
                    self.onNavigateToStudent?(student)
                }
            )
        }
    }
}

public enum ClassNavigationDestination: Hashable, Identifiable {
    case classDetail(Class)

    public var id: String {
        switch self {
        case .classDetail(let classItem):
            return "classDetail_\(classItem.persistentModelID)"
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
