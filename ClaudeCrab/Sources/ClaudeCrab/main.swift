import AppKit
import ApplicationServices

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private let crabManager = CrabManager()
    private var tapMonitor: TripleTapMonitor?
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        installStatusItem()

        let accessibilityOptions = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ] as CFDictionary
        AXIsProcessTrustedWithOptions(accessibilityOptions)
        if !CGPreflightScreenCaptureAccess() {
            CGRequestScreenCaptureAccess()
        }

        tapMonitor = TripleTapMonitor { [weak self] point in
            self?.crabManager.summon(at: point)
        } onMouseDown: { [weak self] point in
            self?.crabManager.mouseDown(at: point)
        } onMouseDragged: { [weak self] point in
            self?.crabManager.mouseDragged(to: point)
        } onMouseUp: { [weak self] point in
            self?.crabManager.mouseUp(at: point)
        } onRightClick: { [weak self] point in
            self?.crabManager.deleteCrab(at: point)
        }
        tapMonitor?.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        tapMonitor?.stop()
    }

    private func installStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        item.button?.title = "🦀"
        item.button?.toolTip = "Claude Crab"

        let menu = NSMenu()
        let hint = NSMenuItem(title: "Triple-click anywhere to summon", action: nil, keyEquivalent: "")
        hint.isEnabled = false
        menu.addItem(hint)
        menu.addItem(.separator())

        let summon = NSMenuItem(
            title: "Summon Crab",
            action: #selector(summonFromMenu),
            keyEquivalent: "n"
        )
        summon.target = self
        menu.addItem(summon)

        let clear = NSMenuItem(
            title: "Clear All Crabs",
            action: #selector(clearCrabs),
            keyEquivalent: "k"
        )
        clear.target = self
        menu.addItem(clear)
        menu.addItem(.separator())

        let quit = NSMenuItem(
            title: "Quit Claude Crab",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quit.target = self
        menu.addItem(quit)

        item.menu = menu
        statusItem = item
    }

    @objc private func summonFromMenu() {
        crabManager.summon(at: NSEvent.mouseLocation)
    }

    @objc private func clearCrabs() {
        crabManager.clear()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}

@main
struct ClaudeCrabApp {
    @MainActor
    static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}
