import XSwiftToolsSupport

@MainActor
protocol TestRunner {
    var testModel: TestViewModel { get }
    var topBarModel: TopBarViewModel { get }
}

extension TestRunner {
    func runTest(_ test: TestRunnable) async {
        testModel.runOutput = ""
        
        do {
            try await topBarModel.build(for: test)
            
            guard !topBarModel.processes.contains(.buildFailed) else { return }
            
            topBarModel.processes.append(.testing)
            try await testModel.runTest(test)
            topBarModel.processes.removeAll(where: {
                $0 == .testing
            })
        } catch {
            print("running failed with: \(error.localizedDescription)")
        }
    }
}
