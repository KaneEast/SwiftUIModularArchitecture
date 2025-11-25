//
//  LoginViewModel.swift
//  KanjiDemo - Login View Model
//

import Foundation
import Observation

@Observable
public final class LoginViewModel {
    private let authState: AuthenticationState

    // MARK: - Published State
    public var email: String = ""
    public var password: String = ""
    public var isLoading: Bool = false
    public var errorMessage: String?

    // MARK: - Computed Properties
    public var canLogin: Bool {
        !email.isEmpty && !password.isEmpty && !isLoading
    }

    public init(authState: AuthenticationState) {
        self.authState = authState
    }

    // MARK: - Actions

    @MainActor
    public func login() async {
        guard canLogin else { return }

        isLoading = true
        errorMessage = nil

        do {
            try await authState.login(email: email, password: password)
            isLoading = false
            // Success - authState will trigger UI update
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }

    public func clearError() {
        errorMessage = nil
    }
}
