import SwiftCrossUI
import DefaultBackend

#if canImport(SwiftBundlerRuntime)
import SwiftBundlerRuntime
#endif

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
