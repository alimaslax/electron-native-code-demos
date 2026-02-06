import Foundation
import SwiftUI
import AppKit

@objc
public class SwiftCode: NSObject {
    private static var windowController: NSWindowController?
    
    // Callbacks provided by JS
    private static var todoAddedCallback: ((String) -> Void)?
    private static var todoUpdatedCallback: ((String) -> Void)?
    private static var todoDeletedCallback: ((String) -> Void)?

    @objc
    public static func helloWorld(_ input: String) -> String {
        return "Hello from Swift! You said: \(input)"
    }

    @objc
    public static func setTodoAddedCallback(_ callback: @escaping (String) -> Void) {
        todoAddedCallback = callback
    }

    @objc
    public static func setTodoUpdatedCallback(_ callback: @escaping (String) -> Void) {
        todoUpdatedCallback = callback
    }

    @objc
    public static func setTodoDeletedCallback(_ callback: @escaping (String) -> Void) {
        todoDeletedCallback = callback
    }

    @objc
    public static func helloGui() -> Void {
        // Create the LauncherView with some dummy bindings
        let contentView = NSHostingView(rootView: LauncherViewWrapper())
        
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 600, height: 450),
            styleMask: [.titled, .closable, .miniaturizable, .resizable],
            backing: .buffered,
            defer: false
        )

        window.title = "Launcher Demo"
        window.contentView = contentView
        window.center()
        
        // Hide title bar for authentic look if desired, but keep it for debug movability
        // window.titlebarAppearsTransparent = true
        // window.styleMask.insert(.fullSizeContentView)

        windowController = NSWindowController(window: window)
        windowController?.showWindow(nil)

        NSApp.activate(ignoringOtherApps: true)
    }
}

// MARK: - Wrapper for bindings
struct LauncherViewWrapper: View {
    @State private var currentTab: AppTab = .home
    @State private var previousTab: AppTab = .home
    
    var body: some View {
        LauncherView(
            currentTab: $currentTab,
            previousTab: $previousTab,
            onAppSelected: {
                print("App selected or dismissed")
            }
        )
    }
}

// MARK: - Mocks for Dependencies

enum AppTab: String, CaseIterable, Identifiable, Hashable {
    case home
    case settings
    case terminal
    case browser
    
    var id: String { rawValue }
    
    var name: String {
        switch self {
        case .home: return "Home"
        case .settings: return "Settings"
        case .terminal: return "Terminal"
        case .browser: return "Browser"
        }
    }
    
    var icon: String {
        switch self {
        case .home: return "house"
        case .settings: return "gear"
        case .terminal: return "terminal"
        case .browser: return "globe"
        }
    }
    
    var color: Color {
        switch self {
        case .home: return .blue
        case .settings: return .gray
        case .terminal: return .black
        case .browser: return .green
        }
    }
}

struct ApplicationItem: Identifiable, Hashable {
    let id: String
    let name: String
    let url: URL
    let icon: NSImage
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    static func == (lhs: ApplicationItem, rhs: ApplicationItem) -> Bool {
        lhs.id == rhs.id
    }
}

enum WindowTransparency {
    case transparent
    case partial
    case opaque
}

class Settings: ObservableObject {
    static let shared = Settings()
    @Published var windowTransparency: WindowTransparency = .partial
    @Published var chatProvider: String = "openai"
}

struct APIProvider {
    let id: String
    let color: Color
    
    static let defaultProviders: [APIProvider] = [
        APIProvider(id: "openai", color: .purple),
        APIProvider(id: "anthropic", color: .orange)
    ]
}

class ApplicationService: ObservableObject {
    static let shared = ApplicationService()
    @Published var applications: [ApplicationItem] = []
    
    init() {
        // Add some mock apps
        if let icon = NSImage(systemSymbolName: "app", accessibilityDescription: nil) {
            applications = [
                ApplicationItem(id: "1", name: "Slack", url: URL(string: "file:///Applications/Slack.app")!, icon: icon),
                ApplicationItem(id: "2", name: "Notion", url: URL(string: "file:///Applications/Notion.app")!, icon: icon),
                ApplicationItem(id: "3", name: "Figma", url: URL(string: "file:///Applications/Figma.app")!, icon: icon)
            ]
        }
    }
    
