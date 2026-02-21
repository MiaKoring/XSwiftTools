import SwiftCrossUI
import DefaultBackend
import XSwiftToolsSupport

@HotReloadable
@main
struct XSwiftToolsApp: App {
    @Environment(\.chooseFile) var fileOpenDialog
    @State var viewModel = TestViewModel(path: nil)
    @State var topBarModel = TopBarViewModel()
    @State var sbunModel = SBunViewModel()
    @AppStorage(PathKey.self) var lastPath
    
    var body: some Scene {
        WindowGroup("XSwiftTools") {
            #hotReloadable {
                ContentView()
                    .environment(viewModel)
                    .environment(topBarModel)
                    .environment(sbunModel)
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
        .defaultSize(width: 800, height: 600)
    }
    
    private func getResult(for path: String) async {
        defer {
            topBarModel.processes.removeAll(where: { $0 == .indexing})
        }
        
        topBarModel.processes.append(.indexing)
        let parser = TestParser(path: path)
        
        var testFindingSucceeded = false
        
        do {
            let (targets, name) = try await parser.testTargets()
            lastPath = path
            viewModel.path = path
            topBarModel.path = path
            topBarModel.projectName = name
            sbunModel.path = path
            
            if !targets.isEmpty {
                topBarModel.availableResponsers = []
                testFindingSucceeded = true
                topBarModel.selected = .test
            }
            
            for target in targets {
                viewModel.tests[target] = parser.tests(in: target)
            }
        } catch {
            viewModel.error = (error, "while looking for tests.")
        }
        
        if testFindingSucceeded {
            topBarModel.availableResponsers = [.test]
        } else {
            topBarModel.availableResponsers = []
        }
        
        let sbunParser = BundlerParser(path: path)
        do {
            let apps = try sbunParser.parse()
            apps.forEach { app in
                topBarModel.availableResponsers.insert(.sbun(app))
            }
        } catch {
            viewModel.error = (error, "while looking for Swift Bundler apps.")
        }
        
        do {
            let simulators = try await sbunParser.simulators()
            sbunModel.availableDestinations = ["Local": nil]
            sbunModel.availableDestinations.merge(simulators, uniquingKeysWith: { _, new in new })
        } catch {
            viewModel.error = (error, "while looking for simulators.")
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
