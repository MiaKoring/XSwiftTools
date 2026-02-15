import SwiftCrossUI
import DefaultBackend
import TestParser
import TestOutputParsing

struct ContentView: View {
    @Environment(\.chooseFile) var fileOpenDialog
    @State var runOutput: String = ""
    @State var viewModel = TestVM()
    @AppStorage(PathKey.self) var lastPath
    @State var updateProducer = false
    
    var body: some View {
        Button("select path & scan") { selectAndScan() }
        Button("print states") {
            print(viewModel.suiteState)
            print(viewModel.testState)
        }
        GeometryReader { proxy in
            HStack(spacing: 20) {
                TestSidebar()
                    .splitScrollViewWidth(testListWidth(for: proxy.size.width))
                    .environment(viewModel)
                
                TestOutput(runOutput: runOutput)
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
            viewModel.targets = try await parser.testTargets()
            lastPath = path
            for target in viewModel.targets {
                viewModel.tests[target] = parser.tests(in: target)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func selectAndScan() {
        viewModel.targets = []
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
        runOutput = ""
        if let suite = test as? TestSuite {
            viewModel.suiteState[suite.uiFilter] = .waiting
            for test in suite.tests {
                viewModel.testState[test.uiFilter] = .waiting
            }
        } else if let test = test as? Test {
            viewModel.testState[test.uiFilter] = .waiting
            print(test.uiFilter)
        } else if let targetTest = test as? TargetTests {
            viewModel.suiteState.removeAll()
            viewModel.testState.removeAll()
            
            for freestanding in targetTest.freestanding {
                viewModel.testState[freestanding.uiFilter] = .waiting
            }
            for suite in targetTest.suites {
                viewModel.suiteState[suite.uiFilter] = .waiting
                
                for test in suite.tests {
                    viewModel.testState[test.uiFilter] = .waiting
                }
            }
            
        }
        
        guard let lastPath else {
            print("running without path is impossibe")
            return
        }
        let parser = TestParser(path: lastPath)
                
        do {
            let lineParser = TestOutputLineParser()
            var startParsing = false
            try await parser.run(
                test,
                lineHandle: { line in
                    runOutput += line
                }
            )
            
            try? await Task.sleep(for: .seconds(2))
            updateProducer.toggle()
        } catch {
            print("running failed with: \(error.localizedDescription)")
        }
    }
    
    private func todo() {}
    
    private func testListWidth(for totalWidth: Double) -> Int {
        Int((totalWidth - 20) / 2)
    }
    
    private func startup() async {
        if let lastPath {
            await getResult(for: lastPath)
        }
    }
}

@ObservableObject
final class TestVM {
    var targets = [Target]()
    var tests = [Target: TargetTests]()
    var suiteState = [String: TestState]()
    var testState = [String: TestState]()
}

enum TestState {
    case waiting
    case running
    case passed
    case failed
}
