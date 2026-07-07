import AppKit

final class PixelCrabView: NSView {
    var facingRight = true
    var animationTime: TimeInterval = 0
    var isAngry = false
    var isFriendly = false
    var isSad = false
    var isNuclearAngry = false
    var isDead = false
    var weaponSymbol: String?

    override var isOpaque: Bool { false }

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        guard let context = NSGraphicsContext.current?.cgContext else { return }
        context.saveGState()
        context.setShouldAntialias(false)
        context.interpolationQuality = .none

        let bob = round(sin(animationTime * 9) * 2)
        let step = sin(animationTime * 13) > 0 ? 2.0 : 0.0

        context.translateBy(x: 0, y: bob)
        if !facingRight {
            context.translateBy(x: bounds.width, y: 0)
            context.scaleBy(x: -1, y: 1)
        }

        let orange = NSColor(
            calibratedRed: 0.86,
            green: 0.38,
            blue: 0.23,
            alpha: 1
        )
        context.setFillColor(orange.cgColor)

        // Legs sit behind the shell and alternate by two pixels as it walks.
        context.fill(CGRect(x: 32, y: 13 + step, width: 9, height: 29))
        context.fill(CGRect(x: 48, y: 13 + (2 - step), width: 9, height: 29))
        context.fill(CGRect(x: 65, y: 13 + step, width: 9, height: 29))
        context.fill(CGRect(x: 82, y: 13 + (2 - step), width: 9, height: 29))

        // Blocky shell and claws, based on the supplied pixel-crab reference.
        context.fill(CGRect(x: 24, y: 34, width: 72, height: 44))
        context.fill(CGRect(x: 8, y: 47, width: 20, height: 15))
        context.fill(CGRect(x: 92, y: 47, width: 20, height: 15))

        context.setFillColor(NSColor(
            calibratedWhite: 0.08,
            alpha: 1
        ).cgColor)
        context.fill(CGRect(x: 40, y: 64, width: 7, height: 7))
        context.fill(CGRect(x: 76, y: 64, width: 7, height: 7))

        if isAngry {
            context.fill(CGRect(x: 37, y: 73, width: 12, height: 3))
            context.fill(CGRect(x: 74, y: 73, width: 12, height: 3))
        }
        if isSad {
            context.setFillColor(NSColor.systemBlue.cgColor)
            context.fill(CGRect(x: 41, y: 55, width: 3, height: 8))
            context.fill(CGRect(x: 79, y: 55, width: 3, height: 8))
        }

        context.restoreGState()

        if isFriendly {
            NSColor.systemPink.setFill()
            NSRect(x: 54, y: 83, width: 6, height: 6).fill()
            NSRect(x: 62, y: 83, width: 6, height: 6).fill()
            NSRect(x: 57, y: 78, width: 8, height: 8).fill()
        }
        if let weaponSymbol {
            (weaponSymbol as NSString).draw(
                at: CGPoint(x: facingRight ? 91 : 5, y: 43),
                withAttributes: [.font: NSFont.systemFont(ofSize: 20)]
            )
        }
        if isNuclearAngry {
            ("☢️" as NSString).draw(
                at: CGPoint(x: 49, y: 38),
                withAttributes: [.font: NSFont.systemFont(ofSize: 19)]
            )
        }
        if isDead {
            ("💀" as NSString).draw(
                at: CGPoint(x: 47, y: 48),
                withAttributes: [.font: NSFont.systemFont(ofSize: 25)]
            )
        }
    }
}
