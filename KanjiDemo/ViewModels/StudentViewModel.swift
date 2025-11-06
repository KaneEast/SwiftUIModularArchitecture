//
//  StudentViewModel.swift
//  KanjiDemo - Student ViewModel
//

import Foundation
import Observation
import Combine

@Observable
public class StudentViewModel {
    private let repository: StudentRepository
    private let randomUserAPI: RandomUserAPIService

    public var students: [Student] = []
    public var searchText: String = "" {
        didSet { applyFilters() }
    }
    public var filteredStudents: [Student] = []
    public var isLoadingFromAPI: Bool = false
    public var isLoadingData: Bool = true
    public var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()

    public init(repository: StudentRepository, randomUserAPI: RandomUserAPIService) {
        self.repository = repository
        self.randomUserAPI = randomUserAPI
        setupReactiveObservation()
    }

    private func setupReactiveObservation() {
        repository.observeAll()
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
        var result = students

        if !searchText.isEmpty {
            result = result.filter {
                $0.name.localizedCaseInsensitiveContains(searchText) ||
                $0.email.localizedCaseInsensitiveContains(searchText)
            }
        }

        filteredStudents = result
    }

    // MARK: - API Integration

    /// Fetch random students from API and save to local database
    public func fetchRandomStudents(count: Int = 5) {
        isLoadingFromAPI = true
        errorMessage = nil

        Task { @MainActor in
            do {
                let randomUsers = try await randomUserAPI.fetchRandomUsers(count: count)

                // Convert API results to Student models
                var createdCount = 0
                for user in randomUsers {
                    let student = Student(
                        name: user.name.full,
                        email: user.email,
                        grade: Int.random(in: 9...12) // Random grade 9-12
                    )

                    do {
                        try repository.create(student)
                        createdCount += 1
                    } catch {
                        print("⚠️ Failed to create student \(user.name.full): \(error)")
                    }
                }

                print("✅ Created \(createdCount)/\(randomUsers.count) students from API")
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
