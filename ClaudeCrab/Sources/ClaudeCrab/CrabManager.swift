import AppKit
import ApplicationServices
import ScreenCaptureKit

@MainActor
final class CrabManager {
    private var crabs: [CrabPet] = []
    private var draggedCrab: CrabPet?
    private var behaviorTimer: Timer?
    private var projectiles: [UUID: CursorProjectile] = [:]
    private let weaponOverlay = CursorWeaponOverlay()

    init() {
        behaviorTimer = Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) {
            [weak self] _ in
            MainActor.assumeIsolated {
                self?.updateBehavior()
            }
        }
        RunLoop.main.add(behaviorTimer!, forMode: .common)
    }

    func summon(at point: CGPoint) {
        let crab = CrabPet(spawnPoint: point) { [weak self] deadCrab in
            self?.remove(deadCrab)
        }
        crabs.append(crab)
        crab.startWalking()
    }

    func clear() {
        crabs.forEach { $0.dismiss() }
        crabs.removeAll()
        projectiles.values.forEach { $0.dismiss() }
        projectiles.removeAll()
        weaponOverlay.dismiss()
    }

    func mouseDown(at point: CGPoint) {
        weaponOverlay.attack(at: point)
        guard let crab = crabs.reversed().first(where: { $0.contains(point) }) else { return }
        draggedCrab = crab
        crab.beginDrag(at: point, whileFriendly: crab.isFriendly)
    }

    func mouseDragged(to point: CGPoint) {
        draggedCrab?.drag(to: point)
    }

    func mouseUp(at point: CGPoint) {
        guard let crab = draggedCrab else { return }
        crab.endDrag(at: point)
        draggedCrab = nil

        if crab.wasFriendlyWhenGrabbed,
           !crabs.contains(where: { $0 !== crab && $0.distance(to: crab) < 230 }) {
            crab.becomeAngry()
        }
    }

    func deleteCrab(at point: CGPoint) {
        guard let index = crabs.lastIndex(where: { $0.contains(point) }) else { return }
        let deletedCrab = crabs[index]
        let grievingFriends = crabs.filter {
            $0 !== deletedCrab && $0.isFriendly && deletedCrab.distance(to: $0) < 180
        }

        if draggedCrab === deletedCrab { draggedCrab = nil }
        deletedCrab.dismiss()
        crabs.remove(at: index)

        for friend in grievingFriends {
            if Bool.random() {
                friend.becomeSad()
            } else {
                friend.becomeNuclearAngry()
            }
        }
    }

    func cycleCursorWeapon(at point: CGPoint) {
        weaponOverlay.cycle(at: point)
    }

    func cursorMoved(to point: CGPoint) {
        weaponOverlay.updatePosition(to: point)
    }

    private func updateBehavior() {
        for crab in crabs where !crab.isAngry && !crab.isDragging {
            let hasFriend = crabs.contains {
                $0 !== crab && !$0.isDragging && crab.distance(to: $0) < 145
            }
            crab.setFriendly(hasFriend)
        }

        let now = ProcessInfo.processInfo.systemUptime
        for crab in crabs {
            guard let attack = crab.attackIfReady(at: now, toward: NSEvent.mouseLocation) else {
                continue
            }
            let projectile = CursorProjectile(
                origin: attack.origin,
                target: NSEvent.mouseLocation,
                symbol: attack.symbol
            ) { [weak self] id in
                self?.projectiles.removeValue(forKey: id)
            }
            projectiles[projectile.id] = projectile
            projectile.start()
        }
    }

    private func remove(_ crab: CrabPet) {
        if draggedCrab === crab { draggedCrab = nil }
        crab.dismiss()
        crabs.removeAll { $0 === crab }
    }
}

@MainActor
final class CrabPet {
    private static let size = NSSize(width: 120, height: 100)

    private let window: NSWindow
    private let crabView: PixelCrabView
    private let onDeath: (CrabPet) -> Void
    private var displayLinkTimer: Timer?
    private var velocity: CGVector
    private var platforms: [CGRect] = []
    private var lastPlatformRefresh: TimeInterval = 0
    private var climbPlatform: CGRect?
    private var climbDirection: CGFloat = 1
    private var latestScreenshot: CGImage?
    private var captureInFlight = false
    private var lastUpdate = ProcessInfo.processInfo.systemUptime
    private var nextTurn = ProcessInfo.processInfo.systemUptime + .random(in: 2.0...5.0)
    private var dragOffset = CGPoint.zero
    private var lastDragPoint = CGPoint.zero
    private var lastDragTime: TimeInterval = 0
    private var dragVelocity = CGVector.zero
    private var fallApex: CGFloat
    private var nextAttackTime: TimeInterval = 0

