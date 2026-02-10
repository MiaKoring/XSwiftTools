import SwiftCrossUI
import DefaultBackend
import TestParser

struct ContentView: View {
    @Environment(\.chooseFile) var fileOpenDialog
    @State var targets = [Target]()
    @State var tests = [Target: TargetTests]()
    @State var runOutput: String = ""
    @AppStorage(PathKey.self) var lastPath
    
    var body: some View {
        Button("select path & scan") { selectAndScan() }
        GeometryReader { proxy in
            HStack(spacing: 20) {
                TestSidebar(targets: targets, tests: tests)
                    .splitScrollViewWidth(testListWidth(for: proxy.size.width))
                
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
            targets = try await parser.testTargets()
            lastPath = path
            for target in targets {
                tests[target] = parser.tests(in: target)
                print(tests)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func selectAndScan() {
        targets = []
        tests = [:]
        
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
        guard let lastPath else {
            print("running without path is impossibe")
            return
        }
        let parser = TestParser(path: lastPath)
                
        do {
            try await parser.run(
                test,
                lineHandle: { line in
                    runOutput.append("\n\(line)")
                }
            )
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

