//
//  BulgeFilterManager.swift
//  WesWorld FX
//
//  Manages persistence, export, and import of custom bulge filters
//

import Foundation
import AppKit

class BulgeFilterManager {
    public static let shared = BulgeFilterManager()
    
    private let userDefaultsKey = "com.wesworld.fx.customBulgeFilters"
    private let fileExtension = "wwfxbulge"
    
    private var customFilters: [CustomBulgeFilter] = []
    
    private init() {
        loadFilters()
    }
    
    // MARK: - Filter Management
    
    public func getAllFilters() -> [CustomBulgeFilter] {
        return customFilters
    }
    
    public func getFilter(byId id: UUID) -> CustomBulgeFilter? {
        return customFilters.first { $0.id == id }
    }
    
    public func addFilter(_ filter: CustomBulgeFilter) {
        customFilters.append(filter)
        saveFilters()
    }
    
    public func updateFilter(_ filter: CustomBulgeFilter) {
        if let index = customFilters.firstIndex(where: { $0.id == filter.id }) {
            customFilters[index] = filter
            saveFilters()
        }
    }
    
    public func deleteFilter(byId id: UUID) {
        customFilters.removeAll { $0.id == id }
        saveFilters()
    }
    
    public func deleteAllFilters() {
        customFilters.removeAll()
        saveFilters()
    }
    
    // MARK: - Persistence
    
    private func saveFilters() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(customFilters)
            UserDefaults.standard.set(data, forKey: userDefaultsKey)
            print("✓ Saved \(customFilters.count) custom bulge filters")
        } catch {
            print("❌ Failed to save custom bulge filters: \(error)")
        }
    }
    
    private func loadFilters() {
        guard let data = UserDefaults.standard.data(forKey: userDefaultsKey) else {
            print("No saved custom bulge filters found")
            return
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            customFilters = try decoder.decode([CustomBulgeFilter].self, from: data)
            print("✓ Loaded \(customFilters.count) custom bulge filters")
        } catch {
            print("❌ Failed to load custom bulge filters: \(error)")
            customFilters = []
        }
    }
    
    // MARK: - Export
    
    public func exportFilters(_ filters: [CustomBulgeFilter], to url: URL) throws {
        let exportData = CustomBulgeFilterExport(filters: filters)
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(exportData)
        try data.write(to: url)
        
        print("✓ Exported \(filters.count) custom bulge filters to \(url.lastPathComponent)")
    }
    
    public func exportAllFilters() {
        let savePanel = NSSavePanel()
        savePanel.title = "Export Custom Bulge Filters"
        savePanel.message = "Choose where to save your custom bulge filters"
        savePanel.allowedContentTypes = [.init(filenameExtension: fileExtension)!]
        savePanel.nameFieldStringValue = "WesWorld-Bulge-Filters-\(Date().formatted(.iso8601)).wwfxbulge"
        savePanel.canCreateDirectories = true
        
        savePanel.begin { [weak self] response in
            guard let self = self,
                  response == .OK,
                  let url = savePanel.url else {
                return
            }
            
            do {
                try self.exportFilters(self.customFilters, to: url)
                self.showAlert(title: "Export Successful",
                             message: "Exported \(self.customFilters.count) custom bulge filters successfully.",
                             style: .informational)
            } catch {
                self.showAlert(title: "Export Failed",
                             message: "Failed to export filters: \(error.localizedDescription)",
                             style: .critical)
            }
        }
    }
    
    public func exportFilter(_ filter: CustomBulgeFilter) {
        let savePanel = NSSavePanel()
        savePanel.title = "Export Bulge Filter"
        savePanel.message = "Choose where to save this bulge filter"
        savePanel.allowedContentTypes = [.init(filenameExtension: fileExtension)!]
        savePanel.nameFieldStringValue = "\(filter.name).wwfxbulge"
        savePanel.canCreateDirectories = true
        
        savePanel.begin { [weak self] response in
            guard let self = self,
                  response == .OK,
                  let url = savePanel.url else {
                return
            }
            
            do {
                try self.exportFilters([filter], to: url)
                self.showAlert(title: "Export Successful",
                             message: "Exported '\(filter.name)' successfully.",
                             style: .informational)
            } catch {
                self.showAlert(title: "Export Failed",
                             message: "Failed to export filter: \(error.localizedDescription)",
                             style: .critical)
            }
        }
    }
    
    // MARK: - Import
    
    public func importFilters(from url: URL, merge: Bool = true) throws -> [CustomBulgeFilter] {
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let exportData = try decoder.decode(CustomBulgeFilterExport.self, from: data)
        
        if merge {
            // Merge with existing filters, avoiding duplicates by name
            for filter in exportData.filters {
                if !customFilters.contains(where: { $0.name == filter.name }) {
                    customFilters.append(filter)
                } else {
                    // Create new filter with modified name
                    var newFilter = filter
                    newFilter.id = UUID()
                    newFilter.name = "\(filter.name) (Imported)"
                    customFilters.append(newFilter)
                }
            }
            saveFilters()
        }
        
        print("✓ Imported \(exportData.filters.count) custom bulge filters from \(url.lastPathComponent)")
        return exportData.filters
    }
    
    public func importFiltersDialog() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Import Custom Bulge Filters"
        openPanel.message = "Choose a bulge filter file to import"
        openPanel.allowedContentTypes = [.init(filenameExtension: fileExtension)!]
        openPanel.allowsMultipleSelection = false
        openPanel.canChooseDirectories = false
        
        openPanel.begin { [weak self] response in
            guard let self = self,
                  response == .OK,
                  let url = openPanel.url else {
                return
            }
            
            do {
                let importedFilters = try self.importFilters(from: url, merge: true)
                self.showAlert(title: "Import Successful",
                             message: "Imported \(importedFilters.count) custom bulge filters successfully.",
                             style: .informational)
            } catch {
                self.showAlert(title: "Import Failed",
                             message: "Failed to import filters: \(error.localizedDescription)",
                             style: .critical)
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func showAlert(title: String, message: String, style: NSAlert.Style) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = title
            alert.informativeText = message
            alert.alertStyle = style
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
}
