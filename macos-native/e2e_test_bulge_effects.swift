#!/usr/bin/env swift
//
//  e2e_test_bulge_effects.swift
//  End-to-end test for 42 bulge effects
//
//  Tests loading, validation, and performance of custom bulge filters
//

import Foundation

// MARK: - Models

struct BulgePoint: Codable {
    var x: Float
    var y: Float
    var radius: Float
    var strength: Float
}

struct CustomBulgeFilter: Codable {
    var id: String
    var name: String
    var points: [BulgePoint]
    var createdDate: String
    var modifiedDate: String
}

struct CustomBulgeFilterExport: Codable {
    var version: String
    var appName: String
    var exportDate: String
    var filters: [CustomBulgeFilter]
}

// MARK: - Test Results

enum TestStatus {
    case passed
    case failed
    case warning
    
    var emoji: String {
        switch self {
        case .passed: return "✅"
        case .failed: return "❌"
        case .warning: return "⚠️"
        }
    }
}

struct TestResult {
    let name: String
    let status: TestStatus
    let message: String
    let duration: TimeInterval?
    
    init(name: String, status: TestStatus, message: String, duration: TimeInterval? = nil) {
        self.name = name
        self.status = status
        self.message = message
        self.duration = duration
    }
}

struct FilterTestResult {
    let filterName: String
    let pointCount: Int
    let validationPassed: Bool
    let issues: [String]
    let avgRadius: Float
    let avgStrength: Float
    let complexity: String
}

// MARK: - E2E Test Runner

class BulgeEffectsE2ETester {
    var results: [TestResult] = []
    var filterResults: [FilterTestResult] = []
    var totalTests = 0
    var passedTests = 0
    var failedTests = 0
    var warnings = 0
    
    func runAllTests(filePath: String) {
        print("🚀 Starting E2E Tests for Bulge Effects")
        print("═══════════════════════════════════════\n")
        
        // Test 1: File exists
        testFileExists(filePath)
        
        // Test 2: Load and parse JSON
        guard let export = testLoadJSON(filePath) else {
            printSummary()
            return
        }
        
        // Test 3: Validate export structure
        testExportStructure(export)
        
        // Test 4: Count filters
        testFilterCount(export, expected: 42)
        
        // Test 5: Validate each filter
        testAllFilters(export.filters)
        
        // Test 6: Test unique names
        testUniqueNames(export.filters)
        
        // Test 7: Test variety
        testVariety(export.filters)
        
        // Test 8: Test performance characteristics
        testPerformanceCharacteristics(export.filters)
        
        // Test 9: Test edge cases
        testEdgeCases(export.filters)
        
        // Print results
        printDetailedResults()
        printSummary()
        
        // Generate HTML report
        generateHTMLReport(export)
    }
    
    func testFileExists(_ path: String) {
        let start = Date()
        let exists = FileManager.default.fileExists(atPath: path)
        let duration = Date().timeIntervalSince(start)
        
        if exists {
            addResult(TestResult(
                name: "File Exists",
                status: .passed,
                message: "Filter file found at \(path)",
                duration: duration
            ))
        } else {
            addResult(TestResult(
                name: "File Exists",
                status: .failed,
                message: "Filter file not found at \(path)",
                duration: duration
            ))
        }
    }
    
    func testLoadJSON(_ path: String) -> CustomBulgeFilterExport? {
        let start = Date()
        
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            let duration = Date().timeIntervalSince(start)
            addResult(TestResult(
                name: "Load JSON",
                status: .failed,
                message: "Failed to read file data",
                duration: duration
            ))
            return nil
        }
        
        let decoder = JSONDecoder()
        guard let export = try? decoder.decode(CustomBulgeFilterExport.self, from: data) else {
            let duration = Date().timeIntervalSince(start)
            addResult(TestResult(
                name: "Load JSON",
                status: .failed,
                message: "Failed to parse JSON",
                duration: duration
            ))
            return nil
        }
        
        let duration = Date().timeIntervalSince(start)
        addResult(TestResult(
            name: "Load JSON",
            status: .passed,
            message: "Successfully parsed \(data.count) bytes",
            duration: duration
        ))
        
