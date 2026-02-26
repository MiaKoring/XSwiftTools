import FSEventsWrapper

class DirectoryMonitor {
    private var stream: FSEventStream?
    
    func startMonitoring(path: String, onChange: @escaping @Sendable () -> Void) {
        stream = FSEventStream(path: path) { stream, event in
            if case .generic = event {
                onChange()
            }
        }
        
        stream?.startWatching()
    }
    
    func stop() {
        guard let stream else { return }
        stream.stopWatching()
    }
}

