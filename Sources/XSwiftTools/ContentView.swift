import SwiftCrossUI
import DefaultBackend
import TestParser

struct ContentView: View {
    @Environment(TestVM.self) var viewModel
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
            try await viewModel.runTest(test)
        } catch {
            print("running failed with: \(error.localizedDescription)")
        }
    }
    
    private func testListWidth(for totalWidth: Double) -> Int {
        Int((totalWidth - 20) / 2)
    }
}
