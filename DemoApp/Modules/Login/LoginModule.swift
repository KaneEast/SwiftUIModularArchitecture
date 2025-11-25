//
//  LoginModule.swift
//  KanjiDemo - Login Feature Module
//

import SwiftUI

public final class LoginModule {
    private let viewModel: LoginViewModel

    public init(authState: AuthenticationState) {
        self.viewModel = LoginViewModel(authState: authState)
    }

    public func rootView() -> some View {
        LoginView(viewModel: viewModel)
    }
}

// MARK: - Login View

struct LoginView: View {
    @Bindable var viewModel: LoginViewModel

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            // Logo/Title
            VStack(spacing: 8) {
                Image(systemName: "graduationcap.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)

                Text("Welcome Back")
                    .font(.largeTitle.bold())

                Text("Login to access your classes")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Login Form
            VStack(spacing: 16) {
                TextField("Email", text: $viewModel.email)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.emailAddress)
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)

                SecureField("Password", text: $viewModel.password)
                    .textFieldStyle(.roundedBorder)
                    .textContentType(.password)

                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                Button(action: { Task { await viewModel.login() } }) {
                    HStack {
                        if viewModel.isLoading {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Text("Login")
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .disabled(!viewModel.canLogin)
            }
            .padding(.horizontal, 32)

            Spacer()

            // Mock user hint
            VStack(spacing: 8) {
                Text("Demo Mode")
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)

                Text("Enter any email and password to continue")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .multilineTextAlignment(.center)
            }
            .padding(.bottom, 32)
        }
        .padding()
    }
}

// MARK: - Preview

#Preview {
    LoginView(viewModel: LoginViewModel(authState: AuthenticationState()))
}
