//
//  ModuleRouter.swift
//  KanjiDemo - Core Module: Unified Navigation Router
//

import Foundation
import SwiftUI

/// Generic router that unifies all navigation types (push, sheet, fullScreen)
/// Benefits:
/// - Single API for all navigation styles
/// - Type-safe navigation destinations
/// - Centralized navigation logic per module
@Observable
public final class ModuleRouter<Destination: Hashable> {

    public var pathRouter = RouterPath<Destination>()
    public var sheetRouter = ModalRouterPath<Destination>()
    public var fullScreenRouter = ModalRouterPath<Destination>()

    public init() {}

    // MARK: - Navigation Methods

    public func navigate(to destination: Destination) {
        pathRouter.navigate(to: destination)
    }

    public func presentSheet(_ destination: Destination) {
        sheetRouter.present(destination)
    }

    public func presentFullScreen(_ destination: Destination) {
        fullScreenRouter.present(destination)
    }

    public func navigate(_ destination: Destination, style: NavigationStyle) {
        switch style {
        case .push:
            pathRouter.navigate(to: destination)
        case .sheet:
            sheetRouter.present(destination)
        case .fullScreen:
            fullScreenRouter.present(destination)
        }
    }

    // MARK: - Dismiss Methods

    public func popToRoot() {
        pathRouter.popToRoot()
    }

    public func pop() {
        pathRouter.pop()
    }

    public func popLast() {
        pathRouter.pop()
    }

    public func dismissSheet() {
        sheetRouter.dismiss()
    }

    public func dismissFullScreen() {
        fullScreenRouter.dismiss()
    }

    public func dismissAll() {
        dismissSheet()
        dismissFullScreen()
    }
}

// MARK: - Navigation Builder (Cleaner API)

/// Provides a cleaner API for navigation
public struct NavigationBuilder<Destination: Hashable> {
    private let router: ModuleRouter<Destination>

    public init(router: ModuleRouter<Destination>) {
        self.router = router
    }

    public func push(_ destination: Destination) {
        router.navigate(destination, style: .push)
    }

    public func sheet(_ destination: Destination) {
        router.navigate(destination, style: .sheet)
    }

    public func fullScreen(_ destination: Destination, disableDefaultAnimation: Bool = false) {
        if disableDefaultAnimation {
            withoutAnimation {
                router.navigate(destination, style: .fullScreen)
            }
        } else {
            router.navigate(destination, style: .fullScreen)
        }
    }
}

extension ModuleRouter {
    public var nav: NavigationBuilder<Destination> {
        NavigationBuilder(router: self)
    }
}

// MARK: - Router Modifier

/// SwiftUI modifier that connects router to navigation views
public struct RouterModifier<Destination: Hashable & Identifiable>: ViewModifier {
    let router: ModuleRouter<Destination>
    let destinationBuilder: (Destination) -> AnyView

    public init(
        router: ModuleRouter<Destination>,
        @ViewBuilder destinationBuilder: @escaping (Destination) -> some View
    ) {
        self.router = router
        self.destinationBuilder = { destination in
            AnyView(destinationBuilder(destination))
        }
    }

    public func body(content: Content) -> some View {
        @Bindable var router = self.router
        content
            .navigationDestination(for: Destination.self) { destination in
                destinationBuilder(destination)
            }
            .sheet(item: $router.sheetRouter.destination) { destination in
                destinationBuilder(destination)
            }
            .fullScreenCover(item: $router.fullScreenRouter.destination) { destination in
                destinationBuilder(destination)
            }
    }
}

extension View {
    public func routerModifier<Destination: Hashable & Identifiable>(
        router: ModuleRouter<Destination>,
        @ViewBuilder destinationBuilder: @escaping (Destination) -> some View
    ) -> some View {
        self.modifier(RouterModifier(router: router, destinationBuilder: destinationBuilder))
    }
}

/// Helper function for disabling animations
public func withoutAnimation(_ body: () -> Void) {
    var transaction = Transaction()
    transaction.disablesAnimations = true
    withTransaction(transaction, body)
}
