import SwiftCrossUI
import TestParser

struct TestView: View {
    @Environment(TestViewModel.self) var viewModel
    @Environment(TopBarViewModel.self) var topBarModel
    
    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: 20) {
                TestSidebar()
                    .environment(viewModel)
                    .splitScrollViewWidth(testListWidth(for: proxy.size.width))
                TestOutput(runOutput: viewModel.runOutput)
                    .splitScrollViewWidth(testListWidth(for: proxy.size.width))
            }
        }
        .environment(
            \.runTest,
             UncheckedSendable(wrappedValue: { test in
                 Task {
                     await runTest(test)
                 }
             })
        )
    }
    
    private func runTest(_ test: TestRunnable) async {
        viewModel.runOutput = ""
        
        do {
            try await topBarModel.build(for: test)
            
            guard !topBarModel.processes.contains(.buildFailed) else { return }
            
            topBarModel.processes.append(.testing)
            try await viewModel.runTest(test)
            topBarModel.processes.removeAll(where: {
                $0 == .testing
            })
        } catch {
            print("running failed with: \(error.localizedDescription)")
        }
    }
    
    private func testListWidth(for totalWidth: Double) -> Int {
        Int((totalWidth - 20) / 2)
    }
}
