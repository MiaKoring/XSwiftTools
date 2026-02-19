import XSwiftToolsPluginInterface
import Foundation
import SwiftCrossUI

#if canImport(Darwin)
import Darwin
#else
import Glibc
#endif

@ObservableObject
final class PluginManager: @unchecked Sendable {
    var plugins: [Plugin] = []
    var uiPlugins: [UIProvidingPlugin] = []
    private var handles: [UnsafeMutableRawPointer] = []
    
    var pluginsDirectory: String {
#if os(macOS)
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        return "\(home)/Downloads"
#else
        let home = ProcessInfo.processInfo.environment["HOME"] ?? "~"
        return "\(home)/Downloads"
#endif
    }
    
#if os(macOS)
    private let ext = "dylib"
#else
    private let ext = "so"
#endif
    
    typealias CreateFunc = @convention(c) () -> UnsafeMutableRawPointer
    
    @MainActor
    func loadAllPlugins(context: PluginHostContext) {
        let fm = FileManager.default
        guard let entries = try? fm.contentsOfDirectory(atPath: pluginsDirectory) else {
            print("No plugins directory found at \(pluginsDirectory)")
            return
        }
        
        for entry in entries where entry.hasSuffix(".\(ext)") {
            let path = "\(pluginsDirectory)/\(entry)"
            load(at: path)
        }
    }
    
    @MainActor
    func load(at path: String) {
        preloadSharedLibraries()
        print("starting plugin load")
        guard let handle = dlopen(path, RTLD_NOW) else {
            let err = String(cString: dlerror())
            print("⚠️ dlopen failed for \(path): \(err)")
            return
        }
        
        guard let sym = dlsym(handle, "createPlugin") else {
            print("⚠️ No createPlugin symbol in \(path)")
            dlclose(handle)
            return
        }
        
        let create = unsafeBitCast(sym, to: CreateFunc.self)
        let raw = create()
        let plugin = Unmanaged<AnyObject>.fromOpaque(raw)
            .takeRetainedValue()
        
        guard let typed = plugin as? Plugin else {
            print("⚠️ Object doesn't conform to Plugin")
            dlclose(handle)
            return
        }
        
        //typed.activate(in: context)
        plugins.append(typed)
        handles.append(handle)
        
        if let uiPlugin = typed as? UIProvidingPlugin {
            uiPlugins.append(uiPlugin)
            
            let view = uiPlugin.buildPrimaryUI()
            
            print(type(of: view))
            print(ObjectIdentifier(AnyView.self))
            print(ObjectIdentifier(type(of: view) as Any.Type))
        }
        
        print("✅ Loaded: \(type(of: typed).pluginName)")
    }
    
    deinit {
        handles.forEach { dlclose($0) }
    }
    
    func preloadSharedLibraries() {
#if os(macOS)
        let libDir = Bundle.main.bundleURL
            .appendingPathComponent("Contents/Libraries")
            .path
#else
        // Adjust for your Linux layout
        let exe = CommandLine.arguments[0]
        let libDir = URL(fileURLWithPath: exe)
            .deletingLastPathComponent()
            .appendingPathComponent("../lib")
            .standardized
            .path
#endif
        
        let libs = [
            "libSwiftCrossUI",
            "libDefaultBackend",
            "libXSwiftToolsPluginInterface",
            // Add any other shared transitive deps here
        ]
        
        let ext: String
#if os(macOS)
        ext = "dylib"
#else
        ext = "so"
#endif
        
        for lib in libs {
            let path = "\(libDir)/\(lib).\(ext)"
            guard dlopen(path, RTLD_NOW | RTLD_GLOBAL) != nil else {
                print("⚠️ Preload failed: \(lib) — \(String(cString: dlerror()))")
                continue
            }
            print("✅ Preloaded \(lib)")
        }
    }

}