    private(set) var isDragging = false
    private(set) var isAngry = false
    private(set) var isSad = false
    private(set) var isNuclearAngry = false
    private(set) var isFriendly = false
    private(set) var wasFriendlyWhenGrabbed = false
    private(set) var isDead = false

    private let footOffset: CGFloat = 13
    private let gravity: CGFloat = 900

    init(spawnPoint: CGPoint, onDeath: @escaping (CrabPet) -> Void) {
        self.onDeath = onDeath
        let size = Self.size
        let origin = CGPoint(
            x: spawnPoint.x - size.width / 2,
            y: spawnPoint.y - size.height / 2
        )

        window = NSWindow(
            contentRect: NSRect(origin: origin, size: size),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        crabView = PixelCrabView(frame: NSRect(origin: .zero, size: size))

        let direction: CGFloat = Bool.random() ? 1 : -1
        velocity = CGVector(
            dx: direction * .random(in: 45...75),
            dy: 0
        )
        fallApex = origin.y + 13

        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.level = .floating
        window.collectionBehavior = [
            .canJoinAllSpaces,
            .fullScreenAuxiliary,
            .stationary,
            .ignoresCycle
        ]
        window.contentView = crabView
        window.orderFrontRegardless()
    }

    func startWalking() {
        lastUpdate = ProcessInfo.processInfo.systemUptime
        displayLinkTimer = Timer.scheduledTimer(
            withTimeInterval: 1.0 / 60.0,
            repeats: true
        ) { [weak self] _ in
            MainActor.assumeIsolated {
                self?.update()
            }
        }
        RunLoop.main.add(displayLinkTimer!, forMode: .common)
    }

    func dismiss() {
        displayLinkTimer?.invalidate()
        displayLinkTimer = nil
        window.orderOut(nil)
    }

    func contains(_ point: CGPoint) -> Bool {
        !isDead && window.frame.insetBy(dx: 12, dy: 8).contains(point)
    }

    func distance(to other: CrabPet) -> CGFloat {
        hypot(window.frame.midX - other.window.frame.midX, window.frame.midY - other.window.frame.midY)
    }

    func setFriendly(_ friendly: Bool) {
        guard !isAngry, !isSad else { return }
        isFriendly = friendly
        crabView.isFriendly = friendly
    }

    func beginDrag(at point: CGPoint, whileFriendly: Bool) {
        isDragging = true
        wasFriendlyWhenGrabbed = whileFriendly
        dragOffset = CGPoint(x: point.x - window.frame.minX, y: point.y - window.frame.minY)
        lastDragPoint = point
        lastDragTime = ProcessInfo.processInfo.systemUptime
        dragVelocity = .zero
        velocity = .zero
        climbPlatform = nil
        window.orderFrontRegardless()
    }

    func drag(to point: CGPoint) {
        guard isDragging else { return }
        let now = ProcessInfo.processInfo.systemUptime
        let elapsed = max(now - lastDragTime, 1.0 / 120.0)
        dragVelocity = CGVector(
            dx: (point.x - lastDragPoint.x) / elapsed,
            dy: (point.y - lastDragPoint.y) / elapsed
        )
        window.setFrameOrigin(CGPoint(x: point.x - dragOffset.x, y: point.y - dragOffset.y))
        lastDragPoint = point
        lastDragTime = now
    }

    func endDrag(at point: CGPoint) {
        guard isDragging else { return }
        drag(to: point)
        isDragging = false
        velocity = CGVector(
            dx: max(-520, min(520, dragVelocity.dx)),
            dy: max(-520, min(520, dragVelocity.dy))
        )
        fallApex = window.frame.minY + footOffset
    }

    func becomeAngry() {
        guard !isDead else { return }
        isAngry = true
        isSad = false
        isFriendly = false
        crabView.isAngry = true
        crabView.isSad = false
        crabView.isFriendly = false
        nextAttackTime = ProcessInfo.processInfo.systemUptime + 0.3
    }

    func becomeSad() {
        guard !isDead else { return }
        isSad = true
        isAngry = false
        isNuclearAngry = false
        isFriendly = false
        velocity.dx *= 0.22
        crabView.isSad = true
        crabView.isAngry = false
        crabView.isFriendly = false
        crabView.weaponSymbol = nil
        crabView.needsDisplay = true
    }

    func becomeNuclearAngry() {
        guard !isDead else { return }
        becomeAngry()
        isNuclearAngry = true
        crabView.isNuclearAngry = true
        nextAttackTime = ProcessInfo.processInfo.systemUptime + 0.15
    }

    func attackIfReady(at now: TimeInterval, toward cursor: CGPoint) -> (origin: CGPoint, symbol: String)? {
        guard isAngry, !isDragging, now >= nextAttackTime else { return nil }
        nextAttackTime = now + (isNuclearAngry
            ? .random(in: 0.28...0.62)
            : .random(in: 0.65...1.45))
        if isNuclearAngry {
            crabView.weaponSymbol = "☢️"
            crabView.needsDisplay = true
            return (CGPoint(x: window.frame.midX, y: window.frame.midY), "☢️")
        }
        let symbols = ["🚀", "💣", "🍅", "🔧", "🥾", "💥"]
        let symbol = symbols.randomElement()!
        crabView.weaponSymbol = ["🔫", "🧨", "🚀"].randomElement()!
        Timer.scheduledTimer(withTimeInterval: 0.22, repeats: false) { [weak crabView] _ in
            crabView?.weaponSymbol = nil
            crabView?.needsDisplay = true
        }
        crabView.needsDisplay = true
        return (CGPoint(x: window.frame.midX, y: window.frame.midY), symbol)
    }

    private func update() {
        let now = ProcessInfo.processInfo.systemUptime
        let elapsed = min(now - lastUpdate, 0.05)
        lastUpdate = now
        guard !isDead else { return }
        guard !isDragging else {
            crabView.animationTime = now
            crabView.needsDisplay = true
            return
        }

        if now >= nextTurn {
            velocity.dx += .random(in: -12...12)
            velocity.dx = max(42, min(abs(velocity.dx), 78)) * (velocity.dx < 0 ? -1 : 1)
            nextTurn = now + .random(in: 2.0...5.0)
        }

        var frame = window.frame
        let movementBounds = screenBounds(for: frame)
        refreshPlatformsIfNeeded(at: now)

        if let platform = climbPlatform {
            frame.origin.x = climbDirection > 0
                ? platform.minX - 96
                : platform.maxX - 24
            frame.origin.y += 72 * elapsed

            if frame.origin.y + footOffset >= platform.maxY {
                frame.origin.y = platform.maxY - footOffset
                frame.origin.x = climbDirection > 0
                    ? platform.minX - 34
                    : platform.maxX - 87
                climbPlatform = nil
                velocity.dy = 0
            }
        } else {
            let oldFrame = frame
            let proposedX = frame.origin.x + velocity.dx * elapsed

            if let wall = wallHit(from: oldFrame, proposedX: proposedX) {
                climbPlatform = wall
                climbDirection = velocity.dx < 0 ? -1 : 1
                velocity.dy = 0
            } else {
                frame.origin.x = proposedX
                velocity.dy -= gravity * elapsed
                frame.origin.y += velocity.dy * elapsed
                fallApex = max(fallApex, frame.origin.y + footOffset)
                landIfNeeded(frame: &frame, previousFrame: oldFrame)
            }
        }

        if frame.minX <= movementBounds.minX {
            frame.origin.x = movementBounds.minX
            velocity.dx = abs(velocity.dx)
        } else if frame.maxX >= movementBounds.maxX {
            frame.origin.x = movementBounds.maxX - frame.width
            velocity.dx = -abs(velocity.dx)
        }

        if frame.origin.y + footOffset <= movementBounds.minY {
            registerLanding(at: movementBounds.minY)
            frame.origin.y = movementBounds.minY - footOffset
            velocity.dy = 0
        }

        window.setFrameOrigin(frame.origin)
        crabView.facingRight = velocity.dx >= 0
        crabView.animationTime = now
        crabView.needsDisplay = true
    }

    private func landIfNeeded(frame: inout CGRect, previousFrame: CGRect) {
        guard velocity.dy <= 0 else { return }

        let previousFeet = previousFrame.origin.y + footOffset
        let nextFeet = frame.origin.y + footOffset
        let footSpan = (frame.origin.x + 32)...(frame.origin.x + 91)

        let landingTop = platforms
            .filter {
                (previousFeet >= $0.maxY - 1
                    || (previousFrame.maxY >= $0.maxY && previousFeet < $0.maxY))
                    && nextFeet <= $0.maxY
                    && footSpan.upperBound >= $0.minX
                    && footSpan.lowerBound <= $0.maxX
            }
            .map(\.maxY)
            .max()

        if let landingTop {
            registerLanding(at: landingTop)
            frame.origin.y = landingTop - footOffset
            velocity.dy = 0
        }
    }

    private func registerLanding(at height: CGFloat) {
        let fallDistance = fallApex - height
        if fallDistance > 520 {
            die()
        } else if fallDistance > 240 {
            becomeAngry()
        }
        fallApex = height
    }

    private func die() {
        guard !isDead else { return }
        isDead = true
        isDragging = false
        isAngry = false
        isFriendly = false
        velocity = .zero
        crabView.isDead = true
        crabView.isAngry = false
        crabView.isFriendly = false
        crabView.isSad = false
        crabView.weaponSymbol = nil
        crabView.needsDisplay = true
        Timer.scheduledTimer(withTimeInterval: 0.9, repeats: false) {
            [weak self] _ in
            guard let self else { return }
            self.onDeath(self)
        }
    }

    private func wallHit(from frame: CGRect, proposedX: CGFloat) -> CGRect? {
        let bodyBottom = frame.origin.y + footOffset + 2
        let bodyTop = frame.origin.y + 78

        return platforms
            .filter { platform in
                let verticalOverlap = bodyTop > platform.minY && bodyBottom < platform.maxY - 2
                guard verticalOverlap else { return false }

                if velocity.dx > 0 {
                    let oldEdge = frame.origin.x + 96
                    let newEdge = proposedX + 96
                    return oldEdge <= platform.minX + 2 && newEdge >= platform.minX
                } else {
                    let oldEdge = frame.origin.x + 24
                    let newEdge = proposedX + 24
                    return oldEdge >= platform.maxX - 2 && newEdge <= platform.maxX
                }
            }
            .min {
                velocity.dx > 0 ? $0.minX < $1.minX : $0.maxX > $1.maxX
            }
    }

    private func refreshPlatformsIfNeeded(at now: TimeInterval) {
        guard now - lastPlatformRefresh >= 0.5 else { return }
        lastPlatformRefresh = now

        guard let windowInfo = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .excludeDesktopElements],
            kCGNullWindowID
        ) as? [[String: Any]] else {
            platforms = []
            return
        }

