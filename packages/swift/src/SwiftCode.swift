import Foundation
import AppKit

// MARK: - Application Model
struct ApplicationItem: Codable {
    let id: String
    let name: String
    let path: String
    let icon: String // Base64 encoded icon
}

// MARK: - Application Service
class ApplicationService {
    static let shared = ApplicationService()
    var applications: [ApplicationItem] = []
    
    init() {
        // Add some mock apps
        applications = [
            ApplicationItem(id: "1", name: "Slack", path: "/Applications/Slack.app", icon: getIcon(path: "/Applications/Slack.app")),
            ApplicationItem(id: "2", name: "Notion", path: "/Applications/Notion.app", icon: getIcon(path: "/Applications/Notion.app")),
            ApplicationItem(id: "3", name: "Figma", path: "/Applications/Figma.app", icon: getIcon(path: "/Applications/Figma.app")),
            ApplicationItem(id: "4", name: "Safari", path: "/Applications/Safari.app", icon: getIcon(path: "/Applications/Safari.app")),
            ApplicationItem(id: "5", name: "Mail", path: "/System/Applications/Mail.app", icon: getIcon(path: "/System/Applications/Mail.app")),
            ApplicationItem(id: "6", name: "Terminal", path: "/System/Applications/Utilities/Terminal.app", icon: getIcon(path: "/System/Applications/Utilities/Terminal.app"))
        ]
    }
    
    func getIcon(path: String) -> String {
        let icon = NSWorkspace.shared.icon(forFile: path)
        // Resize to standard size if needed, but default is usually fine. 
        // Let's ensure it's small to save bandwidth/memory
        icon.size = NSSize(width: 64, height: 64)
        
        guard let tiffData = icon.tiffRepresentation,
              let bitmapImage = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
            return ""
        }
        
        return pngData.base64EncodedString()
    }
    
    func search(query: String) -> [ApplicationItem] {
        if query.isEmpty {
            return []
        }
        return applications.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }
    
    func launch(appId: String) {
        guard let app = applications.first(where: { $0.id == appId }) else {
            print("App with ID \(appId) not found")
            return
        }
        
        let url = URL(fileURLWithPath: app.path)
        let config = NSWorkspace.OpenConfiguration()
        
        NSWorkspace.shared.openApplication(at: url, configuration: config) { app, error in
            if let error = error {
                print("Failed to launch \(app?.localizedName ?? "app"): \(error)")
            } else {
                print("Launched \(app?.localizedName ?? "app")")
            }
        }
    }
}

// MARK: - Main Swift Code
@objc
public class SwiftCode: NSObject {
    
    // Callbacks provided by JS (keeping these as they might be used elsewhere or in future)
    private static var todoAddedCallback: ((String) -> Void)?
    private static var todoUpdatedCallback: ((String) -> Void)?
    private static var todoDeletedCallback: ((String) -> Void)?

    @objc
    public static func helloWorld(_ input: String) -> String {
        return "Hello from Swift! You said: \(input)"
    }
    
    @objc
    public static func searchApplications(_ query: String) -> String {
        let results = ApplicationService.shared.search(query: query)
        do {
            let jsonData = try JSONEncoder().encode(results)
            return String(data: jsonData, encoding: .utf8) ?? "[]"
        } catch {
            print("Failed to encode results: \(error)")
            return "[]"
        }
    }
    
    @objc
    public static func launchApplication(_ id: String) {
        ApplicationService.shared.launch(appId: id)
    }

    // Keep the callback setters
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
}
