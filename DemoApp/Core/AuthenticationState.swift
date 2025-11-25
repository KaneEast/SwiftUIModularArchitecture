//
//  AuthenticationState.swift
//  KanjiDemo - Authentication State Management
//

import Foundation
import Observation

/// Global authentication state manager
/// Demonstrates: Global state management that affects module visibility
@Observable
public final class AuthenticationState {

    // MARK: - State

    public enum Status {
        case onboarding      // First time user
        case unauthenticated // Needs login
        case authenticated   // Logged in
    }

    public private(set) var status: Status
    public private(set) var currentUser: User?

    // MARK: - Storage Keys

    private let hasCompletedOnboardingKey = "hasCompletedOnboarding"
    private let userEmailKey = "currentUserEmail"

    // MARK: - Initialization

    public init() {
        // Check if user has completed onboarding
        let hasCompletedOnboarding = UserDefaults.standard.bool(forKey: hasCompletedOnboardingKey)

        // Check if user is logged in (mock check via UserDefaults)
        if let email = UserDefaults.standard.string(forKey: userEmailKey) {
            self.currentUser = User(email: email, name: "Mock User")
            self.status = .authenticated
        } else if hasCompletedOnboarding {
            self.status = .unauthenticated
        } else {
            self.status = .onboarding
        }
    }

    // MARK: - Public Actions

    /// Complete onboarding flow
    public func completeOnboarding() {
        UserDefaults.standard.set(true, forKey: hasCompletedOnboardingKey)
        status = .unauthenticated
    }

    /// Mock login (in real app, would call backend)
    public func login(email: String, password: String) async throws {
        // Simulate network delay
        try await Task.sleep(for: .seconds(1))

        // Mock validation
        guard !email.isEmpty, !password.isEmpty else {
            throw AuthError.invalidCredentials
        }

        // Save user
        let user = User(email: email, name: "User (\(email.split(separator: "@").first ?? ""))")
        UserDefaults.standard.set(email, forKey: userEmailKey)

        // Update state
        await MainActor.run {
            self.currentUser = user
            self.status = .authenticated
        }
    }

    /// Logout
    public func logout() {
        UserDefaults.standard.removeObject(forKey: userEmailKey)
        currentUser = nil
        status = .unauthenticated
    }

    /// Reset all (for testing)
    public func resetAll() {
        UserDefaults.standard.removeObject(forKey: hasCompletedOnboardingKey)
        UserDefaults.standard.removeObject(forKey: userEmailKey)
        currentUser = nil
        status = .onboarding
    }
}

// MARK: - Models

public struct User: Codable, Hashable {
    public let email: String
    public let name: String

    public init(email: String, name: String) {
        self.email = email
        self.name = name
    }
}

public enum AuthError: LocalizedError {
    case invalidCredentials
    case networkError

    public var errorDescription: String? {
        switch self {
        case .invalidCredentials:
            return "Email or password is incorrect"
        case .networkError:
            return "Network connection failed"
        }
    }
}
