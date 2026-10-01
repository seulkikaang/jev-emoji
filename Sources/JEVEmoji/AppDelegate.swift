import AppKit
import Carbon
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let picker = EmojiPickerModel()
    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var hotKey: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var activationObserver: NSObjectProtocol?
    private var lastExternalApplication: NSRunningApplication?


    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        rememberExternalApplication(NSWorkspace.shared.frontmostApplication)
        activationObserver = NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main
        ) { [weak self] notification in
            guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication else { return }
            Task { @MainActor in self?.rememberExternalApplication(app) }
        }
        installMenuBarItem()
        installGlobalShortcut()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if popover?.isShown != true { togglePicker() }
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let activationObserver { NSWorkspace.shared.notificationCenter.removeObserver(activationObserver) }
        if let hotKey { UnregisterEventHotKey(hotKey) }
        if let eventHandler { RemoveEventHandler(eventHandler) }
    }

    private func installMenuBarItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.image = NSImage(systemSymbolName: "face.smiling", accessibilityDescription: "JEV Emoji")
        item.button?.target = self
        item.button?.action = #selector(togglePicker)

        let panel = NSPopover()
        panel.behavior = .transient
        panel.animates = false
        panel.contentSize = NSSize(width: 376, height: 490)
        panel.contentViewController = NSHostingController(rootView: EmojiPickerView(model: picker))

        statusItem = item
        popover = panel
    }

    @objc private func togglePicker() {
        guard let popover, let button = statusItem?.button else { return }
        if popover.isShown {
            popover.performClose(nil)
        } else {
            rememberExternalApplication(NSWorkspace.shared.frontmostApplication)
            picker.captureContext(from: lastExternalApplication)
            picker.recommendContext()
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    private func rememberExternalApplication(_ app: NSRunningApplication?) {
        guard let app, app.processIdentifier != ProcessInfo.processInfo.processIdentifier else { return }
        lastExternalApplication = app
        // Chromium/Electron publish complete caret information only after an AX client opts in.
        AccessibilityContextReader.prepare(processID: app.processIdentifier)
    }

    private func installGlobalShortcut() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let callback: EventHandlerProcPtr = { _, _, userData in
            guard let userData else { return noErr }
            let delegate = Unmanaged<AppDelegate>.fromOpaque(userData).takeUnretainedValue()
            DispatchQueue.main.async { delegate.togglePicker() }
            return noErr
        }
        InstallEventHandler(GetApplicationEventTarget(), callback, 1, &spec,
                            Unmanaged.passUnretained(self).toOpaque(), &eventHandler)

        let identifier = EventHotKeyID(signature: OSType(0x4A455645), id: 1)
        // Option + Command + E. This avoids macOS's Control + Command + Space emoji picker.
        RegisterEventHotKey(UInt32(kVK_ANSI_E), UInt32(optionKey | cmdKey), identifier,
                            GetApplicationEventTarget(), 0, &hotKey)
    }
}
