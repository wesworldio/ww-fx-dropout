//
//  BulgeEditorViewController.swift
//  WesWorld FX
//
//  Interactive editor for creating custom bulge filters
//

import Cocoa
import AVFoundation
import MetalKit

class BulgeEditorViewController: NSViewController {
    
    // Camera preview
    private var previewView: MTKView!
    private var metalRenderer: MetalRenderer!
    private var filterProcessor: FilterProcessor!
    
    // Current filter being edited
    var currentFilter: CustomBulgeFilter?
    var onSave: ((CustomBulgeFilter) -> Void)?
    
    // Live preview
    private var previewUpdateTimer: Timer?
    private var testTexture: MTLTexture?
    private var lastAppliedFilter: CustomBulgeFilter?
    
    // Editor UI
    private var canvasView: NSView!
    private var selectedPointIndex: Int? = nil
    private var isDragging = false
    
    // Debouncing for slider changes
    private var sliderChangeTimer: Timer?
    private var hasPendingSliderChange = false
    
    // Control panel
    private var controlsView: NSView!
    private var filterNameField: NSTextField!
    private var pointsTableView: NSTableView!
    private var addPointButton: NSButton!
    private var deletePointButton: NSButton!
    private var saveButton: NSButton!
    private var cancelButton: NSButton!
    
