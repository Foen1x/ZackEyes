import Foundation
import Shared
import Testing
@testable import AppLib

@MainActor
struct SettingsViewModelTests {
    @Test
    func generalSettingsPersistAndUpdateLiveUsage() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("zackeyes-settings-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = ConfigStore(directory: directory.path)
        let usage = UsageTracker(projectsDir: directory, codexSessionsDir: nil)
        let model = SettingsViewModel(
            configStore: store,
            usageTracker: usage,
            hasPhysicalNotch: false,
            hookHealthProvider: healthyReport
        )

        model.setVisibility(.whenActive)
        model.setCompactAgent(.codex)
        model.setShowTodayConsumption(false)
        model.setNotifyWaitingForInput(false)

        #expect(store.loadNotchVisibility() == .whenActive)
        #expect(store.loadCompactAgent() == .codex)
        #expect(store.loadShowTodayConsumption() == false)
        #expect(usage.showTodayConsumption == false)
        #expect(store.loadNotifyWaitingForInput() == false)
    }

    @Test
    func appearanceChangesPersistAndThemeResetsSound() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent("zackeyes-settings-test-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let store = ConfigStore(directory: directory.path)
        store.saveNotificationSound("none")
        let model = SettingsViewModel(
            configStore: store,
            usageTracker: UsageTracker(projectsDir: directory, codexSessionsDir: nil),
            hookHealthProvider: healthyReport
        )

        model.setTheme(.f1)
        #expect(store.loadTheme() == .f1)
        #expect(store.loadNotificationSound() == nil)
        #expect(model.notificationSound == BuddyTheme.f1.defaultSoundFile)

        model.setNotificationSound("none")
        #expect(store.loadNotificationSound() == "none")
    }

    private func healthyReport() -> HookHealthReport {
        HookHealthReport(
            claudeHooks: .installed,
            codexHooks: .installed,
            bridgeLauncher: true,
            launcherResolvesApp: true,
            socketReachable: true,
            statusLine: .direct
        )
    }
}
