//
//  DeepLinkCapable.swift
//  KanjiDemo - Core Module: Deep Link Routing System
//

import Foundation
import SwiftData

// MARK: - Deep Link Protocol

/// Protocol for modules that can handle deep link URLs
/// Example: markdownai://tasks/123 or https://app.com/tasks/create
public protocol DeepLinkCapable {
    /// Handle a deep link URL. Returns true if handled successfully.
    func handleDeepLink(_ url: URL) -> Bool
}

// MARK: - Deep Link Router

/// Central router that delegates deep links to registered modules
public class DeepLinkRouter {
    private var modules: [DeepLinkCapable] = []

    public init() {}

    /// Register a module to handle deep links
    public func register(_ module: DeepLinkCapable) {
        modules.append(module)
        print("📍 DeepLinkRouter: Registered module")
    }

    /// Handle a deep link by delegating to modules
    public func handleDeepLink(_ url: URL) -> Result<Void, DeepLinkError> {
        print("📍 DeepLinkRouter: Handling URL: \(url)")

        for module in modules {
            if module.handleDeepLink(url) {
                print("✅ DeepLinkRouter: URL handled successfully")
                return .success(())
            }
        }

        print("❌ DeepLinkRouter: No module could handle URL")
        return .failure(.invalidURL(url))
    }

    /// Handle URL - use this from SwiftUI .onOpenURL
    public func handleURL(_ url: URL) {
        let result = handleDeepLink(url)
        if case .failure(let error) = result {
            print("❌ DeepLinkRouter: \(error.localizedDescription)")
        }
    }
}

// MARK: - URL Extensions

extension URL {
    /// Extract clean path components (excluding "/")
    var cleanPathComponents: [String] {
        return pathComponents.filter { $0 != "/" }
    }

    /// Check if URL matches a specific host
    func matches(host expectedHost: String) -> Bool {
        return host?.lowercased() == expectedHost.lowercased()
    }

    /// Extract ID from path like "/tasks/123" with prefix "/tasks/"
    func extractID(from pathPrefix: String) -> String? {
        guard path.hasPrefix(pathPrefix) else { return nil }
        let remainingPath = String(path.dropFirst(pathPrefix.count))
        return remainingPath.isEmpty ? nil : remainingPath
    }
}

// MARK: - Deep Link Error

public enum DeepLinkError: Error, LocalizedError {
    case invalidURL(URL)
    case navigationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidURL(let url):
            return "No module could handle URL: \(url)"
        case .navigationFailed(let reason):
            return "Navigation failed: \(reason)"
        }
    }
}

// MARK: - PersistentIdentifier Extension

extension PersistentIdentifier {
    /// Create PersistentIdentifier from base64 string
    static func fromString(_ string: String) -> PersistentIdentifier? {
        guard let data = Data(base64Encoded: string),
              let identifier = try? JSONDecoder().decode(PersistentIdentifier.self, from: data) else {
            return nil
        }
        return identifier
    }

    /// Convert PersistentIdentifier to URL-safe string
    var stringValue: String {
        guard let data = try? JSONEncoder().encode(self),
              let base64String = data.base64EncodedString()
                .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) else {
            return ""
        }
        return base64String
    }
}
