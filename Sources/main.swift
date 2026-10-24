import Cocoa
import ApplicationServices

// MARK: - Menu Bar Vector Icon
func createMenuBarKeycastIcon() -> NSImage {
    let size = NSSize(width: 18, height: 18)
    let image = NSImage(size: size, flipped: false) { rect in
        guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
        ctx.setStrokeColor(NSColor.black.cgColor)
        ctx.setLineWidth(1.3)
        
        let keyRect = CGRect(x: 2.5, y: 2.5, width: 13, height: 13)
        let keyPath = CGPath(roundedRect: keyRect, cornerWidth: 3, cornerHeight: 3, transform: nil)
        ctx.addPath(keyPath)
        ctx.strokePath()
        
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
            contentRect: NSRect(x: 0, y: 0, width: 260, height: 56),
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
        
        let visualEffect = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: 260, height: 56))
        visualEffect.material = .hudWindow
        visualEffect.state = .active
        visualEffect.wantsLayer = true
        visualEffect.layer?.cornerRadius = 16
        visualEffect.layer?.masksToBounds = true
        visualEffect.layer?.borderColor = NSColor(white: 1.0, alpha: 0.22).cgColor
        visualEffect.layer?.borderWidth = 1.0
        
        label.frame = visualEffect.bounds
        label.alignment = .center
        label.font = NSFont.monospacedSystemFont(ofSize: 20, weight: .bold)
        label.textColor = NSColor(white: 0.96, alpha: 1.0)
        visualEffect.addSubview(label)
        
        self.contentView = visualEffect
        reposition()
    }
    
    func reposition() {
        if let screen = NSScreen.main {
            let screenFrame = screen.visibleFrame
            let x = screenFrame.midX - 130
            let y = screenFrame.minY + 60
            self.setFrameOrigin(NSPoint(x: x, y: y))
        }
    }
    
    func displayKeyCombination(_ string: String) {
        fadeTimer?.invalidate()
        reposition()
        label.stringValue = string
        self.alphaValue = 1.0
        self.orderFrontRegardless()
        
        fadeTimer = Timer.scheduledTimer(withTimeInterval: 1.8, repeats: false) { [weak self] _ in
            NSAnimationContext.runAnimationGroup({ context in
                context.duration = 0.35
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
    var onlyShortcuts: Bool = false // Default to showing all keystrokes for instant visual feedback!
    var permissionTimer: Timer?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = createMenuBarKeycastIcon()
        
        hudWindow = KeyHUDWindow()
        buildMenu()
        
        // Show launch test greeting HUD
        hudWindow.displayKeyCombination("KeyCast Ready ⌨️")
        
        checkAccessibilityPermission()
    }
    
    func checkAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        let isTrusted = AXIsProcessTrustedWithOptions(options)
        
        if isTrusted {
            startKeyMonitor()
        } else {
            // Poll until user enables it in System Settings
            hudWindow.displayKeyCombination("Grant Accessibility ⚠️")
            permissionTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] timer in
                if AXIsProcessTrusted() {
                    timer.invalidate()
                    self?.hudWindow.displayKeyCombination("Access Granted! ✨")
                    self?.startKeyMonitor()
                    self?.buildMenu()
                }
            }
        }
    }
    
    func buildMenu() {
        let menu = NSMenu()
        
        let isTrusted = AXIsProcessTrusted()
        let permStatus = isTrusted ? "Accessibility: Granted ✅" : "Accessibility: Click to Grant ⚠️"
        let permItem = NSMenuItem(title: permStatus, action: #selector(openAccessibilitySettings), keyEquivalent: "")
        permItem.target = self
        menu.addItem(permItem)
        
        menu.addItem(NSMenuItem.separator())
        
        let testItem = NSMenuItem(title: "Test HUD Display", action: #selector(testHUD), keyEquivalent: "t")
        testItem.target = self
        menu.addItem(testItem)
        
        let modeTitle = onlyShortcuts ? "Mode: Shortcuts Only (⌘/⌥/⌃)" : "Mode: All Keystrokes (Letters + Keys)"
        let modeItem = NSMenuItem(title: modeTitle, action: #selector(toggleMode), keyEquivalent: "")
        modeItem.target = self
        menu.addItem(modeItem)
        
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit KeyCast", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        statusItem.menu = menu
    }
    
    @objc func testHUD() {
        hudWindow.displayKeyCombination("⌘ + ⇧ + K")
    }
    
    @objc func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }
    
    @objc func toggleMode() {
        onlyShortcuts.toggle()
        buildMenu()
        hudWindow.displayKeyCombination(onlyShortcuts ? "Shortcuts Only" : "All Keystrokes")
    }
    
    func startKeyMonitor() {
        guard eventMonitor == nil else { return }
        
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
            
            var keyStr = ""
            switch event.keyCode {
            case 36: keyStr = "⏎ Return"
            case 48: keyStr = "⇥ Tab"
            case 49: keyStr = "␣ Space"
            case 51: keyStr = "⌫ Delete"
            case 53: keyStr = "⎋ Esc"
            case 123: keyStr = "←"
            case 124: keyStr = "→"
            case 125: keyStr = "↓"
            case 126: keyStr = "↑"
            default:
                keyStr = event.charactersIgnoringModifiers?.uppercased() ?? ""
            }
            
            let combo = "\(mods)\(keyStr)".trimmingCharacters(in: .whitespaces)
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
