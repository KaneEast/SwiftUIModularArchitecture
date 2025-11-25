//
//  MockRandomUserAPIService.swift
//  DemoAppTests - Mock API Service for Testing
//
//  Purpose: Mock implementation of RandomUserAPIService that returns predefined data
//  No actual network calls - perfect for fast, isolated testing
//

import Foundation
@testable import DemoApp

/// Mock implementation of RandomUserAPIService for testing
/// Benefits:
/// - No network dependency
/// - Deterministic results
/// - Can simulate success and failure scenarios
/// - Fast execution
public final class MockRandomUserAPIService: RandomUserAPIServiceProtocol {

    // MARK: - Configuration

    /// Control whether the mock should throw an error
    public var shouldThrowError: Bool = false

    /// The error to throw when shouldThrowError is true
    public var errorToThrow: Error = NetworkService.NetworkError.networkError(NSError(domain: "MockError", code: -1))

    /// Predefined mock users to return
    public var mockUsers: [RandomUserResult] = []

    // MARK: - Initialization

    public init(shouldThrowError: Bool = false) {
        self.shouldThrowError = shouldThrowError
        self.mockUsers = Self.createDefaultMockUsers()
    }

    // MARK: - API Methods

    /// Fetch random users (mock implementation)
    public func fetchRandomUsers(count: Int = 5) async throws -> [RandomUserResult] {
        // Simulate slight delay to mimic real API
        try await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds

        if shouldThrowError {
            throw errorToThrow
        }

        // Return requested number of users (or all available if count exceeds mockUsers.count)
        let usersToReturn = min(count, mockUsers.count)
        return Array(mockUsers.prefix(usersToReturn))
    }

    // MARK: - Test Helpers

    /// Reset mock to default state
    public func reset() {
        shouldThrowError = false
        errorToThrow = NetworkService.NetworkError.networkError(NSError(domain: "MockError", code: -1))
        mockUsers = Self.createDefaultMockUsers()
    }

    /// Create a set of default mock users for testing
    private static func createDefaultMockUsers() -> [RandomUserResult] {
        return [
            RandomUserResult(
                name: RandomUserResult.RandomUserName(first: "John", last: "Doe"),
                email: "john.doe@test.com"
            ),
            RandomUserResult(
                name: RandomUserResult.RandomUserName(first: "Jane", last: "Smith"),
                email: "jane.smith@test.com"
            ),
            RandomUserResult(
                name: RandomUserResult.RandomUserName(first: "Alice", last: "Johnson"),
                email: "alice.johnson@test.com"
            ),
            RandomUserResult(
                name: RandomUserResult.RandomUserName(first: "Bob", last: "Williams"),
                email: "bob.williams@test.com"
            ),
            RandomUserResult(
                name: RandomUserResult.RandomUserName(first: "Carol", last: "Brown"),
                email: "carol.brown@test.com"
            )
        ]
    }

    /// Set custom mock users
    public func setMockUsers(_ users: [RandomUserResult]) {
        self.mockUsers = users
    }

    /// Configure mock to simulate network error
    public func simulateNetworkError() {
        shouldThrowError = true
        errorToThrow = NetworkService.NetworkError.networkError(
            NSError(domain: NSURLErrorDomain, code: NSURLErrorNotConnectedToInternet)
        )
    }

    /// Configure mock to simulate server error
    public func simulateServerError(code: Int = 500) {
        shouldThrowError = true
        errorToThrow = NetworkService.NetworkError.serverError(code)
    }

    /// Configure mock to simulate decoding error
    public func simulateDecodingError() {
        shouldThrowError = true
        errorToThrow = NetworkService.NetworkError.decodingError(
            NSError(domain: "DecodingError", code: -1, userInfo: [NSLocalizedDescriptionKey: "Mock decoding error"])
        )
    }
}
