# KeyCast ⌨️ for macOS

A minimalist, frosted-glass floating HUD for macOS that renders your shortcuts and keystrokes on-screen in real time. Perfect for screencasts, pair programming, and livestreams.

---

## Features
- **Frosted Glass Dark Pill:** Native `NSVisualEffectView` HUD floating at the bottom center of your screen.
- **Shortcuts Only Mode:** Avoids noisy clutter by only visualizing hotkey combinations (`⌘`, `⌥`, `⌃`, `⇧`) by default.
- **Auto Fade-out:** Smoothly animates out after 1.8 seconds of keyboard inactivity.
- **Multi-Space Support:** Can join all virtual spaces and full-screen apps without blinking.

---

## Build & Run

```bash
mkdir -p build && swiftc -O Sources/main.swift -o build/KeyCast
./build/KeyCast &
```

*(Note: macOS requires granting Input Monitoring / Accessibility permission in System Settings -> Privacy & Security for apps capturing global keystrokes).*

---

## License
MIT License.
