import Cocoa

// MARK: - Menu Bar Vector Icon
func createMenuBarKeycastIcon() -> NSImage {
    let size = NSSize(width: 18, height: 18)
    let image = NSImage(size: size, flipped: false) { rect in
        guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
        ctx.setStrokeColor(NSColor.black.cgColor)
        ctx.setLineWidth(1.3)
        
        // Keycap square
        let keyRect = CGRect(x: 2.5, y: 2.5, width: 13, height: 13)
        let keyPath = CGPath(roundedRect: keyRect, cornerWidth: 3, cornerHeight: 3, transform: nil)
        ctx.addPath(keyPath)
        ctx.strokePath()
        
        // Command symbol or dot
        ctx.setLineWidth(1.1)
        ctx.move(to: CGPoint(x: 6.5, y: 9))
        ctx.addLine(to: CGPoint(x: 11.5, y: 9))
        ctx.strokePath()
        return true
    }
    image.isTemplate = true
    return image
}

// MARK: - Key HUD Floating Pill Window
class KeyHUDWindow: NSWindow {
    let label = NSTextField(labelWithString: "")
    var fadeTimer: Timer?
    
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 220, height: 50),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        self.isOpaque = false
        self.backgroundColor = .clear
        self.level = NSWindow.Level(Int(CGWindowLevelForKey(.screenSaverWindow)))
        self.ignoresMouseEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary, .ignoresCycle]
        self.hasShadow = true
        
        // Visual Effect View (Frosted Glass Dark Pill)
        let visualEffect = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: 220, height: 50))
        visualEffect.material = .hudWindow
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 14
        visualEffect.layer?.masksToBounds = true
        
        // Border ring
        visualEffect.layer?.borderColor = NSColor(white: 1.0, alpha: 0.18).cgColor
        visualEffect.layer?.borderWidth = 1.0
        
        label.frame = visualEffect.bounds
        label.alignment = .center
        label.font = NSFont.monospacedSystemFont(ofSize: 18, weight: .semibold)
        label.textColor = NSColor(white: 0.95, alpha: 1.0)
        visualEffect.addSubview(label)
        
        self.contentView = visualEffect
        reposition()
    }
    
    func reposition() {
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - 110
            let y = screenFrame.minY + 60 // Float 60px from bottom dock
            self.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }
    
    func displayKeyCombination(_ string: String) {
        fadeTimer?.invalidate()
        reposition()
        label.stringValue = string
        self.alphaValue = 1.0
        self.orderFrontRegardless()
        
        // Fade out after 1.8 seconds of inactivity
        fadeTimer = Timer.scheduledTimer(withTimeInterval: 1.8, repeats: false) { [weak self] _ in
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.4
                self?.animator().alphaValue = 0.0
            }, completionHandler: {
                self?.orderOut(nil)
            })
        }
    }
}

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    var hudWindow: KeyHUDWindow!
    var eventMonitor: Any?
    var onlyShortcuts: Bool = true
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = createMenuBarKeycastIcon()
        
        hudWindow = KeyHUDWindow()
        buildMenu()
        startKeyMonitor()
    }
    
    func buildMenu() {
        let menu = NSMenu()
        let modeItem = NSMenuItem(title: onlyShortcuts ? "Mode: Shortcuts Only (⌘/⌥/⌃)" : "Mode: All Keystrokes", action: #selector(toggleMode), keyEquivalent: "")
        modeItem.target = self
        menu.addItem(modeItem)
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit KeyCast", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }
    
    @objc func toggleMode() {
        onlyShortcuts.toggle()
        buildMenu()
    }
    
    func startKeyMonitor() {
        // Monitors key events globally across the system
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self = self else { return }
            
            var mods = ""
            if event.modifierFlags.contains(.command) { mods += "⌘ " }
            if event.modifierFlags.contains(.option) { mods += "⌥ " }
            if event.modifierFlags.contains(.control) { mods += "⌃ " }
            if event.modifierFlags.contains(.shift) { mods += "⇧ " }
            
            if self.onlyShortcuts && mods.isEmpty {
                return
            }
            
            let chars = event.charactersIgnoringModifiers?.uppercased() ?? ""
            let combo = "\(mods)\(chars)".trimmingCharacters(in: .whitespaces)
            if !combo.isEmpty {
                DispatchQueue.main.async {
                    self.hudWindow.displayKeyCombination(combo)
                }
            }
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.setActivationPolicy(.accessory)
app.run()
