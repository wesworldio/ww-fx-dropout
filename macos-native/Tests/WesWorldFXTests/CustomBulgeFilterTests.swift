import XCTest

// MARK: - Data Models Tests

final class BulgePointTests: XCTestCase {
    
    func testBulgePointInitialization() {
        let point = BulgePoint(x: 0.5, y: 0.6, radius: 0.1, strength: 0.8)
        XCTAssertEqual(point.x, 0.5)
        XCTAssertEqual(point.y, 0.6)
        XCTAssertEqual(point.radius, 0.1)
        XCTAssertEqual(point.strength, 0.8)
    }
    
    func testBulgePointEquality() {
        let point1 = BulgePoint(x: 0.5, y: 0.6, radius: 0.1, strength: 0.8)
        let point2 = BulgePoint(x: 0.5, y: 0.6, radius: 0.1, strength: 0.8)
        XCTAssertEqual(point1, point2)
    }
    
    func testBulgePointCodable() throws {
        let point = BulgePoint(x: 0.5, y: 0.6, radius: 0.1, strength: 0.8)
        let encoder = JSONEncoder()
        let data = try encoder.encode(point)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(BulgePoint.self, from: data)
        XCTAssertEqual(point, decoded)
    }
    
    func testBulgePointEdgeCases() {
        let minPoint = BulgePoint(x: 0.0, y: 0.0, radius: 0.0, strength: -1.0)
        let maxPoint = BulgePoint(x: 1.0, y: 1.0, radius: 1.0, strength: 1.0)
        
        XCTAssertEqual(minPoint.x, 0.0)
        XCTAssertEqual(maxPoint.x, 1.0)
        XCTAssertEqual(minPoint.strength, -1.0)
        XCTAssertEqual(maxPoint.strength, 1.0)
    }
}

// MARK: - CustomBulgeFilter Tests

final class CustomBulgeFilterTests: XCTestCase {
    
    func testFilterInitialization() {
        let filter = CustomBulgeFilter(name: "Test Filter")
        XCTAssertEqual(filter.name, "Test Filter")
        XCTAssertTrue(filter.points.isEmpty)
        XCTAssertNotNil(filter.id)
    }
    
    func testAddPoint() {
        var filter = CustomBulgeFilter(name: "Test Filter")
        let point = BulgePoint(x: 0.5, y: 0.5, radius: 0.1, strength: 0.8)
        
        filter.addPoint(point)
        XCTAssertEqual(filter.points.count, 1)
        XCTAssertEqual(filter.points[0], point)
    }
    
    func testRemovePoint() {
        var filter = CustomBulgeFilter(name: "Test Filter")
        let point = BulgePoint(x: 0.5, y: 0.5, radius: 0.1, strength: 0.8)
        
        filter.addPoint(point)
        XCTAssertEqual(filter.points.count, 1)
        
        filter.removePoint(at: 0)
        XCTAssertTrue(filter.points.isEmpty)
    }
    
    func testUpdatePoint() {
        var filter = CustomBulgeFilter(name: "Test Filter")
        let point1 = BulgePoint(x: 0.5, y: 0.5, radius: 0.1, strength: 0.8)
        filter.addPoint(point1)
        
        let point2 = BulgePoint(x: 0.6, y: 0.6, radius: 0.2, strength: 0.9)
        filter.updatePoint(at: 0, with: point2)
        
        XCTAssertEqual(filter.points[0], point2)
    }
    
    func testFilterCodable() throws {
        var filter = CustomBulgeFilter(name: "Test Filter")
        filter.addPoint(BulgePoint(x: 0.5, y: 0.5, radius: 0.1, strength: 0.8))
        
        let encoder = JSONEncoder()
        let data = try encoder.encode(filter)
        
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(CustomBulgeFilter.self, from: data)
        
        XCTAssertEqual(decoded.name, "Test Filter")
        XCTAssertEqual(decoded.points.count, 1)
    }
    
    func testMultiplePoints() {
        var filter = CustomBulgeFilter(name: "Multi Point Filter")
        
        for i in 0..<5 {
            let point = BulgePoint(
                x: Float(i) * 0.2,
                y: 0.5,
                radius: 0.1,
                strength: 0.5 + Float(i) * 0.1
            )
            filter.addPoint(point)
        }
        
        XCTAssertEqual(filter.points.count, 5)
    }
    
    func testFilterEquality() {
        let filter1 = CustomBulgeFilter(name: "Filter")
        let filter2 = CustomBulgeFilter(name: "Filter")
        
        // Different IDs, so not equal
        XCTAssertNotEqual(filter1.id, filter2.id)
    }
}

