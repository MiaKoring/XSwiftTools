import SwiftCrossUI
import Foundation

struct TopBar: View {
    @Environment(TopBarViewModel.self) var viewModel
    @Environment(TestViewModel.self) var testViewModel
    @Environment(SBunViewModel.self) var sbunViewModel
    @State var textWidth = 0.0
    @State var showBuildErrorSheet = false
    
    var isRunningEnabled: Bool {
        guard let selected = viewModel.selected else { return false }
        
        if selected == .test { return !testViewModel.isRunningTests }
        
        if case .sbun(_) = viewModel.selected {
            return sbunViewModel.selectedDestination != nil
        }
        return false
    }
    
    var body: some View {
        Capsule()
            .stroke(.gray)
            .frame(height: 30)
            .overlay {
                HStack {
                    if let process = viewModel.sortedProcesses.first {
                        ProcessView(process: process)
                    }
                    
                    if viewModel.processes.contains(.buildFailed) {
                        Circle()
                            .stroke(.red, style: StrokeStyle(width: 3))
                            .frame(width: 20)
                            .overlay {
                                Text("X")
                                    .foregroundColor(.red)
                            }
                            .onTapGesture {
                                showBuildErrorSheet = true
                            }
                    } else if viewModel.processes.count > 0 {
                        Circle()
                            .stroke(.blue, style: StrokeStyle(width: 3))
                            .frame(width: 20)
                            .overlay {
                                Text("\(viewModel.processes.count)")
                            }
                    }
                }
                .padding(.trailing, 10)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .overlay {
                if let name = viewModel.projectName {
                    HStack {
                        if
                            case .sbun(_) = viewModel.selected,
                            sbunViewModel.process?.isRunning == true
                        {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(.gray)
                                .frame(width: 15, height: 15)
                                .onTapGesture {
                                    sbunViewModel.process?.terminate()
                                }
                        } else {
                            Triangle()
                                .fill(.gray.opacity(isRunningEnabled ? 1: 0.3))
                                .frame(width: 20, height: 20)
                                .onTapGesture {
                                    run()
                                }
                        }
                        Text(name)
                        Arrow()
                            .stroke(Color.gray, style: .init(width: 1.5))
                            .frame(width: 5, height: 10)
                        Picker(of: Array(viewModel.stringResponders), selection: viewModel.selectedStringBinding)
                        if case .sbun(_) = viewModel.selected {
                            Arrow()
                                .stroke(Color.gray, style: .init(width: 1.5))
                                .frame(width: 5, height: 10)
                            Picker(
                                of: Array(sbunViewModel.availableDestinations.keys),
                                selection: sbunViewModel.$selectedDestination
                            )
                            
                            if sbunViewModel.selectedDestination == "Local" {
                                Arrow()
                                    .stroke(Color.gray, style: .init(width: 1.5))
                                    .frame(width: 5, height: 10)
                                Picker(of: ["AppKitBackend", "GtkBackend"], selection: sbunViewModel.$localRunningBackend)
                            }
                        }
                    }
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .sheet(isPresented: $showBuildErrorSheet) {
                ScrollView {
                    Text(viewModel.buildOutput)
                }
            }
    }
    
    private func run() {
        guard isRunningEnabled else { return }
        Task {
            if case let .sbun(name) = viewModel.selected {
                do {
                    try await sbunViewModel.run(app: name)
                } catch {
                    print(error.localizedDescription)
                }
            } else if case .test = viewModel.selected {
                for test in testViewModel.tests.values {
                    do {
                        try await testViewModel.runTest(test)
                    } catch {
                        print(error.localizedDescription)
                    }
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
        }
    }
}
