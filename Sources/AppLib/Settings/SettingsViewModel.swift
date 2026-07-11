import AppKit
import Combine
import Foundation
import Shared

@MainActor
final class SettingsViewModel: ObservableObject {
    @Published private(set) var visibility: NotchVisibility
    @Published private(set) var compactAgent: AgentKind
    @Published private(set) var showTodayConsumption: Bool
    @Published private(set) var hotkey: HotKeyConfig
    @Published private(set) var theme: BuddyTheme
    @Published private(set) var notificationSound: String
    @Published private(set) var notifyWaitingForInput: Bool
    @Published private(set) var notchOffsetX: CGFloat
    @Published private(set) var hookHealth: HookHealthReport

    let hasPhysicalNotch: Bool

    private let configStore: ConfigStore
    private let usageTracker: UsageTracker
    private let hookHealthProvider: () -> HookHealthReport
    private var previewSound: NSSound?

    init(
        configStore: ConfigStore = ConfigStore(),
        usageTracker: UsageTracker,
        hasPhysicalNotch: Bool = NSScreen.hasAnyNotch,
        hookHealthProvider: @escaping () -> HookHealthReport = { HookHealth().check() }
    ) {
        self.configStore = configStore
        self.usageTracker = usageTracker
        self.hasPhysicalNotch = hasPhysicalNotch
        self.hookHealthProvider = hookHealthProvider

        let loadedTheme = configStore.loadTheme()
        visibility = configStore.loadNotchVisibility()
        compactAgent = configStore.loadCompactAgent()
        showTodayConsumption = configStore.loadShowTodayConsumption()
        hotkey = configStore.load()
        theme = loadedTheme
        notificationSound = configStore.loadNotificationSound()
            ?? loadedTheme.defaultSoundFile
            ?? "none"
        notifyWaitingForInput = configStore.loadNotifyWaitingForInput()
        notchOffsetX = configStore.loadNotchOffsetX()
        hookHealth = hookHealthProvider()
    }

    func setVisibility(_ value: NotchVisibility) {
        guard value != visibility else { return }
        configStore.saveNotchVisibility(value)
        visibility = value
        NotificationCenter.default.post(
            name: .notchVisibilityChanged,
            object: nil,
            userInfo: ["visibility": value]
        )
    }

    func setCompactAgent(_ value: AgentKind) {
        guard value != compactAgent else { return }
        configStore.saveCompactAgent(value)
        compactAgent = value
        NotificationCenter.default.post(
            name: .compactAgentChanged,
            object: nil,
            userInfo: ["agent": value]
        )
    }

    func setShowTodayConsumption(_ enabled: Bool) {
        guard enabled != showTodayConsumption else { return }
        configStore.saveShowTodayConsumption(enabled)
        showTodayConsumption = enabled
        usageTracker.showTodayConsumption = enabled
    }

    func setTheme(_ value: BuddyTheme) {
        guard value != theme else { return }
        configStore.saveTheme(value)
        configStore.saveNotificationSound(nil)
        theme = value
        notificationSound = value.defaultSoundFile ?? "none"
        NotificationCenter.default.post(name: .settingsAppearanceChanged, object: nil)
    }

    func setNotificationSound(_ value: String) {
        guard value != notificationSound else { return }
        configStore.saveNotificationSound(value)
        notificationSound = value
        previewNotificationSound()
    }

    func setNotifyWaitingForInput(_ enabled: Bool) {
        guard enabled != notifyWaitingForInput else { return }
        configStore.saveNotifyWaitingForInput(enabled)
        notifyWaitingForInput = enabled
    }

    func refreshHotkey() {
        hotkey = configStore.load()
    }

    func beginNotchRepositioning() {
        NotificationCenter.default.post(name: .notchMoveModeRequested, object: nil)
    }

    func resetNotchPosition() {
        configStore.saveNotchOffsetX(0)
        notchOffsetX = 0
        NotificationCenter.default.post(name: .notchResetPositionRequested, object: nil)
    }

    func refreshHookHealth() {
        hookHealth = hookHealthProvider()
    }

    func repairHooks() {
        HookRepair.run(appPath: Bundle.main.bundlePath)
        refreshHookHealth()
    }

    func previewNotificationSound() {
        previewSound?.stop()
        guard notificationSound != "none",
              let url = Bundle.main.url(forResource: notificationSound, withExtension: "mp3") else {
            return
        }
        let sound = NSSound(contentsOf: url, byReference: true)
        sound?.play()
        previewSound = sound
    }
}

public extension Notification.Name {
    static let settingsWindowRequested = Notification.Name("settingsWindowRequested")
    static let settingsAppearanceChanged = Notification.Name("settingsAppearanceChanged")
}
