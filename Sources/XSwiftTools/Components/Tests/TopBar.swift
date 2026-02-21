import SwiftCrossUI
import Foundation

struct TopBar: View, TestRunner {
    @Environment(TopBarViewModel.self) var topBarModel
    @Environment(TestViewModel.self) var testModel
    @Environment(SBunViewModel.self) var sbunModel
    @State var selectionWidth = 0.0
    @State var showBuildErrorSheet = false
    
    var isRunningEnabled: Bool {
        guard let selected = topBarModel.selected else { return false }
        
        if selected == .test { return !testModel.isRunningTests }
        
        if case .sbun(_) = topBarModel.selected {
            return sbunModel.selectedDestination != nil
        }
        return false
    }
    
    var isSelectionChangeDisabled: Bool {
        testModel.isRunningTests ||
        sbunModel.process?.isRunning == true ||
        !topBarModel.processes.filter { $0 != .buildFailed }.isEmpty
    }
    
    var body: some View {
        Capsule()
            .stroke(.gray)
            .frame(height: 30)
            .overlay {
                ZStack {
                    HStack {
                        if let process = topBarModel.sortedProcesses.first {
                            ProcessView(process: process)
                        }
                        
                        if !topBarModel.processes.filter({ $0 == .buildFailed || $0 == .exitedWithError }).isEmpty {
                            Circle()
                                .fill(.red)
                                .frame(width: 20)
                                .overlay {
                                    Text("X")
                                        .foregroundColor(.white)
                                }
                                .onTapGesture {
                                    print("tapped")
                                    showBuildErrorSheet = true
                                }
                                .disabled(false)
                        } else if topBarModel.processes.count > 0 {
                            Circle()
                                .stroke(.blue, style: StrokeStyle(width: 3))
                                .frame(width: 20)
                                .overlay {
                                    Text("\(topBarModel.processes.count)")
                                }
                        }
                    }
                    .padding(.trailing, 10)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    
                    if let name = topBarModel.projectName {
                        HStack {
                            VStack {
                                if
                                    case .sbun(_) = topBarModel.selected,
                                    sbunModel.process?.isRunning == true
                                {
                                    RoundedRectangle(cornerRadius: 2)
                                        .fill(.gray)
                                        .frame(width: 15, height: 15)
                                        .onTapGesture {
                                            sbunModel.process?.terminate()
                                        }
                                } else {
                                    Triangle()
                                        .fill(.gray.opacity(isRunningEnabled ? 1: 0.3))
                                        .frame(width: 20, height: 20)
                                        .onTapGesture {
                                            run()
                                        }
                                }
                            }
                            .disabled(false)
                            Text(name)
                            .frame(minWidth: 100)
                            Arrow()
                                .stroke(Color.gray, style: .init(width: 1.5))
                                .frame(width: 5, height: 10)
                            Picker(of: Array(topBarModel.stringResponders), selection: topBarModel.selectedStringBinding)
                            if case .sbun(_) = topBarModel.selected {
                                Arrow()
                                    .stroke(Color.gray, style: .init(width: 1.5))
                                    .frame(width: 5, height: 10)
                                Picker(
                                    of: Array(sbunModel.availableDestinations.keys),
                                    selection: sbunModel.$selectedDestination
                                )
                                
                                if sbunModel.selectedDestination == "Local" {
                                    Arrow()
                                        .stroke(Color.gray, style: .init(width: 1.5))
                                        .frame(width: 5, height: 10)
                                    Picker(of: ["AppKitBackend", "GtkBackend"], selection: sbunModel.$localRunningBackend)
                                }
                            }
                        }
                        .padding(.leading, 10)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.trailing, 100)
                        .disabled(isSelectionChangeDisabled)
                    }
                }
            }
            .sheet(isPresented: $showBuildErrorSheet) {
                ScrollView {
                    Text(topBarModel.buildOutput)
                }
                .padding()
                .frame(width: 400, height: 500)
            }
    }
    
    private func run() {
        guard isRunningEnabled else { return }
        Task {
            if case let .sbun(name) = topBarModel.selected {
                do {
                    try await sbunModel.run(app: name, topBarModel: topBarModel)
                } catch {
                    print(error.localizedDescription)
                }
            } else if case .test = topBarModel.selected {
                for test in testModel.tests.values {
                    await runTest(test)
                }
            }
        }
    }
}

struct ProcessView: View {
    let process: TopBarProcess
    
    var body: some View {
        switch process {
            case .testing:
                Text("Testing")
            case .prepareBuilding:
                Text("Preparing Build")
            case .building(let file, let total):
                HStack {
                    Text("Building |")
                    Text("\(file)/\(total)")
                        .fontDesign(.monospaced)
                }
            case .indexing:
                Text("Indexing")
            case .buildFailed:
                Text("Build failed")
            case .running:
                Text("Running")
            case .exitedWithError:
                Text("Exited with Error")
        }
    }
}
