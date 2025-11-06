//
//  RouterPath.swift
//  KanjiDemo - Core Module: Navigation State Management
//

import Foundation
import Observation
import SwiftUI

/// Observable path router for NavigationStack
@Observable
public class RouterPath<Destination: Hashable> {
    public var path: [Destination] = []

    public init() {}

    public func navigate(to destination: Destination) {
        DispatchQueue.main.async { [weak self] in
            self?.path.append(destination)
        }
    }

    public func pop() {
        DispatchQueue.main.async { [weak self] in
            guard let self = self, !self.path.isEmpty else { return }
            self.path.removeLast()
        }
    }

    public func popToRoot() {
        DispatchQueue.main.async { [weak self] in
            self?.path = []
        }
    }
}

/// Observable modal router for sheets/fullScreenCover
@Observable
public class ModalRouterPath<Destination: Hashable> {
    public var destination: Destination?

    public init() {}

    public func present(_ destination: Destination) {
        self.destination = destination
    }

    public func dismiss() {
        self.destination = nil
    }
}

/// Navigation style enum
public enum NavigationStyle {
    case push
    case sheet
    case fullScreen
}
