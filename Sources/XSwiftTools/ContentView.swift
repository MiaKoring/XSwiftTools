import SwiftCrossUI
import DefaultBackend
import TestParser

struct ContentView: View {
    @Environment(TestViewModel.self) var viewModel
    @Environment(TopBarViewModel.self) var topBarModel
    var body: some View {
        VStack {
            TopBar()
            GeometryReader { proxy in
                HStack(spacing: 20) {
                    TestSidebar()
                        .environment(viewModel)
                        .splitScrollViewWidth(testListWidth(for: proxy.size.width))
                    TestOutput(runOutput: viewModel.runOutput)
                        .splitScrollViewWidth(testListWidth(for: proxy.size.width))
                }
            }
        }
        .padding()
        .environment(\.runTest, UncheckedSendable(wrappedValue: { test in
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
