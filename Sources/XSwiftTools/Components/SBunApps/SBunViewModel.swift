import SwiftCrossUI
import XSwiftToolsSupport
import Foundation

@MainActor
@ObservableObject
final class SBunViewModel: @unchecked Sendable {
    var path: String?
    var output: String = ""
    @SwiftCrossUI.ObservationIgnored
    var stderrOutput: String = ""
    var availableDestinations = [String: String?]()
    var selectedDestination: String? = "Local"
    var localRunningBackend: String?
    var process: ChildProcess<UnspecifiedInputSource, PipeOutputDestination, PipeOutputDestination>?
    
    func run(app: String, topBarModel: TopBarViewModel) async throws {
        guard let path else { return }
        
        topBarModel.processes.removeAll(where: { $0 == .buildFailed })
        topBarModel.processes.append(.prepareBuilding)
        
        let selectedDestination = selectedDestination ?? "Local"
        var arguments = [String]()
        var environment = [String: String]()
        
        if
            selectedDestination == "Local",
            let localRunningBackend
        {
            environment["SCUI_DEFAULT_BACKEND"] = localRunningBackend
        } else if
            let value = availableDestinations[selectedDestination],
            let id = value
        {
            arguments.append("--simulator")
            arguments.append(id)
        }
        
        let parser = BundlerParser(path: path)
        
        output = ""
        let command = try await parser.runAppCommand(
            named: app,
            environment: environment,
            arguments: arguments
        )
        
        output = ""
        stderrOutput = ""
        process = try command.spawn()
        
        var startedBuilding = false
        let buildProgressCheckEnabled = selectedDestination == "Local"
        
        guard let process = self.process else { return }
        var isRunning = false
        for try await line in process.stdout.lines {
            if
                buildProgressCheckEnabled,
                !isRunning,
                topBarModel.extractAndSetBuildProgress(
                    line,
                    startedBuilding: &startedBuilding
                )
            { continue }
            
            if
                buildProgressCheckEnabled,
                !isRunning,
                line.hasPrefix("Building for ")
            {
                topBarModel.processes.removeAll(where: { $0 == .prepareBuilding })
                topBarModel.processes.append(.building(file: 0, total: 0))
            }
            
            if
                !isRunning,
                line.hasPrefix("Build of product '")
            {
                isRunning = true
                topBarModel.removeBuildingProcesses()
                topBarModel.processes.append(.running)
                continue
            }
            self.output.append("\n\(line)")
        }
        
        var errorLine = ""
        
        for try await line in process.stderr.lines {
            if line.hasPrefix("error: ") {
                errorLine = line
                continue
            }
            stderrOutput.append("\n\(line)")
        }
        
        topBarModel.processes.removeAll(where: { $0 == .running })
        
        process.terminate()
        
        if
            let status = try process.statusIfAvailable,
            !errorLine.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        {
            await MainActor.run {
                topBarModel.buildOutput = output + "\n" + stderrOutput + "\n" + errorLine
                topBarModel.removeBuildingProcesses()
                topBarModel.processes.append(isRunning ? .exitedWithError: .buildFailed)
            }
        }
    }
}
