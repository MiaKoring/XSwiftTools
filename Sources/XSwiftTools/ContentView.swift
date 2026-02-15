import SwiftCrossUI
import DefaultBackend
import TestParser

struct ContentView: View {
    @Environment(\.chooseFile) var fileOpenDialog
    @State var viewModel: TestVM = TestVM(path: nil)
    @AppStorage(PathKey.self) var lastPath
    
    var body: some View {
        Button("select path & scan") { selectAndScan() }
        .disabled(viewModel.isRunningTests)
        Button("print states") {
            print(viewModel.tests.values.first?.suites.map { $0.name } ?? "")
            print(viewModel.suiteState)
            print(viewModel.testState)
        }
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
        .task(startup)
        .environment(\.runTest, UncheckedSendable(wrappedValue: { test in
                 Task {
                     await runTest(test)
                 }
             })
        )
    }
    
    private func getResult(for path: String) async {
        let parser = TestParser(path: path)
        
        do {
            let targets = try await parser.testTargets()
            lastPath = path
            viewModel.path = path
            
            for target in targets {
                viewModel.tests[target] = parser.tests(in: target)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func selectAndScan() {
        viewModel.tests = [:]
        
        Task {
            let path = await fileOpenDialog.callAsFunction(
                title: "Project Directory",
                allowSelectingFiles: false,
                allowSelectingDirectories: true
            )
            guard let path = path?.relativePath else { return }
            await getResult(for: path)
        }
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
    
    private func startup() async {
        if let lastPath {
            await getResult(for: lastPath)
        }
    }
}
