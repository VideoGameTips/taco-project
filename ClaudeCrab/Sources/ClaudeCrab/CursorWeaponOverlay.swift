import AppKit

@MainActor
final class CursorWeaponOverlay {
    private let window: NSWindow
    private let weaponView: CursorWeaponView
    private var selectedIndex = -1
    private var followTimer: Timer?
    private var attackTimer: Timer?
    private var hideCursor = false

    init() {
        let size = NSSize(width: 58, height: 58)
        window = NSWindow(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        weaponView = CursorWeaponView(frame: NSRect(origin: .zero, size: size))
        window.contentView = weaponView
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = false
        window.ignoresMouseEvents = true
        window.level = .screenSaver
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
    }

    func cycle(at point: CGPoint) {
        guard !WeaponCatalog.all.isEmpty else { return }
        selectedIndex = (selectedIndex + 1) % WeaponCatalog.all.count
        weaponView.weapon = WeaponCatalog.all[selectedIndex]
        weaponView.needsDisplay = true
        show(at: point)
    }

    func attack(at point: CGPoint) {
        guard window.isVisible, weaponView.weapon != nil else { return }
        updatePosition(to: point)
        weaponView.attackPulse = 1
        weaponView.needsDisplay = true
        attackTimer?.invalidate()
        attackTimer = Timer.scheduledTimer(withTimeInterval: 0.08, repeats: true) {
            [weak self] timer in
            MainActor.assumeIsolated {
                guard let self else { return }
                self.weaponView.attackPulse -= 0.28
                if self.weaponView.attackPulse <= 0 {
                    self.weaponView.attackPulse = 0
                    timer.invalidate()
                    self.attackTimer = nil
                }
                self.weaponView.needsDisplay = true
            }
        }
        RunLoop.main.add(attackTimer!, forMode: .common)
    }

    func updatePosition(to point: CGPoint) {
        guard window.isVisible else { return }
        window.setFrameOrigin(CGPoint(x: point.x - 8, y: point.y - 44))
    }

    func dismiss() {
        followTimer?.invalidate()
        followTimer = nil
        attackTimer?.invalidate()
        attackTimer = nil
        window.orderOut(nil)
        if hideCursor {
            NSCursor.unhide()
            hideCursor = false
        }
    }

    private func show(at point: CGPoint) {
        updatePosition(to: point)
        window.orderFrontRegardless()
        if !hideCursor {
            NSCursor.hide()
            hideCursor = true
        }
        if followTimer == nil {
            followTimer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) {
                [weak self] _ in
                MainActor.assumeIsolated {
                    self?.updatePosition(to: NSEvent.mouseLocation)
                }
            }
            RunLoop.main.add(followTimer!, forMode: .common)
        }
    }
}

final class CursorWeaponView: NSView {
    var weapon: CursorWeapon?
    var attackPulse: CGFloat = 0

    override var isOpaque: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        guard let weapon else { return }

        NSColor(calibratedWhite: 0, alpha: 0.45).setFill()
        NSBezierPath(ovalIn: NSRect(x: 10, y: 4, width: 34, height: 10)).fill()

        if attackPulse > 0 {
            NSColor.systemYellow.withAlphaComponent(0.65 * attackPulse).setFill()
            NSBezierPath(ovalIn: NSRect(x: 34, y: 28, width: 18 + attackPulse * 16, height: 12)).fill()
        }