    func launch(app: ApplicationItem) {
        print("Launching \(app.name)")
    }
}


// MARK: - Ported LauncherView

struct LauncherView: View {
    @Binding var currentTab: AppTab
    @Binding var previousTab: AppTab
    var onAppSelected: () -> Void
    @State private var searchText = ""
    @State private var selectedIndex = 0
    @ObservedObject var settings = Settings.shared
    @ObservedObject var appService = ApplicationService.shared
    
    // Unified Item Type
    enum LauncherItem: Identifiable, Hashable {
        case tab(AppTab)
        case app(ApplicationItem)
        
        var id: String {
            switch self {
            case .tab(let tab): return "tab-\(tab.rawValue)"
            case .app(let app): return "app-\(app.id)"
            }
        }
    }
    
    // Filtered items based on search text
    var filteredItems: [LauncherItem] {
        var items: [LauncherItem] = []
        
        // Always show AppTabs at the top (unless filtered out)
        if searchText.isEmpty {
             return AppTab.allCases.map { .tab($0) }
        }
        
        let query = searchText.lowercased()
        
        // Filter Tabs
        let matchingTabs = AppTab.allCases.filter { $0.name.localizedCaseInsensitiveContains(query) }
        items.append(contentsOf: matchingTabs.map { .tab($0) })
        
        // Filter Apps
        let matchingApps = appService.applications.filter { $0.name.localizedCaseInsensitiveContains(query) }
        items.append(contentsOf: matchingApps.map { .app($0) })
        
        return items
    }
    
    private var providerColor: Color {
        APIProvider.defaultProviders.first { $0.id == settings.chatProvider }?.color ?? .cyan
    }
    
