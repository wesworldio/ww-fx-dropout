#!/usr/bin/env swift

import Foundation

// Read the bundled bulge effects file
if let bundledURL = Bundle.main.url(forResource: "42_bulge_effects", withExtension: "wwfxbulge") {
    print("✓ Found bundled bulge effects file at: \(bundledURL.path)")
    
    do {
        let data = try Data(contentsOf: bundledURL)
        print("✓ Successfully read file: \(data.count) bytes")
        
        // Try to decode the JSON
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            print("✓ Valid JSON format")
            
            if let filters = json["filters"] as? [[String: Any]] {
                print("✓ Found \(filters.count) filters")
                
                // Show first few filter names
                for (index, filter) in filters.prefix(5).enumerated() {
                    if let name = filter["name"] as? String {
                        print("  \(index + 1). \(name)")
                    }
                }
                if filters.count > 5 {
                    print("  ... and \(filters.count - 5) more")
                }
            }
        }
    } catch {
        print("❌ Error reading file: \(error)")
    }
} else {
    print("❌ Bundled bulge effects file not found!")
}
