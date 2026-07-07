import AppKit

@MainActor
final class CursorProjectile {
    let id = UUID()

    private let window: NSWindow
    private var velocity: CGVector
    private var timer: Timer?
    private var lastUpdate = ProcessInfo.processInfo.systemUptime
    private var lifetime: TimeInterval = 0
    private let completion: (UUID) -> Void

    init(
        origin: CGPoint,
        target: CGPoint,
        symbol: String,
        completion: @escaping (UUID) -> Void
    ) {
        self.completion = completion
        let size = NSSize(width: 38, height: 38)
        window = NSWindow(
            contentRect: NSRect(
                x: origin.x - size.width / 2,
                y: origin.y - size.height / 2,
                width: size.width,
                height: size.height
            ),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        let label = NSTextField(labelWithString: symbol)
        label.font = .systemFont(ofSize: symbol == "☢️" ? 31 : 24)
        label.alignment = .center
        label.frame = NSRect(origin: .zero, size: size)
        window.contentView = label
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]

        let delta = CGVector(dx: target.x - origin.x, dy: target.y - origin.y)
        let distance = max(1, hypot(delta.dx, delta.dy))
        let speed: CGFloat = symbol == "🚀" ? 360 : (symbol == "☢️" ? 230 : 270)
        velocity = CGVector(dx: delta.dx / distance * speed, dy: delta.dy / distance * speed)
        if symbol == "💣" || symbol == "☢️" { velocity.dy += 190 }
    }

    func start() {
        window.orderFrontRegardless()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) {
            [weak self] _ in
            MainActor.assumeIsolated { self?.update() }
        }
        RunLoop.main.add(timer!, forMode: .common)
    }

    func dismiss() {
        timer?.invalidate()
        timer = nil
        window.orderOut(nil)
    }

    private func update() {
        let now = ProcessInfo.processInfo.systemUptime
        let elapsed = min(now - lastUpdate, 0.05)
        lastUpdate = now
        lifetime += elapsed
        if lifetime > 4 {
            dismiss()
            completion(id)
            return
        }

        var origin = window.frame.origin
        origin.x += velocity.dx * elapsed
        origin.y += velocity.dy * elapsed
        velocity.dy -= 90 * elapsed
        window.setFrameOrigin(origin)
    }
}
