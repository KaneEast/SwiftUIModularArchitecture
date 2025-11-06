//
//  ClassViewModel.swift
//  KanjiDemo - Class ViewModel
//

import Foundation
import Observation
import Combine

@Observable
public class ClassViewModel {
    private let repository: ClassRepository

    public var classes: [Class] = []
    public var searchText: String = "" {
        didSet { applyFilters() }
    }
    public var filteredClasses: [Class] = []
    public var isLoadingData: Bool = true
    public var errorMessage: String?

    private var cancellables = Set<AnyCancellable>()

    public init(repository: ClassRepository) {
        self.repository = repository
        setupReactiveObservation()
    }

    private func setupReactiveObservation() {
        repository.observeAll()
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
}