// MARK: - BulgeFilterManager Tests

final class BulgeFilterManagerTests: XCTestCase {
    
    override func tearDown() {
        super.tearDown()
        // Clean up UserDefaults after each test
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "com.wesworld.fx.customBulgeFilters")
    }
    
    func testManagerIsSingleton() {
        let manager1 = BulgeFilterManager.shared
        let manager2 = BulgeFilterManager.shared
        XCTAssertTrue(manager1 === manager2)
    }
    
    func testAddAndRetrieveFilter() {
        let manager = BulgeFilterManager.shared
        var filter = CustomBulgeFilter(name: "Test Filter")
        filter.addPoint(BulgePoint(x: 0.5, y: 0.5, radius: 0.1, strength: 0.8))
        
        manager.addFilter(filter)
        
        let retrieved = manager.getFilter(byId: filter.id)
        XCTAssertEqual(retrieved?.name, "Test Filter")
    }
    
    func testDeleteFilter() {
        let manager = BulgeFilterManager.shared
        var filter = CustomBulgeFilter(name: "To Delete")
        filter.addPoint(BulgePoint(x: 0.5, y: 0.5, radius: 0.1, strength: 0.8))
        
        manager.addFilter(filter)
        manager.deleteFilter(byId: filter.id)
        
        let retrieved = manager.getFilter(byId: filter.id)
        XCTAssertNil(retrieved)
    }
    
    func testUpdateFilter() {
        let manager = BulgeFilterManager.shared
        var filter = CustomBulgeFilter(name: "Original")
        filter.addPoint(BulgePoint(x: 0.5, y: 0.5, radius: 0.1, strength: 0.8))
        
        manager.addFilter(filter)
        
        filter.removePoint(at: 0)
        filter.addPoint(BulgePoint(x: 0.3, y: 0.3, radius: 0.2, strength: 0.9))
        manager.updateFilter(filter)
        
        let retrieved = manager.getFilter(byId: filter.id)
        XCTAssertEqual(retrieved?.points.count, 1)
        XCTAssertEqual(retrieved?.points[0].x, 0.3)
    }
    
    func testGetAllFilters() {
        let manager = BulgeFilterManager.shared
        
        for i in 0..<3 {
            var filter = CustomBulgeFilter(name: "Filter \(i)")
            filter.addPoint(BulgePoint(x: 0.5, y: 0.5, radius: 0.1, strength: 0.8))
            manager.addFilter(filter)
        }
        
        let allFilters = manager.getAllFilters()
        XCTAssertEqual(allFilters.count, 3)
    }
    
    func testExportAndImportFilters() throws {
        let manager = BulgeFilterManager.shared
        
        var filter1 = CustomBulgeFilter(name: "Filter 1")
        filter1.addPoint(BulgePoint(x: 0.5, y: 0.5, radius: 0.1, strength: 0.8))
        
        var filter2 = CustomBulgeFilter(name: "Filter 2")
        filter2.addPoint(BulgePoint(x: 0.3, y: 0.3, radius: 0.15, strength: 0.9))
        
        manager.addFilter(filter1)
        manager.addFilter(filter2)
        
        // Export to temporary file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("test_export.wwfxbulge")
        try manager.exportFilters([filter1, filter2], to: tempURL)
        
        // Verify file exists
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempURL.path))
        
        // Clean up
        try FileManager.default.removeItem(at: tempURL)
    }
    
    func testCompleteWorkflow() throws {
        let manager = BulgeFilterManager.shared
        
        // Create filter
        var filter = CustomBulgeFilter(name: "Big Eyes Effect")
        filter.addPoint(BulgePoint(x: 0.4, y: 0.6, radius: 0.12, strength: 0.8))
        filter.addPoint(BulgePoint(x: 0.6, y: 0.6, radius: 0.12, strength: 0.8))
        
        // Save filter
        manager.addFilter(filter)
        
        // Retrieve and verify
        let retrieved = manager.getFilter(byId: filter.id)
        XCTAssertEqual(retrieved?.name, "Big Eyes Effect")
        XCTAssertEqual(retrieved?.points.count, 2)
        
        // Update filter
        filter.removePoint(at: 1)
        manager.updateFilter(filter)
        
        let updated = manager.getFilter(byId: filter.id)
        XCTAssertEqual(updated?.points.count, 1)
    }
}

// MARK: - Integration Tests

final class FilterIntegrationTests: XCTestCase {
    
