import SwiftCrossUI
import TestParser

struct TestSidebar: View {
    let targets: [Target]
    let tests: [Target: TargetTests]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                ForEach(targets, id: \.name) { target in
                    if let tests = tests[target] {
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
    
    var body: some View {
        RoundedRectangle(cornerRadius: 5)
            .fill(.gray.opacity(isHovered ? 0.3: 0.0))
            .frame(width: 20, height: 20)
            .overlay {
                Text("▶")
            }
            .onHover { hovering in
                isHovered = hovering
            }
            .onTapGesture {
                runTest.wrappedValue?(test)
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
