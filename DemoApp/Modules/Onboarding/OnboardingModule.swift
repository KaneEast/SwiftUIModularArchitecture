//
//  OnboardingModule.swift
//  KanjiDemo - Onboarding Feature Module
//

import SwiftUI

public final class OnboardingModule {
    private let viewModel: OnboardingViewModel

    public init(authState: AuthenticationState) {
        self.viewModel = OnboardingViewModel(authState: authState)
    }

    public func rootView() -> some View {
        OnboardingView(viewModel: viewModel)
    }
}

// MARK: - Onboarding View

struct OnboardingView: View {
    @Bindable var viewModel: OnboardingViewModel

    var body: some View {
        VStack {
            TabView(selection: $viewModel.currentPage) {
                ForEach(viewModel.pages.indices, id: \.self) { index in
                    OnboardingPageView(page: viewModel.pages[index])
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            // Bottom Button
            Button(action: handleContinue) {
                Text(viewModel.buttonTitle)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 32)
        }
    }

    private func handleContinue() {
        withAnimation {
            viewModel.handleContinue()
        }
    }
}

// MARK: - Onboarding Page View

struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: page.icon)
                .font(.system(size: 100))
                .foregroundStyle(.blue)

            VStack(spacing: 12) {
                Text(page.title)
                    .font(.title.bold())

                Text(page.description)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()
        }
    }
}

// MARK: - Preview

#Preview {
    OnboardingView(viewModel: OnboardingViewModel(authState: AuthenticationState()))
}