    // Point property controls
    private var radiusSlider: NSSlider!
    private var strengthSlider: NSSlider!
    private var radiusLabel: NSTextField!
    private var strengthLabel: NSTextField!
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 1280, height: 720))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.darkGray.cgColor
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupPreviewView()
        setupEditorCanvas()
        setupControlPanel()
        
        // Start with empty filter if none provided
        if currentFilter == nil {
            currentFilter = CustomBulgeFilter(name: "My Custom Bulge")
        }
        
        updateUI()
        // Don't start timer immediately - start it after view appears
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        // Start live preview after view is fully loaded
        startLivePreview()
    }
    
    private func setupPreviewView() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }
        
        // Preview on left side
        previewView = MTKView(frame: NSRect(x: 0, y: 0, width: 853, height: 720), device: device)
        previewView.framebufferOnly = false
        previewView.preferredFramesPerSecond = 60
        previewView.clearColor = MTLClearColor(red: 0.1, green: 0.1, blue: 0.1, alpha: 1)
        previewView.isPaused = false
        view.addSubview(previewView)
        
        metalRenderer = MetalRenderer(device: device, view: previewView)
        previewView.delegate = metalRenderer
        
        filterProcessor = FilterProcessor(device: device)
        
        // Create test texture asynchronously to prevent blocking
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            let texture = self.createTestTexture(device: device)
            DispatchQueue.main.async {
                self.testTexture = texture
                // Show initial texture immediately
                if let texture = self.testTexture {
                    self.metalRenderer.updateTexture(texture)
                }
            }
        }
    }
    
    private func setupEditorCanvas() {
        // Transparent overlay for editing bulge points
        canvasView = NSView(frame: previewView.frame)
        canvasView.wantsLayer = true
        canvasView.layer?.backgroundColor = NSColor.clear.cgColor
        view.addSubview(canvasView)
        
        // Enable mouse tracking
        let trackingArea = NSTrackingArea(
            rect: canvasView.bounds,
            options: [.activeAlways, .inVisibleRect, .mouseMoved],
            owner: self,
            userInfo: nil
        )
        canvasView.addTrackingArea(trackingArea)
    }
    
    private func setupControlPanel() {
        // Control panel on right side
        controlsView = NSView(frame: NSRect(x: 863, y: 0, width: 417, height: 720))
        controlsView.wantsLayer = true
        controlsView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        view.addSubview(controlsView)
        
        var yOffset: CGFloat = 680
        
        // Title
        let titleLabel = NSTextField(labelWithString: "Custom Bulge Filter Editor")
        titleLabel.frame = NSRect(x: 10, y: yOffset, width: 397, height: 24)
        titleLabel.font = .systemFont(ofSize: 18, weight: .bold)
        titleLabel.alignment = .center
        controlsView.addSubview(titleLabel)
        yOffset -= 40
        
        // Filter name
        let nameLabel = NSTextField(labelWithString: "Filter Name:")
        nameLabel.frame = NSRect(x: 10, y: yOffset, width: 100, height: 20)
        controlsView.addSubview(nameLabel)
        
        filterNameField = NSTextField(frame: NSRect(x: 120, y: yOffset, width: 287, height: 24))
        filterNameField.placeholderString = "Enter filter name"
        controlsView.addSubview(filterNameField)
        yOffset -= 40
        
        // Instructions
        let instructions = NSTextField(wrappingLabelWithString: "Click on preview to add bulge points. Drag to move. Use sliders to adjust. Shift+Click for pinch effect.")
        instructions.frame = NSRect(x: 10, y: yOffset - 40, width: 397, height: 50)
        instructions.font = .systemFont(ofSize: 11)
        instructions.textColor = .secondaryLabelColor
        controlsView.addSubview(instructions)
        yOffset -= 60
        
        // Points list
        let pointsLabel = NSTextField(labelWithString: "Bulge Points:")
        pointsLabel.frame = NSRect(x: 10, y: yOffset, width: 397, height: 20)
        pointsLabel.font = .systemFont(ofSize: 13, weight: .medium)
        controlsView.addSubview(pointsLabel)
        yOffset -= 30
        
        // Table view for points
        let scrollView = NSScrollView(frame: NSRect(x: 10, y: yOffset - 120, width: 397, height: 120))
        scrollView.hasVerticalScroller = true
        scrollView.borderType = .bezelBorder
        
        pointsTableView = NSTableView(frame: scrollView.bounds)
        pointsTableView.headerView = nil
        pointsTableView.delegate = self
        pointsTableView.dataSource = self
        
        let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier("point"))
        column.width = 380
        pointsTableView.addTableColumn(column)
        
        scrollView.documentView = pointsTableView
        controlsView.addSubview(scrollView)
        yOffset -= 140
        
        // Add/Delete buttons
        addPointButton = NSButton(title: "Add Point (Click Preview)", target: self, action: #selector(showAddPointInstructions))
        addPointButton.frame = NSRect(x: 10, y: yOffset, width: 195, height: 28)
        controlsView.addSubview(addPointButton)
        
        deletePointButton = NSButton(title: "Delete Selected", target: self, action: #selector(deleteSelectedPoint))
        deletePointButton.frame = NSRect(x: 212, y: yOffset, width: 195, height: 28)
        deletePointButton.isEnabled = false
        controlsView.addSubview(deletePointButton)
        yOffset -= 40
        
        // Point properties section
        let propsLabel = NSTextField(labelWithString: "Selected Point Properties:")
        propsLabel.frame = NSRect(x: 10, y: yOffset, width: 397, height: 20)
        propsLabel.font = .systemFont(ofSize: 13, weight: .medium)
        controlsView.addSubview(propsLabel)
        yOffset -= 30
        
        // Radius slider
        let radiusLabelStatic = NSTextField(labelWithString: "Radius:")
        radiusLabelStatic.frame = NSRect(x: 10, y: yOffset, width: 60, height: 20)
        controlsView.addSubview(radiusLabelStatic)
        
        radiusSlider = NSSlider(frame: NSRect(x: 80, y: yOffset, width: 270, height: 24))
        radiusSlider.minValue = 0.05
        radiusSlider.maxValue = 0.5
        radiusSlider.doubleValue = 0.15
        radiusSlider.target = self
        radiusSlider.action = #selector(radiusChanged)
        radiusSlider.isEnabled = false
        controlsView.addSubview(radiusSlider)
        
        radiusLabel = NSTextField(labelWithString: "0.15")
        radiusLabel.frame = NSRect(x: 360, y: yOffset, width: 47, height: 20)
        radiusLabel.alignment = .right
        controlsView.addSubview(radiusLabel)
        yOffset -= 30
        
        // Strength slider
        let strengthLabelStatic = NSTextField(labelWithString: "Strength:")
        strengthLabelStatic.frame = NSRect(x: 10, y: yOffset, width: 60, height: 20)
        controlsView.addSubview(strengthLabelStatic)
        
        strengthSlider = NSSlider(frame: NSRect(x: 80, y: yOffset, width: 270, height: 24))
        strengthSlider.minValue = -1.0
        strengthSlider.maxValue = 1.0
        strengthSlider.doubleValue = 0.65
        strengthSlider.target = self
        strengthSlider.action = #selector(strengthChanged)
        strengthSlider.isEnabled = false
        controlsView.addSubview(strengthSlider)
        
        strengthLabel = NSTextField(labelWithString: "0.65")
        strengthLabel.frame = NSRect(x: 360, y: yOffset, width: 47, height: 20)
        strengthLabel.alignment = .right
        controlsView.addSubview(strengthLabel)
        yOffset -= 50
        
        // Hint
        let hint = NSTextField(wrappingLabelWithString: "Positive strength = bulge (push out)\nNegative strength = pinch (pull in)")
        hint.frame = NSRect(x: 10, y: yOffset - 30, width: 397, height: 35)
        hint.font = .systemFont(ofSize: 10)
        hint.textColor = .secondaryLabelColor
        controlsView.addSubview(hint)
        yOffset -= 70
        
        // Save/Cancel buttons
        saveButton = NSButton(title: "Save Filter", target: self, action: #selector(saveFilter))
        saveButton.frame = NSRect(x: 10, y: 20, width: 195, height: 32)
        saveButton.bezelStyle = .rounded
        saveButton.keyEquivalent = "\r" // Enter key
        controlsView.addSubview(saveButton)
        
        cancelButton = NSButton(title: "Cancel", target: self, action: #selector(cancel))
        cancelButton.frame = NSRect(x: 212, y: 20, width: 195, height: 32)
        cancelButton.bezelStyle = .rounded
        cancelButton.keyEquivalent = "\u{1b}" // Escape key
        controlsView.addSubview(cancelButton)
    }
    
    private func updateUI() {
        guard let filter = currentFilter else { return }
        
        filterNameField.stringValue = filter.name
        pointsTableView.reloadData()
        
        // Update property controls based on selection
        if let index = selectedPointIndex, index < filter.points.count {
            let point = filter.points[index]
            radiusSlider.doubleValue = Double(point.radius)
            strengthSlider.doubleValue = Double(point.strength)
            radiusLabel.stringValue = String(format: "%.2f", point.radius)
            strengthLabel.stringValue = String(format: "%.2f", point.strength)
            radiusSlider.isEnabled = true
            strengthSlider.isEnabled = true
            deletePointButton.isEnabled = true
        } else {
            radiusSlider.isEnabled = false
            strengthSlider.isEnabled = false
            deletePointButton.isEnabled = false
        }
        
        redrawCanvas()
        applyFilter()
    }
    
    private func redrawCanvas() {
        guard let filter = currentFilter else { return }
        
        // Clear existing sublayers
        canvasView.layer?.sublayers?.removeAll()
        
        // Draw each bulge point
        for (index, point) in filter.points.enumerated() {
            let isSelected = (index == selectedPointIndex)
            drawBulgePoint(point, at: index, selected: isSelected)
        }
    }
    
    private func drawBulgePoint(_ point: BulgePoint, at index: Int, selected: Bool) {
        let width = canvasView.bounds.width
        let height = canvasView.bounds.height
        
        let centerX = CGFloat(point.x) * width
        let centerY = CGFloat(1.0 - point.y) * height // Flip Y coordinate
        let radius = CGFloat(point.radius) * min(width, height)
        
        // Draw radius circle
        let circleLayer = CAShapeLayer()
        let circlePath = NSBezierPath(ovalIn: NSRect(
            x: centerX - radius,
            y: centerY - radius,
            width: radius * 2,
            height: radius * 2
        ))
        if #available(macOS 14.0, *) {
            circleLayer.path = circlePath.cgPath
        } else {
            circleLayer.path = circlePath.flattened.cgPath
        }
        circleLayer.strokeColor = selected ? NSColor.systemBlue.cgColor : NSColor.systemGreen.cgColor
        circleLayer.fillColor = selected ? NSColor.systemBlue.withAlphaComponent(0.1).cgColor : NSColor.systemGreen.withAlphaComponent(0.05).cgColor
        circleLayer.lineWidth = selected ? 3 : 2
        canvasView.layer?.addSublayer(circleLayer)
        
        // Draw center point
        let centerLayer = CAShapeLayer()
        let centerPath = NSBezierPath(ovalIn: NSRect(
            x: centerX - 5,
            y: centerY - 5,
            width: 10,
            height: 10
        ))
        if #available(macOS 14.0, *) {
            centerLayer.path = centerPath.cgPath
        } else {
            centerLayer.path = centerPath.flattened.cgPath
        }
        centerLayer.fillColor = point.strength >= 0 ? NSColor.systemYellow.cgColor : NSColor.systemRed.cgColor
        canvasView.layer?.addSublayer(centerLayer)
        
        // Draw index label
        let textLayer = CATextLayer()
        textLayer.string = "\(index + 1)"
        textLayer.fontSize = 14
        textLayer.foregroundColor = NSColor.white.cgColor
        textLayer.frame = NSRect(x: centerX + 8, y: centerY - 8, width: 30, height: 20)
        canvasView.layer?.addSublayer(textLayer)
    }
    
    private func applyFilter() {
        // Apply the custom bulge filter to the preview with live updates (non-blocking)
        guard let filter = currentFilter, let testTexture = testTexture else { return }
        
        // Only process if filter has changed
        if lastAppliedFilter?.id == filter.id && lastAppliedFilter?.points.count == filter.points.count {
            var pointsChanged = false
            for (i, point) in filter.points.enumerated() {
                if i < (lastAppliedFilter?.points.count ?? 0) {
                    let lastPoint = lastAppliedFilter!.points[i]
                    if lastPoint != point {
                        pointsChanged = true
                        break
                    }
                }
            }
            if !pointsChanged {
                return  // No changes, skip processing
            }
        }
        
        // Apply filter asynchronously to prevent blocking UI
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            // Apply custom bulge filter to test texture
            self.filterProcessor.setCurrentFilter(.custom(filter.id))
            
            // Pass filter points to processor for rendering (non-blocking version)
            if let filteredTexture = self.filterProcessor.processCustomBulgeAsync(testTexture, with: filter) {
                DispatchQueue.main.async {
                    self.metalRenderer.updateTexture(filteredTexture)
                }
            }
        }
        
        lastAppliedFilter = filter
    }
    
    // MARK: - Actions
    
    @objc private func showAddPointInstructions() {
        let alert = NSAlert()
        alert.messageText = "Add Bulge Point"
        alert.informativeText = "Click anywhere on the preview image to add a bulge point.\n\n• Regular click = Bulge effect (push out)\n• Shift + click = Pinch effect (pull in)"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @objc private func deleteSelectedPoint() {
        guard let index = selectedPointIndex else { return }
        currentFilter?.removePoint(at: index)
        selectedPointIndex = nil
        updateUI()
    }
    
    @objc private func radiusChanged(_ sender: NSSlider) {
        guard let index = selectedPointIndex else { return }
        let newRadius = Float(sender.doubleValue)
        var point = currentFilter!.points[index]
        point.radius = newRadius
        currentFilter?.updatePoint(at: index, with: point)
        radiusLabel.stringValue = String(format: "%.2f", newRadius)
        
        // Queue update instead of applying immediately - debounce rapid slider changes
        hasPendingSliderChange = true
        sliderChangeTimer?.invalidate()
        sliderChangeTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.applyDebouncedUpdate()
            }
        }
    }
    
    @objc private func strengthChanged(_ sender: NSSlider) {
        guard let index = selectedPointIndex else { return }
        let newStrength = Float(sender.doubleValue)
        var point = currentFilter!.points[index]
        point.strength = newStrength
        currentFilter?.updatePoint(at: index, with: point)
        strengthLabel.stringValue = String(format: "%.2f", newStrength)
        
        // Queue update instead of applying immediately - debounce rapid slider changes
        hasPendingSliderChange = true
        sliderChangeTimer?.invalidate()
        sliderChangeTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: false) { [weak self] _ in
            DispatchQueue.main.async {
                self?.applyDebouncedUpdate()
            }
        }
    }
    
    private func applyDebouncedUpdate() {
        guard hasPendingSliderChange else { return }
        hasPendingSliderChange = false
        
        // Redraw canvas immediately (no GPU work)
        redrawCanvas()
        
        // Apply filter asynchronously (GPU work on background queue)
        applyFilter()
    }
    
    @objc private func saveFilter() {
        guard var filter = currentFilter else { return }
        
        // Update filter name
        let name = filterNameField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty {
            showAlert("Please enter a filter name")
            return
        }
        
        if filter.points.isEmpty {
            showAlert("Please add at least one bulge point")
            return
        }
        
        filter.name = name
        filter.modifiedDate = Date()
        
        onSave?(filter)
        dismiss(self)
    }
    
    @objc private func cancel() {
        dismiss(self)
    }
    
    private func showAlert(_ message: String) {
        let alert = NSAlert()
        alert.messageText = "Validation Error"
        alert.informativeText = message
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    // MARK: - Mouse Handling
    
    override func mouseDown(with event: NSEvent) {
        let location = canvasView.convert(event.locationInWindow, from: nil)
        
        // Check if clicking on existing point
        if let (index, _) = findPointAt(location) {
            selectedPointIndex = index
            isDragging = true
            updateUI()
            return
        }
        
        // Add new point
        let width = canvasView.bounds.width
        let height = canvasView.bounds.height
        let normalizedX = Float(location.x / width)
        let normalizedY = Float(1.0 - (location.y / height)) // Flip Y
        
        // Check if shift key is pressed for pinch effect
        let isShiftPressed = event.modifierFlags.contains(.shift)
        let strength: Float = isShiftPressed ? -0.65 : 0.65
        
        let newPoint = BulgePoint(x: normalizedX, y: normalizedY, radius: 0.15, strength: strength)
        currentFilter?.addPoint(newPoint)
        selectedPointIndex = (currentFilter?.points.count ?? 1) - 1
        updateUI()
    }
    
    override func mouseDragged(with event: NSEvent) {
        guard isDragging, let index = selectedPointIndex else { return }
        
        let location = canvasView.convert(event.locationInWindow, from: nil)
        let width = canvasView.bounds.width
        let height = canvasView.bounds.height
        let normalizedX = Float(max(0, min(1, location.x / width)))
        let normalizedY = Float(max(0, min(1, 1.0 - (location.y / height))))
        
        var point = currentFilter!.points[index]
        point.x = normalizedX
        point.y = normalizedY
        currentFilter?.updatePoint(at: index, with: point)
        updateUI()
    }
    
    override func mouseUp(with event: NSEvent) {
        isDragging = false
    }
    
    private func findPointAt(_ location: NSPoint) -> (Int, BulgePoint)? {
        guard let filter = currentFilter else { return nil }
        
        let width = canvasView.bounds.width
        let height = canvasView.bounds.height
        
        for (index, point) in filter.points.enumerated() {
            let centerX = CGFloat(point.x) * width
            let centerY = CGFloat(1.0 - point.y) * height
            let radius = CGFloat(point.radius) * min(width, height)
            
            let dx = location.x - centerX
            let dy = location.y - centerY
            let distance = sqrt(dx * dx + dy * dy)
            
            if distance <= radius {
                return (index, point)
            }
        }
        
        return nil
    }
    
    // MARK: - Live Preview
    
    private func startLivePreview() {
        // Only start timer if not already running and texture is ready
        guard previewUpdateTimer == nil else { return }
        guard testTexture != nil else {
            // Retry after texture is created
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.startLivePreview()
            }
            return
        }
        
        // Start timer to continuously update preview at 20 FPS (less aggressive)
        previewUpdateTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.applyFilter()
        }
    }
    
    private func stopLivePreview() {
        previewUpdateTimer?.invalidate()
        previewUpdateTimer = nil
    }
    
    private func createTestTexture(device: MTLDevice) -> MTLTexture? {
        // Create a test texture with a gradient pattern for preview
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: .bgra8Unorm,
            width: 853,
            height: 720,
            mipmapped: false
        )
        descriptor.usage = [.shaderRead, .shaderWrite]
        
        guard let texture = device.makeTexture(descriptor: descriptor) else {
            return nil
        }
        
        // Fill with gradient pattern for visualization
        let pixelCount = 853 * 720
        var pixels = [UInt32](repeating: 0, count: pixelCount)
        
        for y in 0..<720 {
            for x in 0..<853 {
                let index = y * 853 + x
                let r = UInt8((Float(x) / 853.0) * 255)
                let g = UInt8((Float(y) / 720.0) * 255)
                let b = UInt8(((Float(x) / 853.0) + (Float(y) / 720.0)) * 127.5)
                
                // BGRA format
                pixels[index] = (UInt32(255) << 24) | (UInt32(b) << 16) | (UInt32(g) << 8) | UInt32(r)
            }
        }
        
        texture.replace(
            region: MTLRegion(origin: MTLOrigin(x: 0, y: 0, z: 0), size: MTLSize(width: 853, height: 720, depth: 1)),
            mipmapLevel: 0,
            withBytes: pixels,
            bytesPerRow: 853 * 4
        )
        
        return texture
    }
    
    deinit {
        stopLivePreview()
    }
}

