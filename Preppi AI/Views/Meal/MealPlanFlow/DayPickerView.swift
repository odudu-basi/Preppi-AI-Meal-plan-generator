import SwiftUI

struct DayPickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var flowData: MealPlanFlowData
    let onContinue: () -> Void

    @State private var selectedDates: Set<Date> = []
    @Environment(\.colorScheme) var colorScheme

    // Get the current week dates (7 days starting from today)
    private var weekDates: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: today)
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    // Icon
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Image(systemName: "calendar")
                                .font(.system(size: 36))
                                .foregroundColor(.orange)
                        )
                        .padding(.top, 40)

                    // Title
                    Text("Select your meal plan days")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)

                    // Subtitle
                    Text("Choose up to 7 days for your meal plan")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                .padding(.bottom, 40)

                // Scrollable day selection grid
                ScrollView(showsIndicators: true) {
                    VStack(spacing: 16) {
                        ForEach(weekDates, id: \.self) { date in
                            dayButton(for: date)
                        }

                        // Bottom spacing for scroll
                        Color.clear.frame(height: 20)
                    }
                    .padding(.horizontal, 20)
                }

                // Selected count
                if !selectedDates.isEmpty {
                    Text("\(selectedDates.count) day\(selectedDates.count == 1 ? "" : "s") selected")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 16)
                }

                // Continue button
                Button(action: {
                    // Save selected dates to flowData
                    flowData.selectedDays = Array(selectedDates).sorted()
                    onContinue()
                }) {
                    Text("Continue")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(selectedDates.isEmpty ? Color.gray : Color.orange)
                        )
                }
                .disabled(selectedDates.isEmpty)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.primary)
                    }
                }
            }
        }
        .onAppear {
            // Pre-load any previously selected dates
            if !flowData.selectedDays.isEmpty {
                selectedDates = Set(flowData.selectedDays)
            }
        }
    }

    // MARK: - Day Button
    private func dayButton(for date: Date) -> some View {
        let isSelected = selectedDates.contains(date)
        let calendar = Calendar.current
        let isToday = calendar.isDateInToday(date)

        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE"
        let dayName = dayFormatter.string(from: date)

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"
        let dateString = dateFormatter.string(from: date)

        return Button(action: {
            toggleDate(date)
        }) {
            HStack(spacing: 16) {
                // Selection indicator
                ZStack {
                    Circle()
                        .stroke(isSelected ? Color.orange : Color.gray.opacity(0.3), lineWidth: 2)
                        .frame(width: 24, height: 24)

                    if isSelected {
                        Circle()
                            .fill(Color.orange)
                            .frame(width: 16, height: 16)
                    }
                }

                // Day info
                VStack(alignment: .leading, spacing: 4) {
                    Text(dayName)
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)

                    Text(dateString)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Spacer()

                // Today badge
                if isToday {
                    Text("Today")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(Color.orange)
                        )
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.orange.opacity(0.1) : Color(.systemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(isSelected ? Color.orange : Color.gray.opacity(0.2), lineWidth: 1.5)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }

    // MARK: - Helper Methods
    private func toggleDate(_ date: Date) {
        if selectedDates.contains(date) {
            selectedDates.remove(date)
        } else {
            // Check if we've reached the max of 7
            if selectedDates.count < 7 {
                selectedDates.insert(date)
            }
        }
    }
}
