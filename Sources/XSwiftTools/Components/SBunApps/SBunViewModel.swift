import SwiftCrossUI
import TestParser

@ObservableObject
final class SBunViewModel: @unchecked Sendable {
    var path: String?
    var output: String = ""
    var availableDestinations = [String: String?]()
    var selectedDestination: String? = "Local"
    var localRunningBackend: String?
    var process: ChildProcess<UnspecifiedInputSource, PipeOutputDestination, UnspecifiedOutputDestination>?
    
    func run(app: String) async throws {
        guard let path else { return }
        print("started")
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
        let process = try command.spawn()
        self.process = process
        
        for try await line in process.stdout.lines {
            output.append("\n\(line)")
        }
    }
}
