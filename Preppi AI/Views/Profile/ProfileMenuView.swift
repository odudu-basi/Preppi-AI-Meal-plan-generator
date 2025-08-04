import SwiftUI

struct ProfileMenuView: View {
    @EnvironmentObject var appState: AppState
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @State private var showingProfileEdit = false
    @State private var showingFeatureRequest = false
    
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
                        // Profile Header
                        profileHeader
                        
                        // Menu Options
                        menuOptions
                        
                        // Bottom safe area spacing
                        Color.clear.frame(height: 50)
                    }
                    .padding()
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.primary)
                }
            }
        }
        .sheet(isPresented: $showingProfileEdit) {
            ProfileView(userData: appState.userData)
                .environmentObject(appState)
        }
        .sheet(isPresented: $showingFeatureRequest) {
            FeatureRequestView()
        }
    }
    
    // MARK: - Profile Header
    private var profileHeader: some View {
        VStack(spacing: 20) {
            // Profile Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 100, height: 100)
                
                Text(appState.userData.name.isEmpty ? "?" : String(appState.userData.name.prefix(1)).uppercased())
                    .font(.system(size: 40, weight: .bold))
                    .foregroundColor(.white)
            }
            
            // User Info
            VStack(spacing: 8) {
                Text(appState.userData.name.isEmpty ? "Welcome!" : appState.userData.name)
                    .font(.title2)
                    .fontWeight(.bold)
                
                if let cookingPref = appState.userData.cookingPreference {
                    HStack {
                        Text(cookingPref.emoji)
                        Text(cookingPref.rawValue)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
        )
    }
    
    // MARK: - Menu Options
    private var menuOptions: some View {
        VStack(spacing: 16) {
            // Edit Profile - Clickable
            MenuOptionRow(
                icon: "person.circle.fill",
                title: "Edit Profile",
                subtitle: "Update your preferences and information",
                iconColor: .blue,
                isClickable: true
            ) {
                showingProfileEdit = true
            }
            
            // Terms of Service - Clickable
            MenuOptionRow(
                icon: "doc.text.fill",
                title: "Terms of Service",
                subtitle: "Read our terms and conditions",
                iconColor: .green,
                isClickable: true
            ) {
                if let url = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
                    openURL(url)
                }
            }
            
            // Privacy Policy - Clickable
            MenuOptionRow(
                icon: "lock.shield.fill",
                title: "Privacy Policy",
                subtitle: "Learn how we protect your data",
                iconColor: .orange,
                isClickable: true
            ) {
                if let url = URL(string: "https://docs.google.com/document/d/1Lm3uLZpbWNJjx1o6I_W6dLgAWMCEaztal7y0fH5zNAU/edit?tab=t.0#heading=h.14nmj5ie8cll") {
                    openURL(url)
                }
            }
            
            // Feature Requests - Clickable
            MenuOptionRow(
                icon: "lightbulb.fill",
                title: "Feature Requests",
                subtitle: "Share your ideas and feedback",
                iconColor: .purple,
                isClickable: true
            ) {
                showingFeatureRequest = true
            }
        }
    }
}

// MARK: - Menu Option Row
struct MenuOptionRow: View {
    let icon: String
    let title: String
    let subtitle: String
    let iconColor: Color
    let isClickable: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: isClickable ? action : {}) {
            HStack(spacing: 16) {
                // Icon
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.1))
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundColor(iconColor)
                }
                
                // Text Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.headline)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Arrow or disabled indicator
                if isClickable {
                    Image(systemName: "chevron.right")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                } else {
                    Text("Soon")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color(.systemGray5))
                        )
                }
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 2)
            )
            .opacity(isClickable ? 1.0 : 0.6)
            .scaleEffect(isClickable ? 1.0 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isClickable)
    }
}

#Preview {
    ProfileMenuView()
        .environmentObject(AppState())
}
