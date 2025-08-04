//
//  FeatureRequestView.swift
//  Preppi AI
//
//  Created for feature request and feedback functionality
//

import SwiftUI
import MessageUI

struct FeatureRequestView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var featureRequests: String = ""
    @State private var improvements: String = ""
    @State private var showingMailComposer = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [
                        Color(.systemBackground),
                        Color(.systemGray6).opacity(0.3)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Section
                        headerSection
                        
                        // Feature Request Form
                        formContent
                        
                        // Submit Button
                        submitButton
                        
                        // Bottom spacing
                        Color.clear.frame(height: 50)
                    }
                    .padding()
                }
            }
            .navigationTitle("Feature Requests")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }
            }
        }
        .sheet(isPresented: $showingMailComposer) {
            MailComposeView(
                recipients: ["oduduabasiav@gmail.com", "oduduabasiav@icloud.com"],
                subject: "App Feedback",
                messageBody: createEmailBody()
            )
        }
        .alert("Feedback Status", isPresented: $showingAlert) {
            Button("OK") {
                if alertMessage.contains("sent successfully") {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        VStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple.opacity(0.1), .blue.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
            
            VStack(spacing: 8) {
                Text("Share Your Ideas")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Help us make Preppi AI better by sharing your feedback and feature ideas")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }
    
    // MARK: - Form Content
    private var formContent: some View {
        VStack(spacing: 20) {
            // Feature Requests Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.green)
                        .font(.title3)
                    
                    Text("Feature Requests")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                Text("What features would you like to see in this app?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextEditor(text: $featureRequests)
                    .frame(minHeight: 120)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    .overlay(
                        Group {
                            if featureRequests.isEmpty {
                                VStack {
                                    HStack {
                                        Text("e.g., Dark mode, recipe sharing, meal reminders...")
                                            .foregroundColor(.gray)
                                            .font(.subheadline)
                                            .padding(.top, 20)
                                            .padding(.leading, 16)
                                        Spacer()
                                    }
                                    Spacer()
                                }
                            }
                        }
                    )
            }
            
            // Improvements Section
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "arrow.up.circle.fill")
                        .foregroundColor(.orange)
                        .font(.title3)
                    
                    Text("Improvements")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                }
                
                Text("What could be improved currently in the app?")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                TextEditor(text: $improvements)
                    .frame(minHeight: 120)
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                    .overlay(
                        Group {
                            if improvements.isEmpty {
                                VStack {
                                    HStack {
                                        Text("e.g., Faster loading, better navigation, clearer instructions...")
                                            .foregroundColor(.gray)
                                            .font(.subheadline)
                                            .padding(.top, 20)
                                            .padding(.leading, 16)
                                        Spacer()
                                    }
                                    Spacer()
                                }
                            }
                        }
                    )
            }
        }
        .padding(.horizontal)
    }
    
    // MARK: - Submit Button
    private var submitButton: some View {
        Button {
            submitFeedback()
        } label: {
            HStack {
                Image(systemName: "paperplane.fill")
                    .font(.title3)
                Text("Submit Feedback")
                    .font(.headline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(
                LinearGradient(
                    colors: [.purple, .blue],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(16)
            .shadow(color: .purple.opacity(0.3), radius: 10, x: 0, y: 5)
        }
        .padding(.horizontal)
        .disabled(featureRequests.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
                 improvements.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        .opacity((featureRequests.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && 
                 improvements.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty) ? 0.6 : 1.0)
    }
    
    // MARK: - Helper Functions
    private func submitFeedback() {
        if MFMailComposeViewController.canSendMail() {
            showingMailComposer = true
        } else {
            alertMessage = "Mail app is not available on this device. Please email us directly at oduduabasiav@gmail.com"
            showingAlert = true
        }
    }
    
    private func createEmailBody() -> String {
        var body = "App Feedback from Preppi AI User\n\n"
        
        if !featureRequests.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            body += "FEATURE REQUESTS:\n"
            body += "What features would you like to see in this app?\n\n"
            body += featureRequests.trimmingCharacters(in: .whitespacesAndNewlines)
            body += "\n\n"
        }
        
        if !improvements.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            body += "IMPROVEMENTS:\n"
            body += "What could be improved currently in the app?\n\n"
            body += improvements.trimmingCharacters(in: .whitespacesAndNewlines)
            body += "\n\n"
        }
        
        body += "---\n"
        body += "Sent from Preppi AI iOS App"
        
        return body
    }
}

// MARK: - Mail Compose View
struct MailComposeView: UIViewControllerRepresentable {
    let recipients: [String]
    let subject: String
    let messageBody: String
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let composer = MFMailComposeViewController()
        composer.mailComposeDelegate = context.coordinator
        composer.setToRecipients(recipients)
        composer.setSubject(subject)
        composer.setMessageBody(messageBody, isHTML: false)
        return composer
    }
    
    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let parent: MailComposeView
        
        init(_ parent: MailComposeView) {
            self.parent = parent
        }
        
        func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            parent.dismiss()
        }
    }
}

#Preview {
    FeatureRequestView()
}