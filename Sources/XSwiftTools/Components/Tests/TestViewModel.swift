import Foundation
import SwiftCrossUI
import XSwiftToolsSupport

#if canImport(FoundationXML)
import FoundationXML
#endif

@ObservableObject
@MainActor
final class TestViewModel: NSObject, @MainActor XMLParserDelegate {
    var tests = [Target: TargetTests]()
    var suiteState = [String: TestState]()
    var testState = [String: TestState]()
    var targetState: TestState?
    var runOutput: String = ""
    var path: String?
    var error: (any Error, String)?
    
    private var outputPath: String {
        let xSwiftToolsDirectory = path! + "/.build/XSwiftTools"
        
        try? FileManager.default.createDirectory(atPath: xSwiftToolsDirectory, withIntermediateDirectories: true)
        
        let outputFile = xSwiftToolsDirectory + "/output-swift-testing.xml"
        
        FileManager.default.createFile(atPath: outputFile, contents: nil)
        return outputFile
    }
    
    private var outputPathParameter: String {
        outputPath.replacingOccurrences(of: "-swift-testing", with: "")
    }
    
    private(set) var isRunningTests = false
    
    init(path: String?) {
        self.path = path
    }
    
    /// Runs all test inside the passed scope
    /// If passed a target, suites get run individually
    func runTest(
        _ test: TestRunnable
    ) async throws {
        guard let path else {
            print("Path must be set")
            return
        }
        isRunningTests = true
        
        defer {
            isRunningTests = false
        }
        
        switch test {
            case let test as Test:
                mark(test, with: .waiting)
                let runner = XSwiftToolsSupport.TestRunner(path: path)
                
                let outputPath = outputPathParameter.replacingOccurrences(of: ".xml", with: "\(test.filter)-swift-testing.xml")
                try? FileManager.default.removeItem(atPath: outputPath)
                
                try await runner.run(test, outputPath: outputPathParameter.replacingOccurrences(of: ".xml", with: "\(test.filter).xml")) { line in
                    self.runOutput.append("\n\(line)")
                }
                await waitAndUpdate(path: outputPath)
            case let suite as TestSuite:
                mark(suite, with: .waiting)
                let runner = XSwiftToolsSupport.TestRunner(path: path)
                
                let outputPath = outputPathParameter.replacingOccurrences(of: ".xml", with: "\(test.filter)-swift-testing.xml")
                try? FileManager.default.removeItem(atPath: outputPath)
                
                try await runner.run(suite, outputPath: outputPathParameter.replacingOccurrences(of: ".xml", with: "\(test.filter).xml")) { line in
                    self.runOutput.append("\n\(line)")
                }
                await waitAndUpdate(path: outputPath)
            case let target as TargetTests:
                for suite in target.suites {
                    try await runTest(suite)
                }
                
                for test in target.freestanding {
                    try await runTest(test)
                }
                return
            default: return
        }
        if test is TestSuite {
            suiteState[test.filter] = suiteDidContainErrors ? .failed: .passed
            suiteDidContainErrors = false
        }
        self.runOutput += "\n"
    }
    
    private func updateUIFromOutput(path: String) {
        let data = try! Data(contentsOf: URL(string: "file://\(path)")!)
        let parser = XMLParser(data: data)
        parser.delegate = self
        parser.parse()
    }
    
    /// Marks all descendant of `TestRunnable` as waiting
    private func mark(_ test: TestRunnable, with state: TestState?) {
        switch test {
            case let test as Test:
                testState[test.filter] = state
            case let suite as TestSuite:
                suiteState[suite.filter] = state
                
                for test in suite.tests {
                    mark(test, with: state)
                }
            case _ as TargetTests:
                targetState = .waiting
            default: return
        }
    }
    
    
    // MARK: - Output Parsing
    private var currentElement = ""
    private var currentTestCaseAttributes: [String: String] = [:]
    private var failureMessage = ""
    private var suiteDidContainErrors = false
    
    func parser(
        _ parser: XMLParser,
        didStartElement elementName: String,
        namespaceURI: String?,
        qualifiedName qName: String?,
        attributes attributeDict: [String : String] = [:]
    ) {
        currentElement = elementName
        
        if elementName == "testcase" {
            currentTestCaseAttributes = attributeDict
            failureMessage = ""  // Reset for each test case
        } else if elementName == "failure" || elementName == "error" {
            failureMessage = attributeDict["message"] ?? ""  // Message is in the attribute, not character data
        }
    }
    
    func parser(_ parser: XMLParser, didEndElement elementName: String,
                namespaceURI: String?, qualifiedName qName: String?) {
        if elementName == "testcase" {
            let name = currentTestCaseAttributes["name"] ?? "Unknown"
            let className = currentTestCaseAttributes["classname"] ?? "Unknown"
            
            let status: TestState = failureMessage.isEmpty ? .passed : .failed
            suiteDidContainErrors = status == .failed || suiteDidContainErrors
            
            testState["\(className)/\(name)"] = status
        }
    }
    
    func waitAndUpdate(path: String) async {
        while !FileManager.default.fileExists(atPath: path) {
            try? await Task.sleep(for: .milliseconds(100))
        }
        
        var tries = 0

        while tries < 10 {
            try? await Task.sleep(for: .milliseconds(50 + 25 * tries))
            
            if
                let data = FileManager.default.contents(atPath: path),
                String(data: data, encoding: .utf8)?.hasSuffix("</testsuites>") == true
            {
                break
            }
            tries += 1
        }
        
        updateUIFromOutput(
            path: path
        )
    }
}

