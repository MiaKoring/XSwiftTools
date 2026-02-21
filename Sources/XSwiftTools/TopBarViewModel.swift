import SwiftCrossUI
import XSwiftToolsSupport

@MainActor
@ObservableObject
final class TopBarViewModel {
    var path: String?
    var processes = [TopBarProcess]()
    var projectName: String?
    var selected: Responder?
    var availableResponsers = Set<Responder>()
    
    @ObservationIgnored
    var buildOutput = ""
    
    var sortedProcesses: [TopBarProcess] {
        processes.sorted(by: {
            $0.hashValue < $1.hashValue
        })
    }
    
    var stringResponders: [String] {
        get {
            availableResponsers.map {
                $0.string
            }
            .sorted(by: { $0 < $1 })
        }
    }
    
    var selectedStringBinding: Binding<String?> {
        Binding(
            get: { self.selected?.string },
            set: { newValue in
                guard let newValue else {
                    self.selected = nil
                    return
                }
                self.selected = Responder(string: newValue)
            }
        )
    }
    
    func build(for test: TestRunnable) async throws {
        defer { removeBuildingProcesses() }
        
        buildOutput = ""
        guard let path else {
            print("Path must be set")
            return
        }
        let runner = XSwiftToolsSupport.TestRunner(path: path)
        var startedBuilding = false
        processes.append(.prepareBuilding)
        
        try await runner.build(test.testProductName) { line in
            self.buildOutput.append("\n\(line)")
            self.extractAndSetBuildProgress(line, startedBuilding: &startedBuilding)
        }
    }
    
    func removeBuildingProcesses() {
        self.processes.removeAll(where: {
            switch $0 {
                case .building: return true
                default: return false
            }
        })
    }
    
    @discardableResult
    func extractAndSetBuildProgress(
        _ line: String,
        startedBuilding: inout Bool
    ) -> Bool {
        guard
            line.starts(with: "["),
            let closingIndex = line.firstIndex(of: "]"),
            let dividingIndex = line.firstIndex(of: "/"),
            dividingIndex < closingIndex
        else { return false }
        
        if !startedBuilding {
            startedBuilding = true
            self.processes.removeAll(where: { $0 == .prepareBuilding })
        }
        
        let substring = line.prefix(upTo: closingIndex).dropFirst()
        let parts = substring.split(separator: "/").map { Int($0)! }
        
        guard parts.count == 2 else { return false }
        
        self.removeBuildingProcesses()
        self.processes.append(.building(file: parts[0], total: parts[1]))
        
        return true
    }
}



enum TopBarProcess: Hashable {
    case testing
    case running
    case prepareBuilding
    case buildFailed
    case exitedWithError
    case building(file: Int, total: Int)
    case indexing
}

enum Responder: Hashable {
    case test
    case sbun(String)
}
extension Responder {
    var string: String {
        switch self {
            case .sbun(let name):
                return name
            case .test:
                return "Package Tests"
        }
    }
    
    init(string: String) {
        switch string {
            case "Package Tests": self = .test
            default: self = .sbun(string)
        }
    }
}
