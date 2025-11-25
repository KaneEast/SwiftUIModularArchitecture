//
//  OnboardingViewModel.swift
//  KanjiDemo - Onboarding View Model
//

import Foundation
import Observation

@Observable
public final class OnboardingViewModel {
    private let authState: AuthenticationState

    // MARK: - Published State
    public var currentPage: Int = 0

    // MARK: - Data
    public let pages: [OnboardingPage] = [
        OnboardingPage(
            icon: "person.2.fill",
            title: "Manage Students",
            description: "Keep track of all your students in one place"
        ),
        OnboardingPage(
            icon: "book.fill",
            title: "Organize Classes",
            description: "Create and manage classes with ease"
        ),
        OnboardingPage(
            icon: "arrow.triangle.branch",
            title: "Cross-Module Navigation",
            description: "Experience seamless navigation between features"
        )
    ]

    // MARK: - Computed Properties
    public var isLastPage: Bool {
        currentPage == pages.count - 1
    }

    public var buttonTitle: String {
        isLastPage ? "Get Started" : "Continue"
    }

    public init(authState: AuthenticationState) {
        self.authState = authState
    }

    // MARK: - Actions

    public func handleContinue() {
        if isLastPage {
            authState.completeOnboarding()
        } else {
            currentPage += 1
        }
    }
}

// MARK: - Models

public struct OnboardingPage {
    public let icon: String
    public let title: String
    public let description: String

    public init(icon: String, title: String, description: String) {
        self.icon = icon
        self.title = title
        self.description = description
    }
}