        let ownPID = ProcessInfo.processInfo.processIdentifier
        let mainScreenTop = NSScreen.main?.frame.maxY ?? 0
        platforms = windowInfo.compactMap { info in
            guard (info[kCGWindowOwnerPID as String] as? pid_t) != ownPID,
                  (info[kCGWindowLayer as String] as? Int) == 0,
                  (info[kCGWindowAlpha as String] as? CGFloat ?? 1) > 0.05,
                  let bounds = info[kCGWindowBounds as String] as? CFDictionary,
                  let cgRect = CGRect(dictionaryRepresentation: bounds),
                  cgRect.width > 100,
                  cgRect.height > 40 else {
                return nil
            }

            return CGRect(
                x: cgRect.minX,
                y: mainScreenTop - cgRect.maxY,
                width: cgRect.width,
                height: cgRect.height
            )
        }

        appendAccessibilityPlatforms(to: &platforms, mainScreenTop: mainScreenTop)
        platforms = visiblyRenderedPlatforms(platforms, mainScreenTop: mainScreenTop)
    }

    private func visiblyRenderedPlatforms(
        _ candidates: [CGRect],
        mainScreenTop: CGFloat
    ) -> [CGRect] {
        guard CGPreflightScreenCaptureAccess() else { return [] }

        let captureBounds = CGDisplayBounds(CGMainDisplayID())
        requestScreenshot(for: captureBounds)
        guard let image = latestScreenshot,
              image.bitsPerPixel == 32,
        let data = image.dataProvider?.data,
        let bytes = CFDataGetBytePtr(data) else {
            return []
        }

        let width = image.width
        let height = image.height
        let bytesPerRow = image.bytesPerRow

        return candidates.filter { platform in
            let cgTop = mainScreenTop - platform.maxY
            guard platform.minX >= captureBounds.minX,
                  platform.maxX <= captureBounds.maxX,
                  cgTop >= captureBounds.minY + 4,
                  cgTop <= captureBounds.maxY - 4 else {
                return false
            }

            let sampleCount = 28
            let inset = min(10, platform.width * 0.08)
            var edgeSamples = 0

            for index in 0..<sampleCount {
                let fraction = (CGFloat(index) + 0.5) / CGFloat(sampleCount)
                let screenX = platform.minX + inset
                    + fraction * max(1, platform.width - inset * 2)
                let pixelX = Int(round(
                    (screenX - captureBounds.minX)
                        / captureBounds.width * CGFloat(width - 1)
                ))
                let centerY = Int(round(
                    (cgTop - captureBounds.minY)
                        / captureBounds.height * CGFloat(height - 1)
                ))
                let aboveY = max(0, centerY - 3)
                let belowY = min(height - 1, centerY + 3)
                let above = bytes + aboveY * bytesPerRow + pixelX * 4
                let below = bytes + belowY * bytesPerRow + pixelX * 4
                let difference =
                    abs(Int(above[0]) - Int(below[0]))
                    + abs(Int(above[1]) - Int(below[1]))
                    + abs(Int(above[2]) - Int(below[2]))
                if difference >= 36 { edgeSamples += 1 }
            }

            return edgeSamples >= 6
        }
    }

    private func requestScreenshot(for bounds: CGRect) {
        guard !captureInFlight else { return }
        guard #available(macOS 15.2, *) else { return }

        captureInFlight = true
        SCScreenshotManager.captureImage(in: bounds) { [weak self] image, _ in
            Task { @MainActor in
                self?.captureInFlight = false
                if let image {
                    self?.latestScreenshot = image
                }
            }
        }
    }

    private func appendAccessibilityPlatforms(
        to result: inout [CGRect],
        mainScreenTop: CGFloat
    ) {
        guard AXIsProcessTrusted(),
              let application = NSWorkspace.shared.frontmostApplication,
              application.processIdentifier != ProcessInfo.processInfo.processIdentifier else {
            return
        }

        let root = AXUIElementCreateApplication(application.processIdentifier)
        var visited = 0
        collectAccessibilityPlatforms(
            from: root,
            depth: 0,
            visited: &visited,
            into: &result,
            mainScreenTop: mainScreenTop
        )
    }

    private func collectAccessibilityPlatforms(
        from element: AXUIElement,
        depth: Int,
        visited: inout Int,
        into result: inout [CGRect],
        mainScreenTop: CGFloat
    ) {
        guard depth <= 9, visited <= 700 else { return }
        visited += 1

        var roleValue: CFTypeRef?
        AXUIElementCopyAttributeValue(element, kAXRoleAttribute as CFString, &roleValue)
        let role = roleValue as? String
        let platformRoles = [
            kAXTextAreaRole as String,
            kAXTextFieldRole as String,
            kAXScrollAreaRole as String
        ]

        if let role, platformRoles.contains(role) {
            var positionValue: CFTypeRef?
            var sizeValue: CFTypeRef?
            AXUIElementCopyAttributeValue(element, kAXPositionAttribute as CFString, &positionValue)
            AXUIElementCopyAttributeValue(element, kAXSizeAttribute as CFString, &sizeValue)

            if let positionAXValue = positionValue as! AXValue?,
               let sizeAXValue = sizeValue as! AXValue? {
                var position = CGPoint.zero
                var size = CGSize.zero
                if AXValueGetValue(positionAXValue, .cgPoint, &position),
                   AXValueGetValue(sizeAXValue, .cgSize, &size),
                   size.width > 120,
                   size.height > 35,
                   size.height < 650 {
                    result.append(CGRect(
                        x: position.x,
                        y: mainScreenTop - position.y - size.height,
                        width: size.width,
                        height: size.height
                    ))
                }
            }
        }

        var childrenValue: CFTypeRef?
        guard AXUIElementCopyAttributeValue(
            element,
            kAXChildrenAttribute as CFString,
            &childrenValue
        ) == .success,
        let children = childrenValue as? [AXUIElement] else {
            return
        }

        for child in children {
            collectAccessibilityPlatforms(
                from: child,
                depth: depth + 1,
                visited: &visited,
                into: &result,
                mainScreenTop: mainScreenTop
            )
            if visited > 700 { break }
        }
    }

    private func screenBounds(for frame: NSRect) -> NSRect {
        let center = CGPoint(x: frame.midX, y: frame.midY)
        return NSScreen.screens.first(where: { $0.frame.contains(center) })?.visibleFrame
            ?? NSScreen.main?.visibleFrame
            ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
    }
}
