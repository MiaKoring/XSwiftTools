import SwiftCrossUI
import DefaultBackend
import TestParser

@HotReloadable
@main
struct XSwiftToolsApp: App {
    @Environment(\.chooseFile) var fileOpenDialog
    @State var viewModel: TestVM = TestVM(path: nil)
    @AppStorage(PathKey.self) var lastPath
    
    var body: some Scene {
        WindowGroup("XSwiftTools") {
            #hotReloadable {
                ContentView()
                    .environment(viewModel)
                    .task { await startup() }
                    .sheet(
                        isPresented: Binding(
                            get: { viewModel.error != nil },
                            set: {_ in viewModel.error = nil }
                        )
                    ) {
                        if let (error, origin) = viewModel.error {
                            VStack {
                                Text("An error occured \(origin)")
                                ScrollView {
                                    Text(error.localizedDescription)
                                }
                            }
                            .padding()
                        }
                    }
            }
        }
        .commands {
            CommandMenu("File") {
                Button("Open") {
                    selectAndScan()
                }
            }
        }
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
            viewModel.error = (error, "while opening project")
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
    
    private func startup() async {
        if let lastPath {
            await getResult(for: lastPath)
        }
    }
}
