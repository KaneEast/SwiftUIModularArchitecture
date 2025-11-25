//
//  NetworkService.swift
//  KanjiDemo - Core Module: Networking Layer
//

import Foundation
import Combine

/// Generic networking service
/// Benefits:
/// - Type-safe API calls
/// - Error handling
/// - Combine integration
/// - Mockable for testing
public class NetworkService {

    public init() {}
    
    // MARK: - Error Types
    
    public enum NetworkError: Error, LocalizedError {
        case invalidURL
        case invalidResponse
        case decodingError(Error)
        case serverError(Int)
        case networkError(Error)
        
        public var errorDescription: String? {
            switch self {
            case .invalidURL: return "Invalid URL"
            case .invalidResponse: return "Invalid response from server"
            case .decodingError(let error): return "Decoding error: \(error.localizedDescription)"
            case .serverError(let code): return "Server error: \(code)"
            case .networkError(let error): return "Network error: \(error.localizedDescription)"
            }
        }
    }
    
    // MARK: - Generic Request
    
    /// Generic GET request with Combine
    public func fetch<T: Decodable>(
        from urlString: String,
        type: T.Type
    ) -> AnyPublisher<T, NetworkError> {
        
        guard let url = URL(string: urlString) else {
            return Fail(error: NetworkError.invalidURL)
                .eraseToAnyPublisher()
        }
        
        print("🌐 NetworkService: Fetching from \(urlString)")
        
        return URLSession.shared.dataTaskPublisher(for: url)
            .tryMap { data, response -> Data in
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }
                
                guard 200...299 ~= httpResponse.statusCode else {
                    throw NetworkError.serverError(httpResponse.statusCode)
                }
                
                return data
            }
            .decode(type: T.self, decoder: JSONDecoder())
            .mapError { error -> NetworkError in
                if let networkError = error as? NetworkError {
                    return networkError
                } else if error is DecodingError {
                    return .decodingError(error)
                } else {
                    return .networkError(error)
                }
            }
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    // MARK: - Async/Await Version
    
    /// Generic GET request with async/await
    public func fetch<T: Decodable>(
        from urlString: String,
        type: T.Type
    ) async throws -> T {
        
        guard let url = URL(string: urlString) else {
            throw NetworkError.invalidURL
        }
        
        print("🌐 NetworkService: Fetching from \(urlString)")
        
        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.invalidResponse
            }
            
            guard 200...299 ~= httpResponse.statusCode else {
                throw NetworkError.serverError(httpResponse.statusCode)
            }
            
            let decoded = try JSONDecoder().decode(T.self, from: data)
            return decoded
            
        } catch let error as NetworkError {
            throw error
        } catch let decodingError as DecodingError {
            throw NetworkError.decodingError(decodingError)
        } catch {
            throw NetworkError.networkError(error)
        }
    }
}

// MARK: - Random User API Models

/// Response from randomuser.me API
public struct RandomUserResponse: Decodable {
    public let results: [RandomUserResult]
}

public struct RandomUserResult: Decodable {
    public let name: RandomUserName
    public let email: String
    
    public struct RandomUserName: Decodable {
        public let first: String
        public let last: String
        
        public var full: String {
            "\(first) \(last)"
        }
    }
}

// MARK: - Random User API Protocol

/// Protocol for Random User API service (enables dependency injection for testing)
public protocol RandomUserAPIServiceProtocol {
    func fetchRandomUsers(count: Int) async throws -> [RandomUserResult]
}

// MARK: - Random User API Service

/// Specific API service for Random User API
public class RandomUserAPIService: RandomUserAPIServiceProtocol {
    private let networkService: NetworkService

    public init(networkService: NetworkService) {
        self.networkService = networkService
    }
    
    /// Fetch random users from API
    public func fetchRandomUsers(count: Int = 5) async throws -> [RandomUserResult] {
        let urlString = "https://randomuser.me/api/?results=\(count)"
        let response = try await networkService.fetch(from: urlString, type: RandomUserResponse.self)
        print("✅ Fetched \(response.results.count) random users")
        return response.results
    }
    
    /// Fetch random users with Combine
    public func fetchRandomUsersPublisher(count: Int = 5) -> AnyPublisher<[RandomUserResult], NetworkService.NetworkError> {
        let urlString = "https://randomuser.me/api/?results=\(count)"
        return networkService.fetch(from: urlString, type: RandomUserResponse.self)
            .map { $0.results }
            .handleEvents(receiveOutput: { results in
                print("✅ Fetched \(results.count) random users")
            })
            .eraseToAnyPublisher()
    }
}
