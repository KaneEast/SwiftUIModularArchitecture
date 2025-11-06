//
//  StudentModule.swift
//  KanjiDemo - Student Feature Module
//

import SwiftUI
import SwiftData

public final class StudentModule {
    private let dependencyContainer: DependencyContainer
    private let viewModel: StudentViewModel
    public let router = ModuleRouter<StudentNavigationDestination>()

    // Cross-module navigation closure
    public var onNavigateToClass: ((Class) -> Void)?

    public init(dependencyContainer: DependencyContainer, randomUserAPI: RandomUserAPIService) {
        self.dependencyContainer = dependencyContainer
        self.viewModel = StudentViewModel(
            repository: dependencyContainer.studentRepository,
            randomUserAPI: randomUserAPI
        )
    }

    public func rootView() -> some View {
        StudentListView(viewModel: viewModel, navigation: router.nav)
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
