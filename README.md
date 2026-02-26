## XSwiftTools
> A lightweight Xcodeless utility to enhance cross platform Swift development workflows, featuring integrated [Swift Testing](https://developer.apple.com/xcode/swift-testing/) UI and [Swift Bundler](https://github.com/moreSwift/swift-bundler) support.
<img width="939" height="583" alt="Screenshot 2026-02-26 at 20 53 39" src="https://github.com/user-attachments/assets/7cc90dcc-6638-4035-b911-f226a787a175" />
<img width="899" height="89" alt="Screenshot 2026-02-26 at 20 59 18" src="https://github.com/user-attachments/assets/823871de-e98d-455f-aa84-766df3b49d26" />

### Features
- **Swift Testing UI:** Visual interface for running and monitoring unit tests.
- **Live Sync:** Automatic updates of available tests as you write code.
- **Build Monitoring:** Real-time display of local build processes.
- **Swift Bundler Integration:**
  - Launch apps directly from the UI.
  - Toggle between Gtk and AppKit backends when running on macOS.
  - Select destinations (Local or Simulators).
- **Maintenance:** Quickly reset build caches via the menu bar.

### Platform support
- **macOS 14+** (Native Apple Silicon; Intel requires manual compilation).
- **Linux** (Planned).

### Setup
1. Download `XSwiftTools.zip` from the latest release.
2. Move it to your `/Applications` folder.
3. **Configure SBun:** Set your Swift Bundler binary path via `File > Set SBun Path`.
4. **Open Project:** Select your project root via `File > Open`.

### Roadmap
- Linux support
- Global keyboard shortcuts for running
- Native Plugins using swift and swift-cross-ui

### Technical Foundation
- [SwiftCrossUI](https://github.com/moreSwift/swift-cross-ui)
- [Swift Bundler](https://github.com/moreSwift/swift-bundler)
- [Swift Syntax](https://github.com/swiftlang/swift-syntax.git)

---
Created by [Mia](https://github.com/MiaKoring)
