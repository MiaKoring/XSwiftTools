import SwiftCrossUI
import XSwiftToolsSupport

struct TestView: View, TestRunner {
    @Environment(TestViewModel.self) var testModel: TestViewModel
    @Environment(TopBarViewModel.self) var topBarModel
    
    var body: some View {
        GeometryReader { proxy in
            HStack(spacing: 20) {
                TestSidebar()
                    .splitScrollViewWidth(testListWidth(for: proxy.size.width))
                TestOutput(runOutput: testModel.runOutput)
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
    
    private func testListWidth(for totalWidth: Double) -> Int {
        Int((totalWidth - 20) / 2)
    }
}
