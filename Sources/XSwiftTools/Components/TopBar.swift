import SwiftCrossUI
import Foundation

struct TopBar: View {
    @Environment(TopBarViewModel.self) var viewModel
    @Environment(TestViewModel.self) var testViewModel
    @State var textWidth = 0.0
    @State var showBuildErrorSheet = false
    
    var body: some View {
        Capsule()
            .stroke(.gray)
            .frame(height: 30)
            .overlay {
                ZStack(alignment: .trailing) {
                    VStack {}
                        .frame(maxWidth: .infinity)
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
                }
            }
            .overlay {
                ZStack(alignment: .leading) {
                    VStack {}
                        .frame(maxWidth: .infinity)
                    if let name = viewModel.projectName {
                        HStack {
                            Text(name)
                            Arrow()
                                .stroke(Color.gray, style: .init(width: 1.5))
                                .frame(width: 5, height: 10)
                            Picker(of: Array(viewModel.availableResponsers), selection: viewModel.$selected)
                        }
                        .padding(.leading, 10)
                    }
                }
            }
            .sheet(isPresented: $showBuildErrorSheet) {
                ScrollView {
                    Text(viewModel.buildOutput)
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

enum Responder {
    case test
    case sbun
}
