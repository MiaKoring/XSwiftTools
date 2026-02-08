import SwiftCrossUI
import DefaultBackend
import TestParser

struct ContentView: View {
    @Environment(\.chooseFile) var fileOpenDialog
    @State var targets = [Target]()
    @State var tests = [Target: TargetTests]()
    @State var parser: TestParser?
    
    var body: some View {
        Button("select path & scan") {
            targets = []
            tests = [:]
            
            Task {
                let path = await fileOpenDialog.callAsFunction(
                    title: "Project Directory",
                    allowSelectingFiles: false,
                    allowSelectingDirectories: true
                )
                guard let path = path?.relativePath else { return }
                print(path)
                let parser = TestParser(path: path)
                self.parser = parser
                
                do {
                    targets = try await parser.testTargets()
                    for target in targets {
                        tests[target] = parser.tests(in: target)
                    }
                } catch {
                    print(error.localizedDescription)
                }
            }
        }
        
        ScrollView {
            VStack(alignment: .leading) {
                ForEach(targets, id: \.name) { target in
                    Text(target.name)
                    if let tests = tests[target] {
                        
                        VStack(alignment: .leading) {
                            if !tests.freestanding.isEmpty {
                                Text("Freestanding")
                                ForEach(tests.freestanding, id: \.function) { test in
                                    TestLine(test: test)
                                }
                                .padding(.leading, 20)
                            }
                            
                            ForEach(tests.suites, id: \.structName) { suite in
                                SuiteView(suite: suite)
                            }
                        }
                        .padding(.leading, 20)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
    }
}

struct SuiteView: View {
    let suite: TestSuite
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(suite.name ?? suite.structName)
            
            ForEach(suite.tests, id: \.function) { test in
                TestLine(test: test)
            }
            .padding(.leading, 20)
        }
    }
}

struct TestLine: View {
    let test: Test
    var body: some View {
        HStack {
            if let name = test.name {
                Text(name)
                Text("\(test.function)()")
                    .foregroundColor(.gray)
            } else {
                Text("\(test.function)()")
            }
        }
    }
}
