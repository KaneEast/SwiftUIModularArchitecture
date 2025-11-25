//
//  AppRootView.swift
//  DemoApp
//
//  Created by apay_JUPITER on 2025/11/25.
//

import SwiftUI

// MARK: - Root View (Matches MarkdownAI's AppView pattern)

struct AppRootView: View {
    @Bindable var appModule: AppModule

    var body: some View {
        // Switch based on authentication state
        switch appModule.authState.status {
        case .onboarding:
            appModule.onboardingModule.rootView()
                .transition(.opacity)

        case .unauthenticated:
            appModule.loginModule.rootView()
                .transition(.opacity)

        case .authenticated:
            authenticatedView
                .transition(.opacity)
        }
    }

    @ViewBuilder
    private var authenticatedView: some View {
        let tabBinding = Binding(
            get: { appModule.selectedTab },
            set: { appModule.selectTab($0) }
        )

        TabView(selection: tabBinding) {
            studentTabView
                .tabItem {
                    Label("Students", systemImage: "person.2.fill")
                }
                .tag(AppModule.Tab.students)

            classTabView
                .tabItem {
                    Label("Classes", systemImage: "book.fill")
                }
                .tag(AppModule.Tab.classes)
        }
        .onOpenURL { url in
            appModule.deepLinkRouter.handleURL(url)
        }
    }
    
    // MARK: - Tab Views (Matches MarkdownAI pattern)
    
    @ViewBuilder
    private var studentTabView: some View {
        @Bindable var router = appModule.studentModule.router.pathRouter
        NavigationStack(path: $router.path) {
            appModule.studentModule.rootView()
        }
    }
    
    @ViewBuilder
    private var classTabView: some View {
        @Bindable var router = appModule.classModule.router.pathRouter
        NavigationStack(path: $router.path) {
            appModule.classModule.rootView()
        }
    }
}
