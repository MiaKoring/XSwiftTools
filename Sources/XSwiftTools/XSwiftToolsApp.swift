import SwiftCrossUI
import DefaultBackend

@HotReloadable
@main
struct XSwiftToolsApp: App {
    var body: some Scene {
        WindowGroup("XSwiftTools") {
            #hotReloadable {
                ContentView()
            }
        }
    }
}
