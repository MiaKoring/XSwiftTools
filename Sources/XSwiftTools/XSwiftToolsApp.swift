import SwiftCrossUI
import DefaultBackend
import XSwiftToolsSupport
import SystemPackage
import Foundation

@HotReloadable
@main
struct XSwiftToolsApp: App {
    @Environment(\.chooseFile) var fileOpenDialog
    @State var viewModel = TestViewModel(path: nil)
    @State var topBarModel = TopBarViewModel()
    @State var sbunModel = SBunViewModel()
    @AppStorage(PathKey.self) var lastPath
    @State var showCleanAlert = false
    @AppStorage(\.sbunLocation) var sbunLocation
    @State var showSbunConfigSheet = false
    
    let directoryMonitor = DirectoryMonitor()
    @State var updateTask: Task<Void, any Error>?
    
    var body: some Scene {
        WindowGroup("XSwiftTools") {
            #hotReloadable {
                ContentView()
                    .environment(viewModel)
                    .environment(topBarModel)
                    .environment(sbunModel)
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
                    .alert("Are you shure you want to clean the build folder?", isPresented: $showCleanAlert) {
                        Button("Cancel") {
                            showCleanAlert = false
                        }
                        Button("Yes") {
                            cleanBuildFolder()
                        }
                    }
                    .sheet(isPresented: $showSbunConfigSheet) {
                        SBunConfigView()
                            .padding()
                            .frame(width: 200)
                    }
                    .onChange(of: sbunLocation, initial: true) {
                        sbunModel.sbunPath = sbunLocation ?? ""
                        Task {
                            if let lastPath {
                                await getResult(for: lastPath)
                                observeFileSystem()
                            }
                        }
                    }
            }
        }
        .commands {
            CommandMenu("File") {
                Button("Open") {
                    selectAndScan()
                }
                Button("Set SBun Path") {
                    showSbunConfigSheet = true
                }
            }
            
            CommandMenu("Project") {
                Button("Clean build folder") {
                    showCleanAlert = true
                }
            }
        }
        .defaultSize(width: 800, height: 600)
    }
    
    private func getResult(for path: String) async {
        defer {
            topBarModel.processes.removeAll(where: { $0 == .indexing})
        }
        
        guard
            let sbunLocation,
            !topBarModel.processes.contains(.indexing)
        else { return }
        sbunModel.clean()
        
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
        
        let sbunParser = BundlerParser(path: path, sbunPath: sbunLocation)
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
    
    private func cleanBuildFolder() {
        guard let path = lastPath else { return }
        _ = try? Command.findInPath(withName: "rm")!
            .addArgument("-rf")
            .addArgument(".build")
            .setCWD(FilePath(path))
            .waitForOutput()
    }
    
    func observeFileSystem() {
        if let lastPath {
            directoryMonitor.stop()
            directoryMonitor.startMonitoring(path: lastPath + "/Tests") {
                Task {
                    await getResult(for: lastPath)
                }
            }
        }
    }
}

extension AppStorageValues {
    @Entry var sbunLocation: String?
}

struct SBunConfigView: View {
    @AppStorage(\.sbunLocation) var sbunLocation
    @State var sbunPath = ""
    
    var body: some View {
        TextField(text: $sbunPath)
            .onAppear {
                sbunPath = sbunLocation ?? ""
            }
        Button("Save") {
            sbunLocation = sbunPath
        }
    }
}
