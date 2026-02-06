//
//  CustomBulgeFilter.swift
//  WesWorld FX
//
//  Custom bulge filter definitions with multiple control points
//

import Foundation
import CoreGraphics

/// Represents a single bulge point with position, radius, and strength
public struct BulgePoint: Codable, Equatable {
    public var x: Float  // Normalized position 0.0 to 1.0
    public var y: Float  // Normalized position 0.0 to 1.0
    public var radius: Float  // Normalized radius 0.0 to 1.0
    public var strength: Float  // Strength -1.0 to 1.0 (negative for pinch)
    
    public init(x: Float, y: Float, radius: Float = 0.15, strength: Float = 0.65) {
        self.x = x
        self.y = y
        self.radius = radius
        self.strength = strength
    }
}

/// A custom bulge filter with multiple control points
public struct CustomBulgeFilter: Codable, Equatable, Identifiable {
    public var id: UUID
    public var name: String
    public var points: [BulgePoint]
    public var createdDate: Date
    public var modifiedDate: Date
    
    public init(id: UUID = UUID(), name: String, points: [BulgePoint] = []) {
        self.id = id
        self.name = name
        self.points = points
        self.createdDate = Date()
        self.modifiedDate = Date()
    }
    
    public mutating func addPoint(_ point: BulgePoint) {
        points.append(point)
        modifiedDate = Date()
    }
    
    public mutating func removePoint(at index: Int) {
        guard index >= 0 && index < points.count else { return }
        points.remove(at: index)
        modifiedDate = Date()
    }
    
    public mutating func updatePoint(at index: Int, with point: BulgePoint) {
        guard index >= 0 && index < points.count else { return }
        points[index] = point
        modifiedDate = Date()
    }
}

/// Export format for sharing custom bulge filters
public struct CustomBulgeFilterExport: Codable {
    public var version: String = "1.0"
    public var appName: String = "WesWorld FX"
    public var filters: [CustomBulgeFilter]
    public var exportDate: Date
    
    public init(filters: [CustomBulgeFilter]) {
        self.filters = filters
        self.exportDate = Date()
    }
}