    override func tearDown() {
        super.tearDown()
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "com.wesworld.fx.customBulgeFilters")
    }
    
    func testFilterTypeNone() {
        let filterType = FilterType.none
        XCTAssertEqual(filterType, .none)
    }
    
    func testFilterTypePreset() {
        let filterType = FilterType.preset(.bulgeEyes)
        
        if case .preset(let preset) = filterType {
            XCTAssertEqual(preset, .bulgeEyes)
        } else {
            XCTFail("Expected preset variant")
        }
    }
    
    func testFilterTypeCustom() {
        let uuid = UUID()
        let filterType = FilterType.custom(uuid)
        
        if case .custom(let id) = filterType {
            XCTAssertEqual(id, uuid)
        } else {
            XCTFail("Expected custom variant")
        }
    }
    
    func testCreateAndPersistCustomFilter() throws {
        let manager = BulgeFilterManager.shared
        
        // Create a custom filter
        var customFilter = CustomBulgeFilter(name: "Pinch Cheeks")
        customFilter.addPoint(BulgePoint(x: 0.25, y: 0.45, radius: 0.1, strength: -0.5))
        customFilter.addPoint(BulgePoint(x: 0.75, y: 0.45, radius: 0.1, strength: -0.5))
        
        // Save it
        manager.addFilter(customFilter)
        
        // Create FilterType referencing it
        let filterType = FilterType.custom(customFilter.id)
        
        // Retrieve the filter
        if case .custom(let id) = filterType {
            let retrieved = manager.getFilter(byId: id)
            XCTAssertEqual(retrieved?.name, "Pinch Cheeks")
            XCTAssertEqual(retrieved?.points.count, 2)
        }
    }
    
    func testMultipleCustomFiltersWithDifferentTypes() {
        let manager = BulgeFilterManager.shared
        
        // Create bulge filter
        var bulgeFilter = CustomBulgeFilter(name: "Big Eyes")
        bulgeFilter.addPoint(BulgePoint(x: 0.4, y: 0.65, radius: 0.12, strength: 0.8))
        manager.addFilter(bulgeFilter)
        
        // Create pinch filter
        var pinchFilter = CustomBulgeFilter(name: "Slim Face")
        pinchFilter.addPoint(BulgePoint(x: 0.3, y: 0.5, radius: 0.15, strength: -0.6))
        manager.addFilter(pinchFilter)
        
        // Verify both exist
        let bigEyes = manager.getFilter(byId: bulgeFilter.id)
        let slimFace = manager.getFilter(byId: pinchFilter.id)
        
        XCTAssertEqual(bigEyes?.name, "Big Eyes")
        XCTAssertEqual(slimFace?.name, "Slim Face")
        
        // Verify properties
        XCTAssertGreater(bigEyes?.points[0].strength ?? 0, 0) // Bulge
        XCTAssertLess(slimFace?.points[0].strength ?? 0, 0)   // Pinch
    }
    
    func testFilterExportFormat() throws {
        let manager = BulgeFilterManager.shared
        
        var filter = CustomBulgeFilter(name: "Export Test")
        filter.addPoint(BulgePoint(x: 0.5, y: 0.5, radius: 0.1, strength: 0.8))
        
        // Encode as JSON
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(filter)
        
        // Decode and verify structure
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(json)
        XCTAssertEqual(json?["name"] as? String, "Export Test")
        XCTAssertNotNil(json?["id"])
        XCTAssertNotNil(json?["points"])
    }
    
    func testLargePointSet() {
        var filter = CustomBulgeFilter(name: "Many Points")
        
        // Add 50 points
        for i in 0..<50 {
            let x = Float(i % 10) * 0.1
            let y = Float(i / 10) * 0.2
            let point = BulgePoint(x: x, y: y, radius: 0.05, strength: 0.5)
            filter.addPoint(point)
        }
        
        XCTAssertEqual(filter.points.count, 50)
        
        // Verify serialization works
        let encoder = JSONEncoder()
        let data = try? encoder.encode(filter)
        XCTAssertNotNil(data)
    }
}

// MARK: - Performance Tests

final class FilterPerformanceTests: XCTestCase {
    
    func testSerializationPerformance() {
        var filter = CustomBulgeFilter(name: "Performance Test")
        
        // Add points
        for i in 0..<100 {
            let point = BulgePoint(
                x: Float.random(in: 0...1),
                y: Float.random(in: 0...1),
                radius: Float.random(in: 0.05...0.2),
                strength: Float.random(in: -1...1)
            )
            filter.addPoint(point)
        }
        
        measure {
            let encoder = JSONEncoder()
            _ = try? encoder.encode(filter)
        }
    }
}
