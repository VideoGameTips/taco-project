# Claude Crab

A tiny macOS menu-bar app. Triple-click (or triple-tap with **Tap to click**
enabled) anywhere and a pixel crab appears at the pointer, then wanders around
the desktop.

## Run it

Open `Package.swift` in Xcode and press **Run**, or use Terminal:

```sh
swift run
```

The crab icon in the menu bar can summon a crab, clear all crabs, or quit.
Building requires a current full Xcode installation (not a mismatched standalone
Command Line Tools installation).

## Build a standalone app

```sh
chmod +x build-app.sh
./build-app.sh
open "build/Claude Crab.app"
```

The built app is written to `build/Claude Crab.app`.

If macOS asks for Input Monitoring permission, enable **Claude Crab** in
**System Settings → Privacy & Security → Input Monitoring**, then relaunch it.
Enable **Accessibility** when prompted to let the crab recognize text boxes and
other controls inside apps as physical platforms.
Enable **Screen Recording** so Claude Crab can reject invisible Accessibility
rectangles and walk only on edges that are actually rendered on screen. Relaunch
the app after granting this permission.

## Notes

- Each triple-click summons another crab.
- Click and drag a crab to pick it up; release to toss it with momentum.
- Nearby crabs become friends. Dragging one far away, or letting one fall a
  long distance, makes it angry.
- Angry crabs launch harmless cartoon projectiles toward the pointer.
- A severe fall causes anger; an extreme fall kills the crab after a brief
  skull animation.
- Right-click deletes a crab. A nearby friend will either grieve or enter
  nuclear rage and rapidly throw cartoon radioactive bombs.
- Crabs float above normal windows, ignore mouse input, and follow you across
  Spaces.
- The visual is drawn directly in Swift from simple rectangles, based on the
  supplied pixel-crab reference, so it stays perfectly sharp.
