//
//  ClassViewModel.swift
//  KanjiDemo - Class ViewModel
//
//  职责：管理 Class 相关的 UI 状态
//  业务逻辑已移至 ClassService
//

import Foundation
import Observation
import Combine

@Observable
public class ClassViewModel {
    private let service: ClassService  // 只依赖 Service
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI State

    public var classes: [Class] = []
    public var searchText: String = "" {
        didSet { applyFilters() }
    }
    public var filteredClasses: [Class] = []
    public var isLoadingData: Bool = true
    public var errorMessage: String?

    // MARK: - Initialization

    public init(service: ClassService) {
        self.service = service
        setupReactiveObservation()
    }

    // MARK: - Private Methods

    private func setupReactiveObservation() {
        service.observeClasses()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedClasses in
                guard let self = self else { return }
                self.isLoadingData = false
                self.classes = updatedClasses.sorted { $0.title < $1.title }
                self.applyFilters()
            }
            .store(in: &cancellables)
    }

    private func applyFilters() {
        var result = classes

        if !searchText.isEmpty {
            result = result.filter {
                $0.title.localizedCaseInsensitiveContains(searchText) ||
                $0.subject.localizedCaseInsensitiveContains(searchText)
            }
        }

        filteredClasses = result
    }

    // MARK: - Public Actions (调用 Service)

    /// 获取班级中的学生列表
    public func getStudents(in classItem: Class) -> [Student] {
        return service.getStudentsInClass(classItem)
    }
}
