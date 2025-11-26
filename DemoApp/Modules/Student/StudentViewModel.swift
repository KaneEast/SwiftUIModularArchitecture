//
//  StudentViewModel.swift
//  KanjiDemo - Student ViewModel
//
//  职责：管理 Student 相关的 UI 状态
//  业务逻辑已移至 StudentService
//

import Foundation
import Observation
import Combine

@Observable
public class StudentViewModel {
    private let service: StudentService  // 只依赖 Service，不知道 Repository
    private var cancellables = Set<AnyCancellable>()

    // MARK: - UI State

    private(set) var students: [Student] = []
    public var searchText: String = "" {
        didSet { applyFilters() }
    }
    private(set) var filteredStudents: [Student] = []
    private(set) var isLoadingFromAPI: Bool = false
    private(set) var isLoadingData: Bool = true
    public var errorMessage: String?

    // MARK: - Initialization

    public init(service: StudentService) {
        self.service = service
        setupReactiveObservation()
    }

    // MARK: - Private Methods

    private func setupReactiveObservation() {
        service.observeStudents()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updatedStudents in
                guard let self = self else { return }
                self.isLoadingData = false
                self.students = updatedStudents.sorted { $0.name < $1.name }
                self.applyFilters()
            }
            .store(in: &cancellables)
    }

    private func applyFilters() {
        // 调用 Service 的搜索逻辑
        filteredStudents = service.searchStudents(by: searchText, from: students)
    }

    // MARK: - Public Actions (调用 Service)

    /// 从 API 获取随机学生并保存
    public func fetchRandomStudents(count: Int = 5) {
        isLoadingFromAPI = true
        errorMessage = nil

        Task { @MainActor in
            do {
                let createdStudents = try await service.fetchAndSaveRandomStudents(count: count)
                print("✅ Created \(createdStudents.count) students from API")
                isLoadingFromAPI = false

            } catch let error as NetworkService.NetworkError {
                errorMessage = error.errorDescription
                print("❌ API Error: \(error.errorDescription ?? "Unknown")")
                isLoadingFromAPI = false
            } catch {
                errorMessage = "Failed to fetch students: \(error.localizedDescription)"
                print("❌ Error: \(error)")
                isLoadingFromAPI = false
            }
        }
    }
}
