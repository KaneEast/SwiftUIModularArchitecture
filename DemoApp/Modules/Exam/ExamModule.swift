//
//  ExamModule.swift
//  DemoApp - Exam Feature Module
//
//  Purpose: Module assembler for Exam feature
//  Manages dependencies, navigation, and cross-module communication
//

import SwiftUI
import SwiftData

public final class ExamModule {
    private let service: ExamService
    private let viewModel: ExamViewModel
    public let router = ModuleRouter<ExamNavigationDestination>()

    // Cross-module navigation closures
    public var onNavigateToStudent: ((Student) -> Void)?
    public var onNavigateToClass: ((Class) -> Void)?

    public init(dependencies: any DependencyProviding) {
        // 1. Create Service (business logic layer)
        self.service = ExamService(repository: dependencies.examRepository)

        // 2. Create ViewModel (UI state layer)
        self.viewModel = ExamViewModel(service: service)
    }

    public func rootView() -> some View {
        ExamListView(viewModel: viewModel, navigation: router.nav)
            .routerModifier(router: router) { destination in
                self.destinationView(for: destination)
            }
    }

    @ViewBuilder
    private func destinationView(for destination: ExamNavigationDestination) -> some View {
        switch destination {
        case .examDetail(let exam):
            ExamDetailView(
                exam: exam,
                onStudentTap: { student in
                    // Cross-module navigation to StudentModule
                    self.onNavigateToStudent?(student)
                },
                onClassTap: { classItem in
                    // Cross-module navigation to ClassModule
                    self.onNavigateToClass?(classItem)
                }
            )
        }
    }
}

public enum ExamNavigationDestination: Hashable, Identifiable {
    case examDetail(Exam)

    public var id: String {
        switch self {
        case .examDetail(let exam):
            return "examDetail_\(exam.persistentModelID)"
        }
    }
}

extension ExamModule: DeepLinkCapable {
    public func handleDeepLink(_ url: URL) -> Bool {
        guard url.matches(host: "exams") || url.path.hasPrefix("/exams") else {
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