    var body: some View {
        ZStack {
            // Background - match Terminal and NotepadView style
            backgroundView
            
            // Content
            VStack(spacing: 0) {
                // Header with arrow and search
                headerView
                
                // App List
                ScrollViewReader { proxy in
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 16) {
                            // Apps Section
                            appsSection
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 40)
                    }
                    .onChange(of: selectedIndex) { newIndex in
                        proxy.scrollTo(newIndex, anchor: .center)
                    }
                }
            }
        }
        .frame(width: 600, height: 450) // Fixed rectangular launcher size
        // Keyboard navigation
        .background(
            Extensions.KeyboardHandler { key in
                handleKey(key)
            }
        )
        .onAppear {
            // Reset state on appear
            searchText = ""
            selectedIndex = 0
        }
    }
    
    // MARK: - Background
    
    private var backgroundView: some View {
        ZStack {
            switch settings.windowTransparency {
            case .transparent:
                Color.clear
            case .partial:
                Color(white: 0.06).opacity(0.7)
            case .opaque:
                Color(white: 0.06)
            }
            
            // Subtle gradient accent
            LinearGradient(
                colors: [providerColor.opacity(0.05), Color.clear],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack(alignment: .center) {
            HStack(spacing: 8) {
                Text(">")
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(providerColor)
                
                TextField("Search", text: $searchText)
                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                    .textFieldStyle(.plain)
                    .foregroundColor(.white)
                    .onSubmit {
                        if !filteredItems.isEmpty {
                            selectItem(filteredItems[selectedIndex])
                        }
                    }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 24)
        .padding(.bottom, 8)
    }
    
    // MARK: - Apps Section
    
    private var appsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "square.grid.2x2")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                
                Text(searchText.isEmpty ? "ALL APPS" : "SEARCH RESULTS")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.white.opacity(0.5))
                    .tracking(1)
            }
            
            if filteredItems.isEmpty {
                Text("No apps found")
                    .font(.system(size: 13, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 12) {
                    ForEach(Array(filteredItems.enumerated()), id: \.element) { index, item in
                        LauncherItemCard(
                            item: item,
                            isSelected: index == selectedIndex,
                            shortcut: index < 9 ? "⌥\(index + 1)" : nil,
                            accentColor: providerColor
                        )
                        .id(index)
                        .onTapGesture {
                            selectItem(item)
                        }
                        .onHover { isHovering in
                            if isHovering {
                                selectedIndex = index
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func handleKey(_ key: NSEvent.TypelessSpecialKey) {
        switch key {
        case .upArrow:
            selectedIndex = max(0, selectedIndex - 1)
        case .downArrow:
            if !filteredItems.isEmpty {
                selectedIndex = min(filteredItems.count - 1, selectedIndex + 1)
            }
        case .carriageReturn, .enter:
            if !filteredItems.isEmpty && selectedIndex < filteredItems.count {
                selectItem(filteredItems[selectedIndex])
            }
        case .escape:
            onAppSelected() // Dismiss launcher on Escape
        default:
            break
        }
    }
    
    private func selectItem(_ item: LauncherItem) {
        switch item {
        case .tab(let tab):
            previousTab = currentTab
            withAnimation(.easeInOut(duration: 0.2)) {
                currentTab = tab
            }
            onAppSelected() // Closes launcher
            
        case .app(let app):
            appService.launch(app: app)
            onAppSelected() // Closes launcher
        }
    }
}

// MARK: - Card Component

struct LauncherItemCard: View {
    let item: LauncherView.LauncherItem
    let isSelected: Bool
    let shortcut: String?
    let accentColor: Color
    
    var body: some View {
        HStack(spacing: 14) {
            // Icon
            iconView
                .frame(width: 32, height: 32)
            
            // Name
            VStack(alignment: .leading, spacing: 4) {
                Text(name)
                    .font(.system(size: 15, weight: .medium, design: .monospaced))
                    .foregroundColor(.white)
                
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.system(size: 12, design: .monospaced))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            
            Spacer()
            
            // Shortcut badge
            if let shortcut = shortcut {
                Text(shortcut)
                    .font(.system(size: 11, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.4))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.06))
                    )
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(isSelected ? accentColor.opacity(0.15) : Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? accentColor.opacity(0.3) : Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
    
    @ViewBuilder
    var iconView: some View {
        switch item {
        case .tab(let tab):
            ZStack {
                Circle()
                    .fill(tab.color.opacity(0.15))
                    .frame(width: 32, height: 32)
                
                Image(systemName: tab.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(tab.color)
            }
        case .app(let app):
            Image(nsImage: app.icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
    }
    
    var name: String {
        switch item {
        case .tab(let tab): return tab.name
        case .app(let app): return app.name
        }
    }
    
    var subtitle: String? {
        switch item {
        case .tab: return nil
        case .app(let app): return app.url.deletingLastPathComponent().path
        }
    }
}

// MARK: - Extensions Namespace
enum Extensions {
    struct KeyboardHandler: NSViewRepresentable {
        var onKey: (NSEvent.TypelessSpecialKey) -> Void
        
        func makeNSView(context: Context) -> NSView {
            let view = KeyListeningView()
            view.onKey = onKey
            return view
        }
        
        func updateNSView(_ nsView: NSView, context: Context) {}
        
        class KeyListeningView: NSView {
            var onKey: ((NSEvent.TypelessSpecialKey) -> Void)?
            
            override var acceptsFirstResponder: Bool { true }
            
            override func keyDown(with event: NSEvent) {
                if let specialKey = event.typelessSpecialKey {
                    onKey?(specialKey)
                } else if event.keyCode == 36 { // Enter
                    onKey?(.enter)
                } else {
                    super.keyDown(with: event)
                }
            }
        }
    }
}


// MARK: - NSEvent Extensions

extension NSEvent {
    enum TypelessSpecialKey {
        case upArrow
        case downArrow
        case leftArrow
        case rightArrow
        case escape
        case enter
        case carriageReturn
        case backspace
        case delete
        case tab
    }
    
    var typelessSpecialKey: TypelessSpecialKey? {
        switch keyCode {
        case 126: return .upArrow
        case 125: return .downArrow
        case 123: return .leftArrow
        case 124: return .rightArrow
        case 53: return .escape
        case 36: return .enter
        case 76: return .enter // Numpad Enter
        case 52: return .enter // Numpad Enter
        case 51: return .backspace
        case 117: return .delete
        case 48: return .tab
        default: return nil
        }
    }
}
