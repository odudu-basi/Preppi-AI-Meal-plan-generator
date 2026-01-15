import Foundation
import UserNotifications
import UIKit

class NotificationService: ObservableObject {
    static let shared = NotificationService()

    @Published var isAuthorized = false
    private let center = UNUserNotificationCenter.current()

    private init() {
        checkAuthorizationStatus()
    }

    // MARK: - Permission Management

    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await MainActor.run {
                isAuthorized = granted
            }

            if granted {
                print("✅ Notification permission granted")
                await scheduleAllNotifications()
            } else {
                print("❌ Notification permission denied")
            }

            return granted
        } catch {
            print("❌ Error requesting notification permission: \(error)")
            return false
        }
    }

    func checkAuthorizationStatus() {
        center.getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
            }
        }
    }

    // MARK: - Schedule All Notifications

    func scheduleAllNotifications() async {
        // Remove all existing notifications first
        center.removeAllPendingNotificationRequests()

        // Schedule daily meal reminders
        await scheduleMealReminders()

        // Schedule weekly meal plan reminder
        await scheduleWeeklyMealPlanReminder()

        print("✅ All notifications scheduled")
    }

    // MARK: - Daily Meal Reminders

    private func scheduleMealReminders() async {
        let mealReminders = [
            (hour: 8, minute: 0, meal: "breakfast", title: "Log your breakfast! 🍳", body: "Track your morning meal to stay on top of your nutrition goals"),
            (hour: 12, minute: 30, meal: "lunch", title: "Time to log lunch! 🥗", body: "Don't forget to log your midday meal"),
            (hour: 18, minute: 0, meal: "dinner", title: "Don't forget to log dinner! 🍽️", body: "Keep your streak going by logging your evening meal")
        ]

        for reminder in mealReminders {
            var dateComponents = DateComponents()
            dateComponents.hour = reminder.hour
            dateComponents.minute = reminder.minute

            let content = UNMutableNotificationContent()
            content.title = reminder.title
            content.body = reminder.body
            content.sound = .default
            content.badge = 1
            content.categoryIdentifier = "MEAL_REMINDER"
            content.userInfo = ["mealType": reminder.meal, "action": "openHome"]

            // Create trigger that repeats daily
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

            let request = UNNotificationRequest(
                identifier: "meal_reminder_\(reminder.meal)",
                content: content,
                trigger: trigger
            )

            do {
                try await center.add(request)
                print("✅ Scheduled \(reminder.meal) reminder for \(reminder.hour):\(String(format: "%02d", reminder.minute))")
            } catch {
                print("❌ Error scheduling \(reminder.meal) reminder: \(error)")
            }
        }
    }

    // MARK: - Weekly Meal Plan Reminder

    private func scheduleWeeklyMealPlanReminder() async {
        var dateComponents = DateComponents()
        dateComponents.weekday = 1 // Sunday
        dateComponents.hour = 14 // 2 PM
        dateComponents.minute = 0

        let content = UNMutableNotificationContent()
        content.title = "Plan your week! 📅"
        content.body = "Set up your meal plan for the week ahead and stay on track with your health goals"
        content.sound = .default
        content.badge = 1
        content.categoryIdentifier = "MEAL_PLAN_REMINDER"
        content.userInfo = ["action": "openHome"]

        // Create trigger that repeats weekly
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        let request = UNNotificationRequest(
            identifier: "weekly_meal_plan",
            content: content,
            trigger: trigger
        )

        do {
            try await center.add(request)
            print("✅ Scheduled weekly meal plan reminder for Sunday 2:00 PM")
        } catch {
            print("❌ Error scheduling weekly meal plan reminder: \(error)")
        }
    }

    // MARK: - Smart Notification Logic

    /// Check if a specific meal has been logged today
    @MainActor
    func shouldSendMealReminder(for mealType: String) -> Bool {
        let today = Date()

        // Check if user has already logged this meal type today
        let loggedMealService = LoggedMealService.shared
        let hasLogged = loggedMealService.hasLoggedMealForDateAndType(today, mealType: mealType)

        if hasLogged {
            print("⏭️ Skipping \(mealType) reminder - already logged")
            return false
        }

        // Check if user has completed this meal in their meal plan
        let streakService = StreakService.shared
        let calendar = Calendar.current
        let normalizedDate = calendar.startOfDay(for: today)

        if let completions = streakService.weekCompletions[normalizedDate] {
            let hasCompleted = completions.contains { $0.mealType == mealType && $0.completion != .none }

            if hasCompleted {
                print("⏭️ Skipping \(mealType) reminder - already completed in meal plan")
                return false
            }
        }

        return true
    }

    // MARK: - Cancel Specific Notifications

    func cancelMealReminder(for mealType: String) {
        center.removePendingNotificationRequests(withIdentifiers: ["meal_reminder_\(mealType)"])
        print("🔕 Cancelled \(mealType) reminder")
    }

    func cancelAllNotifications() {
        center.removeAllPendingNotificationRequests()
        print("🔕 Cancelled all notifications")
    }

    // MARK: - Debug

    func printScheduledNotifications() {
        center.getPendingNotificationRequests { requests in
            print("📋 Scheduled Notifications (\(requests.count)):")
            for request in requests {
                if let trigger = request.trigger as? UNCalendarNotificationTrigger,
                   let nextDate = trigger.nextTriggerDate() {
                    print("  - \(request.identifier): \(request.content.title) at \(nextDate)")
                } else {
                    print("  - \(request.identifier): \(request.content.title)")
                }
            }
        }
    }
}
