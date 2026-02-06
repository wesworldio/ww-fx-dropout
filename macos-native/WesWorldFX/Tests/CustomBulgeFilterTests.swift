//
//  CustomBulgeFilterTests.swift
//  WesWorld FX Tests
//
//  Comprehensive tests for custom bulge filter functionality
//

import XCTest
@testable import WesWorldFX

class CustomBulgeFilterTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Clear any existing test data
        UserDefaults.standard.removeObject(forKey: "com.wesworld.fx.customBulgeFilters")
    }
    
    override func tearDown() {
        super.tearDown()
        // Clean up test data
        UserDefaults.standard.removeObject(forKey: "com.wesworld.fx.customBulgeFilters")
    }
    
    // MARK: - BulgePoint Tests
    
    func testBulgePointInitialization() {
        let point = BulgePoint(x: 0.5, y: 0.5, radius: 0.15, strength: 0.65)
        
        XCTAssertEqual(point.x, 0.5)
        XCTAssertEqual(point.y, 0.5)
        XCTAssertEqual(point.radius, 0.15)
        XCTAssertEqual(point.strength, 0.65)
    }
    
    func testBulgePointDefaultValues() {
        let point = BulgePoint(x: 0.3, y: 0.7)
        
        XCTAssertEqual(point.x, 0.3)
        XCTAssertEqual(point.y, 0.7)
        XCTAssertEqual(point.radius, 0.15)
        XCTAssertEqual(point.strength, 0.65)
    }
    
    func testBulgePointCodable() throws {
        let point = BulgePoint(x: 0.5, y: 0.5, radius: 0.2, strength: -0.5)
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(point)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(BulgePoint.self, from: data)
        
        XCTAssertEqual(point, decoded)
    }
    
    func testBulgePointEquality() {
        let point1 = BulgePoint(x: 0.5, y: 0.5, radius: 0.15, strength: 0.65)
        let point2 = BulgePoint(x: 0.5, y: 0.5, radius: 0.15, strength: 0.65)
        let point3 = BulgePoint(x: 0.4, y: 0.5, radius: 0.15, strength: 0.65)
        
        XCTAssertEqual(point1, point2)
        XCTAssertNotEqual(point1, point3)
    }
    
    // MARK: - CustomBulgeFilter Tests
    
    func testCustomBulgeFilterInitialization() {
        let filter = CustomBulgeFilter(name: "Test Filter")
        
        XCTAssertEqual(filter.name, "Test Filter")
        XCTAssertTrue(filter.points.isEmpty)
        XCTAssertNotNil(filter.id)
        XCTAssertNotNil(filter.createdDate)
        XCTAssertNotNil(filter.modifiedDate)
    }
    
    func testCustomBulgeFilterAddPoint() {
        var filter = CustomBulgeFilter(name: "Test Filter")
        let point = BulgePoint(x: 0.5, y: 0.5)
        
        filter.addPoint(point)
        
        XCTAssertEqual(filter.points.count, 1)
        XCTAssertEqual(filter.points[0], point)
    }
    
    func testCustomBulgeFilterAddMultiplePoints() {
        var filter = CustomBulgeFilter(name: "Test Filter")
        
        filter.addPoint(BulgePoint(x: 0.3, y: 0.3))
        filter.addPoint(BulgePoint(x: 0.5, y: 0.5))
        filter.addPoint(BulgePoint(x: 0.7, y: 0.7))
        
        XCTAssertEqual(filter.points.count, 3)
    }
    
    func testCustomBulgeFilterRemovePoint() {
        var filter = CustomBulgeFilter(name: "Test Filter")
        filter.addPoint(BulgePoint(x: 0.3, y: 0.3))
        filter.addPoint(BulgePoint(x: 0.5, y: 0.5))
        filter.addPoint(BulgePoint(x: 0.7, y: 0.7))
        
        filter.removePoint(at: 1)
        
        XCTAssertEqual(filter.points.count, 2)
        XCTAssertEqual(filter.points[0].x, 0.3)
        XCTAssertEqual(filter.points[1].x, 0.7)
    }
    
    func testCustomBulgeFilterUpdatePoint() {
        var filter = CustomBulgeFilter(name: "Test Filter")
        filter.addPoint(BulgePoint(x: 0.5, y: 0.5, strength: 0.65))
        
        let updatedPoint = BulgePoint(x: 0.6, y: 0.6, strength: 0.8)
        filter.updatePoint(at: 0, with: updatedPoint)
        
        XCTAssertEqual(filter.points[0].x, 0.6)
        XCTAssertEqual(filter.points[0].y, 0.6)
        XCTAssertEqual(filter.points[0].strength, 0.8)
    }
    
    func testCustomBulgeFilterModificationDate() {
        var filter = CustomBulgeFilter(name: "Test Filter")
        let originalModifiedDate = filter.modifiedDate
        
        // Add a slight delay to ensure timestamp difference
        usleep(10000) // 10ms
        
        filter.addPoint(BulgePoint(x: 0.5, y: 0.5))
        
        XCTAssertGreaterThan(filter.modifiedDate, originalModifiedDate)
    }
    
    func testCustomBulgeFilterCodable() throws {
        var filter = CustomBulgeFilter(name: "Test Filter")
        filter.addPoint(BulgePoint(x: 0.3, y: 0.3, strength: 0.6))
        filter.addPoint(BulgePoint(x: 0.7, y: 0.7, strength: -0.4))
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(filter)
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(CustomBulgeFilter.self, from: data)
        
        XCTAssertEqual(filter.id, decoded.id)
        XCTAssertEqual(filter.name, decoded.name)
        XCTAssertEqual(filter.points.count, decoded.points.count)
        XCTAssertEqual(filter.points[0], decoded.points[0])
        XCTAssertEqual(filter.points[1], decoded.points[1])
    }
    
    func testCustomBulgeFilterExportFormat() throws {
        var filter = CustomBulgeFilter(name: "Test Filter")
        filter.addPoint(BulgePoint(x: 0.5, y: 0.5))
        
        let exportData = CustomBulgeFilterExport(filters: [filter])
        
        XCTAssertEqual(exportData.version, "1.0")
        XCTAssertEqual(exportData.appName, "WesWorld FX")
        XCTAssertEqual(exportData.filters.count, 1)
        XCTAssertNotNil(exportData.exportDate)
    }
    
    // MARK: - BulgeFilterManager Tests
    
    func testBulgeFilterManagerSingleton() {
        let manager1 = BulgeFilterManager.shared
        let manager2 = BulgeFilterManager.shared
        
        XCTAssertIdentical(manager1, manager2)
    }
    
    func testBulgeFilterManagerAddFilter() {
        let manager = BulgeFilterManager.shared
        var filter = CustomBulgeFilter(name: "Test Filter")
        filter.addPoint(BulgePoint(x: 0.5, y: 0.5))
        
        manager.addFilter(filter)
        
        let savedFilter = manager.getFilter(byId: filter.id)
        XCTAssertNotNil(savedFilter)
        XCTAssertEqual(savedFilter?.name, "Test Filter")
        XCTAssertEqual(savedFilter?.points.count, 1)
    }
    
    func testBulgeFilterManagerGetAllFilters() {
        let manager = BulgeFilterManager.shared
        
        let initialCount = manager.getAllFilters().count
        
        var filter1 = CustomBulgeFilter(name: "Filter 1")
        filter1.addPoint(BulgePoint(x: 0.3, y: 0.3))
        manager.addFilter(filter1)
        
        var filter2 = CustomBulgeFilter(name: "Filter 2")
        filter2.addPoint(BulgePoint(x: 0.7, y: 0.7))
        manager.addFilter(filter2)
        
        let allFilters = manager.getAllFilters()
        XCTAssertEqual(allFilters.count, initialCount + 2)
    }
    
    func testBulgeFilterManagerUpdateFilter() {
        let manager = BulgeFilterManager.shared
        var filter = CustomBulgeFilter(name: "Original")
        filter.addPoint(BulgePoint(x: 0.5, y: 0.5))
        
        manager.addFilter(filter)
        
        var updatedFilter = filter
        updatedFilter.name = "Updated"
        updatedFilter.addPoint(BulgePoint(x: 0.3, y: 0.3))
        
        manager.updateFilter(updatedFilter)
        
        let retrieved = manager.getFilter(byId: filter.id)
        XCTAssertEqual(retrieved?.name, "Updated")
        XCTAssertEqual(retrieved?.points.count, 2)
    }
    
    func testBulgeFilterManagerDeleteFilter() {
        let manager = BulgeFilterManager.shared
        var filter = CustomBulgeFilter(name: "To Delete")
        filter.addPoint(BulgePoint(x: 0.5, y: 0.5))
        
        manager.addFilter(filter)
        XCTAssertNotNil(manager.getFilter(byId: filter.id))
        
        manager.deleteFilter(byId: filter.id)
        XCTAssertNil(manager.getFilter(byId: filter.id))
    }
    
    func testBulgeFilterManagerExportFilters() throws {
        let manager = BulgeFilterManager.shared
        var filter = CustomBulgeFilter(name: "Export Test")
        filter.addPoint(BulgePoint(x: 0.5, y: 0.5))
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test.wwfxbulge")
        
        try manager.exportFilters([filter], to: tempURL)
        
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempURL.path))
        
        let data = try Data(contentsOf: tempURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let exportData = try decoder.decode(CustomBulgeFilterExport.self, from: data)
        
        XCTAssertEqual(exportData.filters.count, 1)
        XCTAssertEqual(exportData.filters[0].name, "Export Test")
        
        try FileManager.default.removeItem(at: tempURL)
    }
    
    func testBulgeFilterManagerImportFilters() throws {
        let manager = BulgeFilterManager.shared
        var filter = CustomBulgeFilter(name: "Import Test")
        filter.addPoint(BulgePoint(x: 0.5, y: 0.5))
        
        let exportData = CustomBulgeFilterExport(filters: [filter])
        
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("import_test.wwfxbulge")
        
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = .prettyPrinted
        let data = try encoder.encode(exportData)
        try data.write(to: tempURL)
        
        let imported = try manager.importFilters(from: tempURL, merge: false)
        
        XCTAssertEqual(imported.count, 1)
        XCTAssertEqual(imported[0].name, "Import Test")
        
        try FileManager.default.removeItem(at: tempURL)
    }
    
    func testBulgeFilterManagerPersistence() throws {
        let manager = BulgeFilterManager.shared
        
        var filter = CustomBulgeFilter(name: "Persistence Test")
        filter.addPoint(BulgePoint(x: 0.5, y: 0.5, strength: 0.8))
        filter.addPoint(BulgePoint(x: 0.3, y: 0.3, strength: -0.4))
        
        manager.addFilter(filter)
        
        // Simulate creating a new manager instance (would normally reload from UserDefaults)
        // Since we can't reinitialize singleton, we'll verify the data persists
        let allFilters = manager.getAllFilters()
        let foundFilter = allFilters.first { $0.name == "Persistence Test" }
        
        XCTAssertNotNil(foundFilter)
        XCTAssertEqual(foundFilter?.points.count, 2)
    }
    
    // MARK: - FilterType Tests
    
    func testFilterTypeNone() {
        let filterType: FilterType = .none
        XCTAssertEqual(filterType.displayName, "None (Original)")
        XCTAssertEqual(filterType.metalFunctionName, "")
        XCTAssertFalse(filterType.isCustom)
    }
    
    func testFilterTypePreset() {
        let filterType: FilterType = .preset(.bulgeEyes)
        XCTAssertEqual(filterType.displayName, "Bulge Eyes")
        XCTAssertEqual(filterType.metalFunctionName, "bulge_eyes")
        XCTAssertFalse(filterType.isCustom)
    }
    
    func testFilterTypeCustom() {
        let manager = BulgeFilterManager.shared
        var filter = CustomBulgeFilter(name: "Custom Test")
        filter.addPoint(BulgePoint(x: 0.5, y: 0.5))
        manager.addFilter(filter)
        
        let filterType: FilterType = .custom(filter.id)
        XCTAssertTrue(filterType.isCustom)
        XCTAssertEqual(filterType.metalFunctionName, "custom_bulge")
        XCTAssertTrue(filterType.displayName.contains("💎"))
    }
    
    func testFilterTypeEquality() {
        let filter1: FilterType = .none
        let filter2: FilterType = .none
        let filter3: FilterType = .preset(.bulgeEyes)
        
        XCTAssertEqual(filter1, filter2)
        XCTAssertNotEqual(filter1, filter3)
    }
    
    func testFilterTypeHashable() {
        let filter1: FilterType = .preset(.bulgeEyes)
        let filter2: FilterType = .preset(.bulgeEyes)
        
        var set: Set<FilterType> = [filter1]
        set.insert(filter2)
        
        XCTAssertEqual(set.count, 1) // Same type should result in single entry
    }
    
    func testFilterTypeAllAvailableFilters() {
        let manager = BulgeFilterManager.shared
        var filter = CustomBulgeFilter(name: "Available Test")
        filter.addPoint(BulgePoint(x: 0.5, y: 0.5))
        manager.addFilter(filter)
        
        let allFilters = FilterType.allAvailableFilters()
        
        // Should include .none and at least one preset
        XCTAssertGreaterThan(allFilters.count, 1)
        
        let hasNone = allFilters.contains { if case .none = $0 { return true }; return false }
        XCTAssertTrue(hasNone)
        
        let hasCustom = allFilters.contains { if case .custom = $0 { return true }; return false }
        XCTAssertTrue(hasCustom)
    }
    
    // MARK: - Integration Tests
    
    func testCompleteWorkflow() throws {
        let manager = BulgeFilterManager.shared
        
        // 1. Create a custom filter
        var filter = CustomBulgeFilter(name: "Big Eyes Effect")
        filter.addPoint(BulgePoint(x: 0.4, y: 0.6, radius: 0.12, strength: 0.8))
        filter.addPoint(BulgePoint(x: 0.6, y: 0.6, radius: 0.12, strength: 0.8))
        
        // 2. Save filter
        manager.addFilter(filter)
        XCTAssertNotNil(manager.getFilter(byId: filter.id))
        
        // 3. Export filter
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("workflow_test.wwfxbulge")
        try manager.exportFilters([filter], to: tempURL)
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempURL.path))
        
        // 4. Verify export format
        let data = try Data(contentsOf: tempURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let exportData = try decoder.decode(CustomBulgeFilterExport.self, from: data)
        XCTAssertEqual(exportData.version, "1.0")
        XCTAssertEqual(exportData.filters[0].name, "Big Eyes Effect")
        XCTAssertEqual(exportData.filters[0].points.count, 2)
        
        // 5. Delete and re-import
        manager.deleteFilter(byId: filter.id)
        XCTAssertNil(manager.getFilter(byId: filter.id))
        
        let imported = try manager.importFilters(from: tempURL, merge: false)
        XCTAssertEqual(imported.count, 1)
        XCTAssertEqual(imported[0].name, "Big Eyes Effect")
        
        // 6. Verify FilterType integration
        let filterType: FilterType = .custom(imported[0].id)
        XCTAssertTrue(filterType.isCustom)
        XCTAssertTrue(filterType.displayName.contains("Big Eyes Effect"))
        
        try FileManager.default.removeItem(at: tempURL)
    }
    
    func testMultipleFiltersManagement() {
        let manager = BulgeFilterManager.shared
        
        let names = ["Slim Face", "Big Eyes", "Pinch Cheeks", "Funhouse"]
        
        for name in names {
            var filter = CustomBulgeFilter(name: name)
            filter.addPoint(BulgePoint(x: 0.5, y: 0.5))
            manager.addFilter(filter)
        }
        
        let allFilters = manager.getAllFilters()
        for name in names {
            XCTAssertNotNil(allFilters.first { $0.name == name })
        }
    }
    
    func testFilterWithManyPoints() {
        var filter = CustomBulgeFilter(name: "Many Points")
        
        for i in 0..<10 {
            let x = Float(i) / 10.0
            let y = Float(i % 2) * 0.5 + 0.25
            let strength = i % 2 == 0 ? 0.5 : -0.5
            
            filter.addPoint(BulgePoint(x: x, y: y, strength: strength))
        }
        
        XCTAssertEqual(filter.points.count, 10)
        
        // Verify alternating strengths
        for i in 0..<10 {
            if i % 2 == 0 {
                XCTAssertEqual(filter.points[i].strength, 0.5)
            } else {
                XCTAssertEqual(filter.points[i].strength, -0.5)
            }
        }
    }
}
