//
//  AuthComponents.swift
//  Preppi AI
//
//  Created by Oduduabasi Victor on 10/25/25.
//  Extracted from SignInSignUpView.swift for reusability
//

import SwiftUI

// MARK: - Auth Text Field
struct AuthTextField: View {
    let title: String
    @Binding var text: String
    let keyboardType: UIKeyboardType
    let systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            HStack {
                Image(systemName: systemImage)
                    .foregroundColor(.green)
                    .frame(width: 20)

                TextField("Enter \(title.lowercased())", text: $text)
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    .background(Color(.systemBackground))
            )
        }
    }
}

// MARK: - Auth Password Field
struct AuthPasswordField: View {
    let title: String
    @Binding var text: String
    @State private var isSecure = true

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)

            HStack {
                Image(systemName: "lock")
                    .foregroundColor(.green)
                    .frame(width: 20)

                if isSecure {
                    SecureField("Enter \(title.lowercased())", text: $text)
                } else {
                    TextField("Enter \(title.lowercased())", text: $text)
                }

                Button(action: { isSecure.toggle() }) {
                    Image(systemName: isSecure ? "eye" : "eye.slash")
                        .foregroundColor(.gray)
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    .background(Color(.systemBackground))
            )
        }
    }
}

// MARK: - Forgot Password View
struct ForgotPasswordView: View {
    @StateObject private var authService = AuthService.shared
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Text("Reset Password")
                    .font(.title2)
                    .fontWeight(.bold)

                Text("Enter your email address and we'll send you a link to reset your password.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                AuthTextField(
                    title: "Email",
                    text: $email,
                    keyboardType: .emailAddress,
                    systemImage: "envelope"
                )
                .padding(.horizontal)

                if let errorMessage = authService.errorMessage {
                    Text(errorMessage)
                        .font(.caption)
                        .foregroundColor(errorMessage.contains("sent") ? .green : .red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button("Send Reset Link") {
                    Task {
                        await authService.resetPassword(email: email)
                        if authService.errorMessage?.contains("sent") == true {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                dismiss()
                            }
                        }
                    }
                }
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(email.contains("@") ? Color.green : Color.gray)
                )
                .padding(.horizontal)
                .disabled(!email.contains("@") || authService.isLoading)

                Spacer()
            }
            .padding(.top, 40)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - Previews
#Preview("Auth Text Field") {
    AuthTextField(
        title: "Email",
        text: .constant(""),
        keyboardType: .emailAddress,
        systemImage: "envelope"
    )
    .padding()
}

#Preview("Auth Password Field") {
    AuthPasswordField(
        title: "Password",
        text: .constant("")
    )
    .padding()
}

#Preview("Forgot Password") {
    ForgotPasswordView()
}
