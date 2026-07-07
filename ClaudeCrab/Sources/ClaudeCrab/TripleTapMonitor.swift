import AppKit

struct ClickSequence {
    private(set) var clickCount = 0
    private var lastClickTime: TimeInterval?
    private var lastClickPoint: CGPoint?

    let maximumDelay: TimeInterval
    let maximumTravel: CGFloat

    init(maximumDelay: TimeInterval = 0.48, maximumTravel: CGFloat = 28) {
        self.maximumDelay = maximumDelay
        self.maximumTravel = maximumTravel
    }

    mutating func register(at point: CGPoint, time: TimeInterval) -> Bool {
        if let lastClickTime,
           let lastClickPoint,
           time - lastClickTime <= maximumDelay,
           point.distance(to: lastClickPoint) <= maximumTravel {
            clickCount += 1
        } else {
            clickCount = 1
        }

        self.lastClickTime = time
        self.lastClickPoint = point

        guard clickCount == 3 else { return false }
        clickCount = 0
        lastClickTime = nil
        lastClickPoint = nil
        return true
    }
}

@MainActor
final class TripleTapMonitor {
    private let onTripleTap: (CGPoint) -> Void
    private let onMouseDown: (CGPoint) -> Void
    private let onMouseDragged: (CGPoint) -> Void
    private let onMouseUp: (CGPoint) -> Void
    private let onRightClick: (CGPoint) -> Void
    private var clickSequence = ClickSequence()
    private var globalMonitor: Any?
    private var localMonitor: Any?

    init(
        onTripleTap: @escaping (CGPoint) -> Void,
        onMouseDown: @escaping (CGPoint) -> Void,
        onMouseDragged: @escaping (CGPoint) -> Void,
        onMouseUp: @escaping (CGPoint) -> Void,
        onRightClick: @escaping (CGPoint) -> Void
    ) {
        self.onTripleTap = onTripleTap
        self.onMouseDown = onMouseDown
        self.onMouseDragged = onMouseDragged
        self.onMouseUp = onMouseUp
        self.onRightClick = onRightClick
    }

    func start() {
        guard globalMonitor == nil, localMonitor == nil else { return }

        let mask: NSEvent.EventTypeMask = [
            .leftMouseDown, .leftMouseDragged, .leftMouseUp, .rightMouseDown
        ]
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: mask) {
            [weak self] event in
            MainActor.assumeIsolated {
                self?.handle(event)
            }
        }

        localMonitor = NSEvent.addLocalMonitorForEvents(matching: mask) {
            [weak self] event in
            MainActor.assumeIsolated {
                self?.handle(event)
            }
            return event
        }
    }

    func stop() {
        if let globalMonitor {
            NSEvent.removeMonitor(globalMonitor)
        }
        if let localMonitor {
            NSEvent.removeMonitor(localMonitor)
        }
        globalMonitor = nil
        localMonitor = nil
    }

    private func handle(_ event: NSEvent) {
        let point = NSEvent.mouseLocation
        switch event.type {
        case .leftMouseDown:
            onMouseDown(point)
            if clickSequence.register(at: point, time: event.timestamp) {
                onTripleTap(point)
            }
        case .leftMouseDragged:
            onMouseDragged(point)
        case .leftMouseUp:
            onMouseUp(point)
        case .rightMouseDown:
            onRightClick(point)
        default:
            break
        }
    }
}

private extension CGPoint {
    func distance(to other: CGPoint) -> CGFloat {
        hypot(x - other.x, y - other.y)
    }
}