        drawWeapon(weapon, in: bounds.insetBy(dx: 4, dy: 8), attacking: attackPulse)
    }

    private func drawWeapon(_ weapon: CursorWeapon, in rect: NSRect, attacking: CGFloat) {
        switch weapon.kind {
        case .blade:
            drawBlade(in: rect, curved: weapon.name == "katana", attacking: attacking)
        case .bow:
            drawBow(in: rect, cross: false)
        case .axe:
            drawAxe(in: rect)
        case .polearm:
            drawPolearm(in: rect, halberd: weapon.name == "halberd")
        case .dagger:
            drawDagger(in: rect)
        case .blunt:
            drawBlunt(in: rect, spiked: weapon.name == "mace")
        case .staff:
            drawStaff(in: rect)
        case .crossbow:
            drawBow(in: rect, cross: true)
        case .chain:
            drawChain(in: rect)
        case .scythe:
            drawScythe(in: rect)
        case .whip:
            drawWhip(in: rect)
        case .handgun:
            drawGun(in: rect, long: false, heavy: weapon.name == "desert eagle")
        case .longGun:
            drawGun(in: rect, long: true, heavy: false)
        case .shotgun:
            drawGun(in: rect, long: true, heavy: true)
        case .heavy:
            drawHeavy(in: rect, cannon: weapon.name == "cannon")
        case .grenade:
            drawGrenade(in: rect)
        case .rocket:
            drawRocket(in: rect)
        case .energy:
            drawEnergy(in: rect, plasma: weapon.name.contains("plasma"))
        case .flame:
            drawFlame(in: rect)
        case .boomerang:
            drawBoomerang(in: rect)
        }
    }

    private func line(_ points: [CGPoint], color: NSColor, width: CGFloat) {
        guard let first = points.first else { return }
        let path = NSBezierPath()
        path.move(to: first)
        for point in points.dropFirst() { path.line(to: point) }
        color.setStroke()
        path.lineWidth = width
        path.lineCapStyle = .round
        path.lineJoinStyle = .round
        path.stroke()
    }

    private func drawBlade(in r: NSRect, curved: Bool, attacking: CGFloat) {
        line([CGPoint(x: r.minX + 10, y: r.minY + 8), CGPoint(x: r.maxX - 8 + attacking * 6, y: r.maxY - 8)], color: .silver, width: curved ? 7 : 5)
        line([CGPoint(x: r.minX + 12, y: r.minY + 9), CGPoint(x: r.minX + 5, y: r.minY + 2)], color: .brown, width: 5)
        line([CGPoint(x: r.minX + 5, y: r.minY + 15), CGPoint(x: r.minX + 18, y: r.minY + 3)], color: .systemYellow, width: 4)
    }

    private func drawBow(in r: NSRect, cross: Bool) {
        line([CGPoint(x: r.minX + 12, y: r.minY + 6), CGPoint(x: r.minX + 5, y: r.midY), CGPoint(x: r.minX + 12, y: r.maxY - 6)], color: .brown, width: 5)
        line([CGPoint(x: r.minX + 12, y: r.minY + 6), CGPoint(x: r.minX + 12, y: r.maxY - 6)], color: .white, width: 1.5)
        line([CGPoint(x: r.minX + 13, y: r.midY), CGPoint(x: r.maxX - 5, y: r.midY)], color: .silver, width: 2)
        if cross { line([CGPoint(x: r.midX, y: r.minY + 9), CGPoint(x: r.midX, y: r.maxY - 9)], color: .brown, width: 5) }
    }

    private func drawAxe(in r: NSRect) {
        line([CGPoint(x: r.minX + 10, y: r.minY + 4), CGPoint(x: r.maxX - 8, y: r.maxY - 7)], color: .brown, width: 6)
        NSColor.silver.setFill()
        NSBezierPath(ovalIn: NSRect(x: r.maxX - 24, y: r.maxY - 22, width: 22, height: 20)).fill()
    }

    private func drawPolearm(in r: NSRect, halberd: Bool) {
        line([CGPoint(x: r.minX + 8, y: r.minY + 6), CGPoint(x: r.maxX - 8, y: r.maxY - 6)], color: .brown, width: 4)
        NSColor.silver.setFill()
        NSBezierPath(ovalIn: NSRect(x: r.maxX - 18, y: r.maxY - 17, width: 15, height: 15)).fill()
        if halberd { NSBezierPath(ovalIn: NSRect(x: r.maxX - 27, y: r.maxY - 22, width: 17, height: 17)).fill() }
    }

    private func drawDagger(in r: NSRect) { drawBlade(in: r.insetBy(dx: 8, dy: 8), curved: false, attacking: 0) }
    private func drawBlunt(in r: NSRect, spiked: Bool) {
        line([CGPoint(x: r.minX + 9, y: r.minY + 7), CGPoint(x: r.maxX - 11, y: r.maxY - 10)], color: .brown, width: 7)
        (spiked ? NSColor.darkGray : NSColor.brown).setFill()
        NSBezierPath(ovalIn: NSRect(x: r.maxX - 21, y: r.maxY - 21, width: 18, height: 18)).fill()
    }
    private func drawStaff(in r: NSRect) {
        line([CGPoint(x: r.minX + 8, y: r.minY + 6), CGPoint(x: r.maxX - 8, y: r.maxY - 6)], color: .brown, width: 5)
        NSColor.systemPurple.setFill()
        NSBezierPath(ovalIn: NSRect(x: r.maxX - 16, y: r.maxY - 16, width: 12, height: 12)).fill()
    }
    private func drawChain(in r: NSRect) {
        line([CGPoint(x: r.minX + 10, y: r.maxY - 10), CGPoint(x: r.midX, y: r.midY), CGPoint(x: r.maxX - 15, y: r.maxY - 15)], color: .gray, width: 4)
        NSColor.darkGray.setFill()
        NSBezierPath(ovalIn: NSRect(x: r.maxX - 20, y: r.maxY - 22, width: 18, height: 18)).fill()
    }
    private func drawScythe(in r: NSRect) {
        line([CGPoint(x: r.minX + 10, y: r.minY + 5), CGPoint(x: r.maxX - 12, y: r.maxY - 7)], color: .brown, width: 5)
        line([CGPoint(x: r.maxX - 17, y: r.maxY - 10), CGPoint(x: r.maxX - 3, y: r.maxY - 27)], color: .silver, width: 5)
    }
    private func drawWhip(in r: NSRect) {
        line([CGPoint(x: r.minX + 8, y: r.minY + 10), CGPoint(x: r.midX - 5, y: r.midY + 8), CGPoint(x: r.maxX - 8, y: r.midY - 10)], color: .brown, width: 4)
    }
    private func drawGun(in r: NSRect, long: Bool, heavy: Bool) {
        let body = NSRect(x: r.minX + 8, y: r.midY, width: long ? 35 : 24, height: heavy ? 10 : 8)
        NSColor.darkGray.setFill()
        body.fill()
        NSRect(x: body.maxX - 2, y: body.midY - 2, width: long ? 16 : 8, height: 4).fill()
        NSColor.black.setFill()
        NSRect(x: body.minX + 5, y: body.minY - 12, width: 7, height: 13).fill()
    }
    private func drawHeavy(in r: NSRect, cannon: Bool) {
        drawGun(in: r, long: true, heavy: true)
        if cannon { NSBezierPath(ovalIn: NSRect(x: r.minX + 4, y: r.minY + 8, width: 12, height: 12)).fill() }
    }
    private func drawGrenade(in r: NSRect) {
        NSColor.darkGray.setFill()
        NSBezierPath(ovalIn: NSRect(x: r.midX - 13, y: r.midY - 12, width: 26, height: 26)).fill()
        NSColor.gray.setFill()
        NSRect(x: r.midX - 5, y: r.midY + 12, width: 10, height: 6).fill()
    }
    private func drawRocket(in r: NSRect) {
        line([CGPoint(x: r.minX + 8, y: r.minY + 8), CGPoint(x: r.maxX - 8, y: r.maxY - 8)], color: .systemRed, width: 9)
        NSColor.systemOrange.setFill()
        NSBezierPath(ovalIn: NSRect(x: r.minX + 4, y: r.minY + 3, width: 15, height: 12)).fill()
    }
    private func drawEnergy(in r: NSRect, plasma: Bool) {
        drawGun(in: r, long: true, heavy: false)
        (plasma ? NSColor.systemPurple : NSColor.systemCyan).setFill()
        NSBezierPath(ovalIn: NSRect(x: r.maxX - 12, y: r.midY - 7, width: 13, height: 13)).fill()
    }
    private func drawFlame(in r: NSRect) {
        drawGun(in: r, long: true, heavy: true)
        NSColor.systemOrange.setFill()
        NSBezierPath(ovalIn: NSRect(x: r.maxX - 13, y: r.midY - 5, width: 20, height: 14)).fill()
    }
    private func drawBoomerang(in r: NSRect) {
        line([CGPoint(x: r.minX + 9, y: r.minY + 12), CGPoint(x: r.midX, y: r.maxY - 8), CGPoint(x: r.maxX - 8, y: r.minY + 14)], color: .systemTeal, width: 8)
    }
}
