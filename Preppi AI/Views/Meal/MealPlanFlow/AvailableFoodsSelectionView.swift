import SwiftUI

struct AvailableFoodsSelectionView: View {
    @Binding var flowData: MealPlanFlowData
    let onNext: () -> Void

    @State private var selectedProteins: Set<String> = []
    @State private var selectedCarbs: Set<String> = []
    @State private var selectedFats: Set<String> = []
    @State private var selectedSpices: Set<String> = []

    // Custom items added by user (session-only)
    @State private var customProteins: [String] = []
    @State private var customCarbs: [String] = []
    @State private var customFats: [String] = []
    @State private var customSpices: [String] = []

    // Custom input states
    @State private var showingProteinInput = false
    @State private var showingCarbInput = false
    @State private var showingFatInput = false
    @State private var showingSpiceInput = false
    @State private var customProteinText = ""
    @State private var customCarbText = ""
    @State private var customFatText = ""
    @State private var customSpiceText = ""

    @Environment(\.colorScheme) var colorScheme

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                // Icon
                Circle()
                    .fill(Color.orange.opacity(0.15))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: "basket.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.orange)
                    )
                    .padding(.top, 20)

                // Title
                Text("Select your available foods")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                // Subtitle
                Text("Your meal plan depends on it")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 24)

            // Scrollable content
            ScrollView(showsIndicators: true) {
                VStack(spacing: 24) {
                    // Protein Section
                    foodCategorySection(
                        title: "Protein",
                        subtitle: "Select at least 2",
                        items: AvailableFoodOptions.proteins + customProteins,
                        selectedItems: $selectedProteins,
                        emoji: "🍗"
                    )

                    Divider()
                        .padding(.horizontal, 20)

                    // Carbohydrates Section
                    foodCategorySection(
                        title: "Carbohydrates",
                        subtitle: "Select at least 3",
                        items: AvailableFoodOptions.carbs + customCarbs,
                        selectedItems: $selectedCarbs,
                        emoji: "🍚"
                    )

                    Divider()
                        .padding(.horizontal, 20)

                    // Fats Section
                    foodCategorySection(
                        title: "Fats",
                        subtitle: "Select at least 2",
                        items: AvailableFoodOptions.fats + customFats,
                        selectedItems: $selectedFats,
                        emoji: "🥑"
                    )

                    Divider()
                        .padding(.horizontal, 20)

                    // Spices Section
                    foodCategorySection(
                        title: "Spices & Seasonings",
                        subtitle: "Optional",
                        items: AvailableFoodOptions.spices + customSpices,
                        selectedItems: $selectedSpices,
                        emoji: "🌶️"
                    )

                    // Bottom spacing
                    Color.clear.frame(height: 100)
                }
                .padding(.horizontal, 20)
            }

            // Continue button
            VStack(spacing: 12) {
                // Selection summary
                if totalSelectedCount > 0 {
                    Text("\(totalSelectedCount) item\(totalSelectedCount == 1 ? "" : "s") selected")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Button(action: {
                    // Save selections to flowData
                    flowData.availableProteins = Array(selectedProteins)
                    flowData.availableCarbs = Array(selectedCarbs)
                    flowData.availableFats = Array(selectedFats)
                    flowData.availableSpices = Array(selectedSpices)
                    onNext()
                }) {
                    Text("Continue")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(canContinue ? Color.orange : Color.gray)
                        )
                }
                .disabled(!canContinue)
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
            }
            .background(Color(.systemGroupedBackground))
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            // Pre-load any previously selected items
            if !flowData.availableProteins.isEmpty {
                selectedProteins = Set(flowData.availableProteins)
            }
            if !flowData.availableCarbs.isEmpty {
                selectedCarbs = Set(flowData.availableCarbs)
            }
            if !flowData.availableFats.isEmpty {
                selectedFats = Set(flowData.availableFats)
            }
            if !flowData.availableSpices.isEmpty {
                selectedSpices = Set(flowData.availableSpices)
            }
        }
    }

    // MARK: - Food Category Section
    private func foodCategorySection(
        title: String,
        subtitle: String,
        items: [String],
        selectedItems: Binding<Set<String>>,
        emoji: String
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            // Section header
            HStack {
                Text(emoji)
                    .font(.title3)
                Text(title)
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Spacer()

                Button(action: {
                    if selectedItems.wrappedValue.count == items.count {
                        selectedItems.wrappedValue.removeAll()
                    } else {
                        selectedItems.wrappedValue = Set(items)
                    }
                }) {
                    Text(selectedItems.wrappedValue.count == items.count ? "Deselect all" : "Select all")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.orange)
                }
            }

            Text(subtitle)
                .font(.subheadline)
                .foregroundColor(.secondary)

            // Food items grid
            FlexibleGrid(
                items: items,
                selectedItems: selectedItems
            )

            // "Other" input section
            customInputSection(
                for: title,
                selectedItems: selectedItems
            )
        }
    }

    // MARK: - Custom Input Section
    private func customInputSection(
        for category: String,
        selectedItems: Binding<Set<String>>
    ) -> some View {
        let isShowing: Binding<Bool>
        let customText: Binding<String>

        switch category {
        case "Protein":
            isShowing = $showingProteinInput
            customText = $customProteinText
        case "Carbohydrates":
            isShowing = $showingCarbInput
            customText = $customCarbText
        case "Fats":
            isShowing = $showingFatInput
            customText = $customFatText
        case "Spices & Seasonings":
            isShowing = $showingSpiceInput
            customText = $customSpiceText
        default:
            isShowing = .constant(false)
            customText = .constant("")
        }

        return VStack(spacing: 8) {
            // "Other" button
            Button(action: {
                withAnimation {
                    isShowing.wrappedValue.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "plus.circle.fill")
                        .font(.subheadline)
                    Text("Other")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .foregroundColor(.blue)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.blue.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())

            // Text input field
            if isShowing.wrappedValue {
                VStack(spacing: 8) {
                    HStack(spacing: 8) {
                        TextField("Enter custom item...", text: customText)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocapitalization(.words)

                        Button(action: {
                            let trimmedText = customText.wrappedValue.trimmingCharacters(in: .whitespaces)
                            if !trimmedText.isEmpty {
                                // Add to appropriate custom items array
                                switch category {
                                case "Protein":
                                    customProteins.append(trimmedText)
                                case "Carbohydrates":
                                    customCarbs.append(trimmedText)
                                case "Fats":
                                    customFats.append(trimmedText)
                                case "Spices & Seasonings":
                                    customSpices.append(trimmedText)
                                default:
                                    break
                                }

                                // Automatically select the newly added item
                                selectedItems.wrappedValue.insert(trimmedText)

                                // Clear the text field
                                customText.wrappedValue = ""
                            }
                        }) {
                            Text("Add")
                                .font(.subheadline)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(customText.wrappedValue.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Color.blue)
                                )
                        }
                        .disabled(customText.wrappedValue.trimmingCharacters(in: .whitespaces).isEmpty)
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Helper Properties
    private var totalSelectedCount: Int {
        selectedProteins.count + selectedCarbs.count + selectedFats.count + selectedSpices.count
    }

    private var canContinue: Bool {
        selectedProteins.count >= 2 && selectedCarbs.count >= 3 && selectedFats.count >= 2
    }
}

// MARK: - Flexible Grid Component
struct FlexibleGrid: View {
    let items: [String]
    @Binding var selectedItems: Set<String>

    private let spacing: CGFloat = 8

    var body: some View {
        FlowLayout(spacing: spacing) {
            ForEach(items, id: \.self) { item in
                foodItemChip(item: item)
            }
        }
    }

    private func foodItemChip(item: String) -> some View {
        let isSelected = selectedItems.contains(item)

        return Button(action: {
            if isSelected {
                selectedItems.remove(item)
            } else {
                selectedItems.insert(item)
            }
        }) {
            Text(item)
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(isSelected ? .white : .primary)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(isSelected ? Color.orange : Color(.systemBackground))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(isSelected ? Color.orange : Color.gray.opacity(0.3), lineWidth: 1.5)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Flow Layout (for wrapping items)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(
            in: proposal.replacingUnspecifiedDimensions().width,
            subviews: subviews,
            spacing: spacing
        )
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(
            in: bounds.width,
            subviews: subviews,
            spacing: spacing
        )
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.frames[index].minX, y: bounds.minY + result.frames[index].minY), proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var frames: [CGRect] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var currentX: CGFloat = 0
            var currentY: CGFloat = 0
            var lineHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if currentX + size.width > maxWidth && currentX > 0 {
                    // Move to next line
                    currentX = 0
                    currentY += lineHeight + spacing
                    lineHeight = 0
                }

                frames.append(CGRect(x: currentX, y: currentY, width: size.width, height: size.height))

                lineHeight = max(lineHeight, size.height)
                currentX += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: currentY + lineHeight)
        }
    }
}
