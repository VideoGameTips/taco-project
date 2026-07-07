import CoreGraphics
import Testing
@testable import ClaudeCrab

struct ClickSequenceTests {
    @Test
    func recognizesThreeNearbyClicks() {
        var sequence = ClickSequence()

        #expect(!sequence.register(at: CGPoint(x: 50, y: 50), time: 1.0))
        #expect(!sequence.register(at: CGPoint(x: 52, y: 51), time: 1.2))
        #expect(sequence.register(at: CGPoint(x: 51, y: 49), time: 1.4))
    }

    @Test
    func slowClicksStartANewSequence() {
        var sequence = ClickSequence()

        #expect(!sequence.register(at: .zero, time: 1.0))
        #expect(!sequence.register(at: .zero, time: 1.2))
        #expect(!sequence.register(at: .zero, time: 2.0))
        #expect(sequence.clickCount == 1)
    }

    @Test
    func distantClicksStartANewSequence() {
        var sequence = ClickSequence()

        #expect(!sequence.register(at: .zero, time: 1.0))
        #expect(!sequence.register(at: CGPoint(x: 100, y: 100), time: 1.1))
        #expect(sequence.clickCount == 1)
    }
}