// MARK: - Table View Data Source & Delegate
extension BulgeEditorViewController: NSTableViewDataSource, NSTableViewDelegate {
    
    func numberOfRows(in tableView: NSTableView) -> Int {
        return currentFilter?.points.count ?? 0
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let point = currentFilter?.points[row] else { return nil }
        
        let cellView = NSTableCellView()
        let textField = NSTextField(labelWithString: String(format: "Point %d: (%.2f, %.2f) R:%.2f S:%.2f %@",
                                                            row + 1,
                                                            point.x,
                                                            point.y,
                                                            point.radius,
                                                            point.strength,
                                                            point.strength >= 0 ? "Bulge" : "Pinch"))
        textField.frame = NSRect(x: 5, y: 0, width: 370, height: 20)
        cellView.addSubview(textField)
        
        return cellView
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        let selectedRow = pointsTableView.selectedRow
        selectedPointIndex = selectedRow >= 0 ? selectedRow : nil
        updateUI()
    }
}

// Extension for NSBezierPath to CGPath conversion
extension NSBezierPath {
    var cgPath: CGPath {
        let path = CGMutablePath()
        var points = [CGPoint](repeating: .zero, count: 3)
        
        for i in 0..<elementCount {
            let type = element(at: i, associatedPoints: &points)
            switch type {
            case .moveTo:
                path.move(to: points[0])
            case .lineTo:
                path.addLine(to: points[0])
            case .curveTo, .cubicCurveTo:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .quadraticCurveTo:
                path.addQuadCurve(to: points[1], control: points[0])
            case .closePath:
                path.closeSubpath()
            @unknown default:
                break
            }
        }
        
        return path
    }
}