        return export
    }
    
    func testExportStructure(_ export: CustomBulgeFilterExport) {
        let start = Date()
        var issues: [String] = []
        
        if export.version != "1.0" {
            issues.append("Version mismatch: \(export.version)")
        }
        
        if export.appName != "WesWorld FX" {
            issues.append("App name mismatch: \(export.appName)")
        }
        
        if export.filters.isEmpty {
            issues.append("No filters found")
        }
        
        let duration = Date().timeIntervalSince(start)
        
        if issues.isEmpty {
            addResult(TestResult(
                name: "Export Structure",
                status: .passed,
                message: "Valid export structure",
                duration: duration
            ))
        } else {
            addResult(TestResult(
                name: "Export Structure",
                status: .failed,
                message: issues.joined(separator: ", "),
                duration: duration
            ))
        }
    }
    
    func testFilterCount(_ export: CustomBulgeFilterExport, expected: Int) {
        let start = Date()
        let count = export.filters.count
        let duration = Date().timeIntervalSince(start)
        
        if count == expected {
            addResult(TestResult(
                name: "Filter Count",
                status: .passed,
                message: "Found \(count) filters as expected",
                duration: duration
            ))
        } else {
            addResult(TestResult(
                name: "Filter Count",
                status: .failed,
                message: "Expected \(expected) filters, found \(count)",
                duration: duration
            ))
        }
    }
    
    func testAllFilters(_ filters: [CustomBulgeFilter]) {
        let start = Date()
        var validCount = 0
        
        for filter in filters {
            let result = validateFilter(filter)
            filterResults.append(result)
            if result.validationPassed {
                validCount += 1
            }
        }
        
        let duration = Date().timeIntervalSince(start)
        
        if validCount == filters.count {
            addResult(TestResult(
                name: "Filter Validation",
                status: .passed,
                message: "All \(filters.count) filters passed validation",
                duration: duration
            ))
        } else {
            addResult(TestResult(
                name: "Filter Validation",
                status: .failed,
                message: "\(filters.count - validCount) filters failed validation",
                duration: duration
            ))
        }
    }
    
    func validateFilter(_ filter: CustomBulgeFilter) -> FilterTestResult {
        var issues: [String] = []
        
        // Check name
        if filter.name.isEmpty {
            issues.append("Empty name")
        }
        
        // Check points
        if filter.points.isEmpty {
            issues.append("No points defined")
        }
        
        if filter.points.count > 20 {
            issues.append("Too many points (\(filter.points.count))")
        }
        
        // Validate each point
        for (i, point) in filter.points.enumerated() {
            if point.x < 0 || point.x > 1 {
                issues.append("Point \(i) x out of range: \(point.x)")
            }
            if point.y < 0 || point.y > 1 {
                issues.append("Point \(i) y out of range: \(point.y)")
            }
            if point.radius < 0.05 || point.radius > 0.5 {
                issues.append("Point \(i) radius out of range: \(point.radius)")
            }
            if point.strength < -1.0 || point.strength > 1.0 {
                issues.append("Point \(i) strength out of range: \(point.strength)")
            }
        }
        
        // Calculate statistics
        let avgRadius = filter.points.reduce(0.0) { $0 + $1.radius } / Float(filter.points.count)
        let avgStrength = filter.points.reduce(0.0) { $0 + abs($1.strength) } / Float(filter.points.count)
        
        // Determine complexity
        let complexity: String
        if filter.points.count <= 2 {
            complexity = "Simple"
        } else if filter.points.count <= 5 {
            complexity = "Medium"
        } else if filter.points.count <= 10 {
            complexity = "Complex"
        } else {
            complexity = "Very Complex"
        }
        
        return FilterTestResult(
            filterName: filter.name,
            pointCount: filter.points.count,
            validationPassed: issues.isEmpty,
            issues: issues,
            avgRadius: avgRadius,
            avgStrength: avgStrength,
            complexity: complexity
        )
    }
    
    func testUniqueNames(_ filters: [CustomBulgeFilter]) {
        let start = Date()
        let names = filters.map { $0.name }
        let uniqueNames = Set(names)
        let duration = Date().timeIntervalSince(start)
        
        if names.count == uniqueNames.count {
            addResult(TestResult(
                name: "Unique Names",
                status: .passed,
                message: "All filter names are unique",
                duration: duration
            ))
        } else {
            let duplicates = names.count - uniqueNames.count
            addResult(TestResult(
                name: "Unique Names",
                status: .failed,
                message: "\(duplicates) duplicate name(s) found",
                duration: duration
            ))
        }
    }
    
    func testVariety(_ filters: [CustomBulgeFilter]) {
        let start = Date()
        
        // Count different types
        let singlePoint = filters.filter { $0.points.count == 1 }.count
        let twoPoints = filters.filter { $0.points.count == 2 }.count
        let multiPoint = filters.filter { $0.points.count > 2 }.count
        
        let hasBulge = filters.filter { filter in
            filter.points.contains { $0.strength > 0 }
        }.count
        
        let hasPinch = filters.filter { filter in
            filter.points.contains { $0.strength < 0 }
        }.count
        
        let duration = Date().timeIntervalSince(start)
        
        let message = """
        Variety analysis:
          - Single point: \(singlePoint)
          - Two points: \(twoPoints)
          - Multi-point: \(multiPoint)
          - With bulge: \(hasBulge)
          - With pinch: \(hasPinch)
        """
        
        if singlePoint > 0 && twoPoints > 0 && multiPoint > 0 {
            addResult(TestResult(
                name: "Filter Variety",
                status: .passed,
                message: message,
                duration: duration
            ))
        } else {
            addResult(TestResult(
                name: "Filter Variety",
                status: .warning,
                message: "Limited variety\n\(message)",
                duration: duration
            ))
        }
    }
    
    func testPerformanceCharacteristics(_ filters: [CustomBulgeFilter]) {
        let start = Date()
        
        let totalPoints = filters.reduce(0) { $0 + $1.points.count }
        let avgPoints = Float(totalPoints) / Float(filters.count)
        let maxPoints = filters.map { $0.points.count }.max() ?? 0
        let minPoints = filters.map { $0.points.count }.min() ?? 0
        
        let duration = Date().timeIntervalSince(start)
        
        let message = """
        Performance stats:
          - Total points: \(totalPoints)
          - Avg points per filter: \(String(format: "%.1f", avgPoints))
          - Range: \(minPoints)-\(maxPoints) points
        """
        
        if avgPoints < 15.0 {
            addResult(TestResult(
                name: "Performance Characteristics",
                status: .passed,
                message: message,
                duration: duration
            ))
        } else {
            addResult(TestResult(
                name: "Performance Characteristics",
                status: .warning,
                message: "High average point count may affect performance\n\(message)",
                duration: duration
            ))
        }
    }
    
    func testEdgeCases(_ filters: [CustomBulgeFilter]) {
        let start = Date()
        var issues: [String] = []
        
        // Test for extreme values
        for filter in filters {
            for point in filter.points {
                if point.radius < 0.07 {
                    issues.append("\(filter.name): Very small radius (\(point.radius))")
                }
                if point.radius > 0.45 {
                    issues.append("\(filter.name): Very large radius (\(point.radius))")
                }
                if abs(point.strength) > 0.95 {
                    issues.append("\(filter.name): Extreme strength (\(point.strength))")
                }
            }
        }
        
        let duration = Date().timeIntervalSince(start)
        
        if issues.isEmpty {
            addResult(TestResult(
                name: "Edge Cases",
                status: .passed,
                message: "No extreme values detected",
                duration: duration
            ))
        } else {
            addResult(TestResult(
                name: "Edge Cases",
                status: .warning,
                message: "\(issues.count) edge cases found",
                duration: duration
            ))
        }
    }
    
    func addResult(_ result: TestResult) {
        results.append(result)
        totalTests += 1
        
        switch result.status {
        case .passed:
            passedTests += 1
        case .failed:
            failedTests += 1
        case .warning:
            warnings += 1
        }
    }
    
    func printDetailedResults() {
        print("\n📋 Filter Details")
        print("═══════════════════════════════════════\n")
        
        for (i, result) in filterResults.enumerated() {
            let status = result.validationPassed ? "✅" : "❌"
            print("\(i + 1). \(status) \(result.filterName)")
            print("   Points: \(result.pointCount) | Complexity: \(result.complexity)")
            print("   Avg Radius: \(String(format: "%.2f", result.avgRadius)) | Avg Strength: \(String(format: "%.2f", result.avgStrength))")
            
            if !result.issues.isEmpty {
                print("   Issues: \(result.issues.joined(separator: ", "))")
            }
            print("")
        }
    }
    
    func printSummary() {
        print("\n" + "═".repeated(50))
        print("📊 Test Summary")
        print("═".repeated(50) + "\n")
        
        for result in results {
            let durationStr = result.duration.map { String(format: " (%.3fs)", $0) } ?? ""
            print("\(result.status.emoji) \(result.name)\(durationStr)")
            print("   \(result.message)")
            print("")
        }
        
        print("═".repeated(50))
        print("Total Tests: \(totalTests)")
        print("✅ Passed: \(passedTests)")
        print("❌ Failed: \(failedTests)")
        print("⚠️  Warnings: \(warnings)")
        print("Success Rate: \(String(format: "%.1f", Float(passedTests) / Float(totalTests) * 100))%")
        print("═".repeated(50) + "\n")
        
        if failedTests == 0 {
            print("🎉 All tests passed!")
        } else {
            print("❌ Some tests failed. Please review the results above.")
        }
    }
    
    func generateHTMLReport(_ export: CustomBulgeFilterExport) {
        let html = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
            <meta charset="UTF-8">
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <title>Bulge Effects E2E Test Report</title>
            <style>
                * { margin: 0; padding: 0; box-sizing: border-box; }
                body {
                    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    padding: 40px 20px;
                    color: #333;
                }
                .container {
                    max-width: 1200px;
                    margin: 0 auto;
                    background: white;
                    border-radius: 20px;
                    box-shadow: 0 20px 60px rgba(0,0,0,0.3);
                    overflow: hidden;
                }
                .header {
                    background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
                    color: white;
                    padding: 40px;
                    text-align: center;
                }
                .header h1 {
                    font-size: 2.5em;
                    margin-bottom: 10px;
                }
                .header p {
                    font-size: 1.2em;
                    opacity: 0.9;
                }
                .stats {
                    display: grid;
                    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
                    gap: 20px;
                    padding: 40px;
                    background: #f8f9fa;
                }
                .stat-card {
                    background: white;
                    padding: 20px;
                    border-radius: 10px;
                    text-align: center;
                    box-shadow: 0 2px 10px rgba(0,0,0,0.1);
                }
                .stat-card h3 {
                    font-size: 2em;
                    margin-bottom: 5px;
                }
                .stat-card p {
                    color: #666;
                    font-size: 0.9em;
                }
                .passed { color: #10b981; }
                .failed { color: #ef4444; }
                .warning { color: #f59e0b; }
                .content {
                    padding: 40px;
                }
                .test-section {
                    margin-bottom: 40px;
                }
                .test-section h2 {
                    font-size: 1.8em;
                    margin-bottom: 20px;
                    color: #667eea;
                }
                .test-item {
                    background: #f8f9fa;
                    padding: 20px;
                    border-radius: 10px;
                    margin-bottom: 15px;
                    border-left: 4px solid #667eea;
                }
                .test-item.passed { border-left-color: #10b981; }
                .test-item.failed { border-left-color: #ef4444; }
                .test-item.warning { border-left-color: #f59e0b; }
                .test-item h3 {
                    font-size: 1.2em;
                    margin-bottom: 10px;
                }
                .filter-grid {
                    display: grid;
                    grid-template-columns: repeat(auto-fill, minmax(300px, 1fr));
                    gap: 20px;
                    margin-top: 20px;
                }
                .filter-card {
                    background: #f8f9fa;
                    padding: 20px;
                    border-radius: 10px;
                    border: 2px solid #e5e7eb;
                }
                .filter-card h4 {
                    color: #667eea;
                    margin-bottom: 10px;
                }
                .filter-stats {
                    display: grid;
                    grid-template-columns: 1fr 1fr;
                    gap: 10px;
                    font-size: 0.9em;
                    margin-top: 10px;
                }
                .filter-stat {
                    background: white;
                    padding: 8px;
                    border-radius: 5px;
                }
                .complexity-simple { background: #d1fae5; color: #059669; }
                .complexity-medium { background: #fef3c7; color: #d97706; }
                .complexity-complex { background: #fecaca; color: #dc2626; }
                .complexity-very-complex { background: #ddd6fe; color: #7c3aed; }
            </style>
        </head>
        <body>
            <div class="container">
                <div class="header">
                    <h1>🎨 Bulge Effects E2E Test Report</h1>
                    <p>Generated: \(Date())</p>
                </div>
                
                <div class="stats">
                    <div class="stat-card">
                        <h3>\(export.filters.count)</h3>
                        <p>Total Filters</p>
                    </div>
                    <div class="stat-card">
                        <h3 class="passed">\(passedTests)</h3>
                        <p>Tests Passed</p>
                    </div>
                    <div class="stat-card">
                        <h3 class="failed">\(failedTests)</h3>
                        <p>Tests Failed</p>
                    </div>
                    <div class="stat-card">
                        <h3 class="warning">\(warnings)</h3>
                        <p>Warnings</p>
                    </div>
                </div>
                
                <div class="content">
                    <div class="test-section">
                        <h2>Test Results</h2>
                        \(results.map { result in
                            let statusClass = result.status == .passed ? "passed" : (result.status == .failed ? "failed" : "warning")
                            return """
                            <div class="test-item \(statusClass)">
                                <h3>\(result.status.emoji) \(result.name)</h3>
                                <p>\(result.message.replacingOccurrences(of: "\n", with: "<br>"))</p>
                            </div>
                            """
                        }.joined())
                    </div>
                    
                    <div class="test-section">
                        <h2>All Filters (\(export.filters.count))</h2>
                        <div class="filter-grid">
                            \(filterResults.map { result in
                                let complexityClass = "complexity-\(result.complexity.lowercased().replacingOccurrences(of: " ", with: "-"))"
                                return """
                                <div class="filter-card">
                                    <h4>\(result.validationPassed ? "✅" : "❌") \(result.filterName)</h4>
                                    <div class="filter-stats">
                                        <div class="filter-stat"><strong>Points:</strong> \(result.pointCount)</div>
                                        <div class="filter-stat \(complexityClass)"><strong>Complexity:</strong> \(result.complexity)</div>
                                        <div class="filter-stat"><strong>Avg Radius:</strong> \(String(format: "%.2f", result.avgRadius))</div>
                                        <div class="filter-stat"><strong>Avg Strength:</strong> \(String(format: "%.2f", result.avgStrength))</div>
                                    </div>
                                    \(result.issues.isEmpty ? "" : "<p style='color: #dc2626; margin-top: 10px; font-size: 0.9em;'>Issues: \(result.issues.joined(separator: ", "))</p>")
                                </div>
                                """
                            }.joined())
                        </div>
                    </div>
                </div>
            </div>
        </body>
        </html>
        """
        
        do {
            let reportPath = "bulge_effects_e2e_report.html"
            try html.write(toFile: reportPath, atomically: true, encoding: .utf8)
            print("📄 HTML report generated: \(reportPath)")
        } catch {
            print("❌ Failed to generate HTML report: \(error)")
        }
    }
}

// MARK: - String Extension

extension String {
    func repeated(_ count: Int) -> String {
        return String(repeating: self, count: count)
    }
}

// MARK: - Main

let tester = BulgeEffectsE2ETester()
let filePath = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "42_bulge_effects.wwfxbulge"
tester.runAllTests(filePath: filePath)
