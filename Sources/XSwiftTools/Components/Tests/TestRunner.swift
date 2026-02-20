import SwiftCrossUI
import TestParser

struct TestSidebar: View {
    @Environment(TestViewModel.self) var viewModel
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                ForEach(viewModel.tests.keys, id: \.name) { target in
                    if let tests = viewModel.tests[target] {
                        RunnableRow(test: tests) {
                            Text(tests.targetName)
                                .padding(.trailing, 30)
                        }
                        VStack(alignment: .leading) {
                            if !tests.freestanding.isEmpty {
                                Text("Freestanding")
                                ForEach(tests.freestanding, id: \.functionName) { test in
                                    TestLine(test: test)
                                }
                                .informedLeadingPadding(20)
                            }
                            
                            ForEach(tests.suites, id: \.structName) { suite in
                                SuiteView(suite: suite)
                            }
                        }
                        .informedLeadingPadding(20)
                    }
                }
            }
        }
        .lineLimit(1)
    }
}

struct RunnableRow<Label: View>: View {
    let test: TestRunnable
    let label: Label
    @Environment(\.testListWidth) var totalWidth
    @Environment(\.externallyAppliedLeadingPadding) var leadingPadding
    
    init(test: TestRunnable, label: @escaping () -> Label) {
        self.test = test
        self.label = label()
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            label
            RunButton(test: test)
                .padding(.leading, totalWidth - 30 - leadingPadding)
                .padding(.trailing, 10)
        }
    }
}

struct RunButton: View {
    let test: TestRunnable
    @Environment(\.runTest) var runTest
    @State var isHovered = false
    
    @Environment(TestViewModel.self) var viewModel
    
    var state: TestState? {
        if test is Test {
            return viewModel.testState[test.filter]
        }
        if test is TestSuite {
            return viewModel.suiteState[test.filter]
        }
        return nil
    }
    
    var color: Color {
        switch state {
            case .passed:
                .green
            case .failed:
                .red
            case nil, .waiting, .running:
                .gray
        }
    }
    
    var opacity: Double {
        if state == .passed || state == .failed {
            return 1
        }
        if isHovered { return 0.3 }
        return 0
    }
    
    var body: some View {
        if state != .waiting && state != .running {
            RoundedRectangle(cornerRadius: 5)
                .fill(color.opacity(opacity))
                .frame(width: 20, height: 20)
                .overlay {
                    if isHovered {
                        if !viewModel.isRunningTests {
                            Text("▶")
                        } else {
                            Text("x")
                        }
                    } else if state == .passed {
                        Text("✓")
                            .foregroundColor(.white)
                    } else if state == .failed {
                        Text("x")
                            .foregroundColor(.white)
                    } else {
                        Text("▶")
                    }
                }
                .onHover { hovering in
                    isHovered = hovering
                }
                .onTapGesture {
                    if !viewModel.isRunningTests {
                        runTest.wrappedValue?(test)
                    }
                }
        } else {
            ProgressView()
            .resizable()
            .frame(width: 20, height: 20)
        }
    }
}

struct TestLine: View {
    let test: Test
    @Environment(\.testListWidth) var width
    
    var body: some View {
        RunnableRow(test: test) {
            HStack {
                if let name = test.name {
                    Text(name)
                    Text("\(test.untickedFunctionName)()")
                        .foregroundColor(.gray)
                } else {
                    Text("\(test.untickedFunctionName)()")
                }
            }
            .padding(.trailing, 30)
        }
    }
}

struct SuiteView: View {
    let suite: TestSuite
    @Environment(\.testListWidth) var width
    
    var body: some View {
        VStack(alignment: .leading) {
            RunnableRow(test: suite) {
                Text(suite.name ?? suite.structName)
                    .padding(.trailing, 30)
            }
            
            ForEach(suite.tests, id: \.functionName) { test in
                TestLine(test: test)
            }
            .informedLeadingPadding(20)
        }
    }
}
