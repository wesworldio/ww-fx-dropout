//
//  CameraViewController.swift
//  WesWorld FX
//
//  High-performance camera capture with AVFoundation
//

import Cocoa
import AVFoundation
import MetalKit

class CameraViewController: NSViewController {
    
    // Camera
    private var captureSession: AVCaptureSession!
    private var videoOutput: AVCaptureVideoDataOutput!
    private var currentCamera: AVCaptureDevice?
    private let sessionQueue = DispatchQueue(label: "com.wesworld.fx.camera")
    
    // Metal rendering
    private var metalView: MTKView!
    private var metalRenderer: MetalRenderer!
    
    // Filter manager
    private var filterProcessor: FilterProcessor!
    
    // UI
    private var controlsView: NSView!
    private var fpsLabel: NSTextField!
    private var filterLabel: NSTextField!
    private var filterSelector: NSPopUpButton!
    private var cameraSelector: NSPopUpButton!
    private var uiVisible: Bool = false
    
    // Performance tracking
    private var lastFrameTime: CFTimeInterval = 0
    private var fps: Double = 0.0
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 1920, height: 1080))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("CameraViewController viewDidLoad started")
        
        do {
            setupMetalView()
            print("Metal view setup complete")
            
            setupUI()
            print("UI setup complete")
            
            // CRITICAL: Setup filter processor BEFORE camera to avoid race condition
            setupFilterProcessor()
            print("Filter processor setup complete")
            
            setupCamera()
            print("Camera setup complete")
        } catch {
            print("Error during setup: \(error)")
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.makeFirstResponder(self)
    }
    
    override var acceptsFirstResponder: Bool {
        return true
    }
    
    private func setupMetalView() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }
        
        metalView = MTKView(frame: view.bounds, device: device)
        metalView.autoresizingMask = [.width, .height]
        metalView.framebufferOnly = false
        metalView.preferredFramesPerSecond = 60
        metalView.enableSetNeedsDisplay = false
        metalView.isPaused = false
        metalView.clearColor = MTLClearColor(red: 0, green: 0, blue: 0, alpha: 1)
        
        view.addSubview(metalView)
        
        // Initialize Metal renderer
        metalRenderer = MetalRenderer(device: device, view: metalView)
        metalView.delegate = metalRenderer
    }
    
    private func setupUI() {
        // Controls container - toggle with Tab key
        controlsView = NSView(frame: NSRect(x: 10, y: view.bounds.height - 190, width: 300, height: 180))
        controlsView.wantsLayer = true
        controlsView.layer?.backgroundColor = NSColor.black.withAlphaComponent(0.85).cgColor
        controlsView.layer?.cornerRadius = 8
        controlsView.autoresizingMask = [.minYMargin]
        controlsView.isHidden = true
        view.addSubview(controlsView)
        
        // Version Label
        let versionLabel = NSTextField(labelWithString: "WesWorld FX v2.1.2 (Build 2128)")
        versionLabel.frame = NSRect(x: 10, y: 165, width: 280, height: 15)
        versionLabel.textColor = .white.withAlphaComponent(0.6)
        versionLabel.font = .systemFont(ofSize: 11, weight: .regular)
        controlsView.addSubview(versionLabel)
        
        // FPS Label
        fpsLabel = NSTextField(labelWithString: "FPS: --")
        fpsLabel.frame = NSRect(x: 10, y: 145, width: 280, height: 20)
        fpsLabel.textColor = .white
        fpsLabel.font = .monospacedSystemFont(ofSize: 14, weight: .medium)
        controlsView.addSubview(fpsLabel)
        
        // Camera Label
        let cameraLabel = NSTextField(labelWithString: "Camera:")
        cameraLabel.frame = NSRect(x: 10, y: 120, width: 280, height: 20)
        cameraLabel.textColor = .white
        cameraLabel.font = .systemFont(ofSize: 13, weight: .medium)
        controlsView.addSubview(cameraLabel)
        
        // Camera Selector
        cameraSelector = NSPopUpButton(frame: NSRect(x: 10, y: 90, width: 280, height: 25))
        cameraSelector.target = self
        cameraSelector.action = #selector(cameraChanged)
        updateCameraList()
        controlsView.addSubview(cameraSelector)
        
        // Filter Label
        filterLabel = NSTextField(labelWithString: "Current Filter:")
        filterLabel.frame = NSRect(x: 10, y: 60, width: 280, height: 20)
        filterLabel.textColor = .white
        filterLabel.font = .systemFont(ofSize: 13, weight: .medium)
        controlsView.addSubview(filterLabel)
        
        // Filter Selector
        filterSelector = NSPopUpButton(frame: NSRect(x: 10, y: 30, width: 280, height: 25))
        filterSelector.target = self
        filterSelector.action = #selector(filterChanged)
        updateFilterList()
        controlsView.addSubview(filterSelector)
        
        // Select Bulge Eyes by default (index 1, after None)
        let allFilters = FilterType.allAvailableFilters()
        if allFilters.count > 1 {
            filterSelector.selectItem(at: 1) // Bulge Eyes
            updateFilterLabel(allFilters[1].displayName)
        }
        
        // Instructions
        let instructions = NSTextField(labelWithString: "TAB=Menu SPACE=Random ↑↓=Browse B=Editor N=Manage")
        instructions.frame = NSRect(x: 10, y: 5, width: 280, height: 20)
        instructions.textColor = .white.withAlphaComponent(0.7)
        instructions.font = .systemFont(ofSize: 11)
        controlsView.addSubview(instructions)
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        
        // Try different presets for compatibility
        let presets: [AVCaptureSession.Preset] = [.hd1920x1080, .hd1280x720, .high]
        var presetSelected = false
        
        for preset in presets {
            if captureSession.canSetSessionPreset(preset) {
                captureSession.sessionPreset = preset
                print("📷 Camera preset set to: \(preset.rawValue)")
                presetSelected = true
                break
            }
        }
        
        if !presetSelected {
            print("⚠️  No camera preset could be set, using default")
        }
        
        // Get all available cameras and **strongly prefer** built-in
        let allCameras = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .externalUnknown],
            mediaType: .video,
            position: .unspecified
        ).devices
        
        print("📷 Found \(allCameras.count) camera(s):")
        for (index, cam) in allCameras.enumerated() {
            print("   [\(index)] \(cam.localizedName) - \(cam.deviceType.rawValue)")
        }
        
        // STRONGLY prefer built-in camera - don't fall back easily
        let camera: AVCaptureDevice?
        if let builtIn = allCameras.first(where: { $0.deviceType == .builtInWideAngleCamera }) {
            camera = builtIn
            print("📷 🎯 Using BUILT-IN camera: \(builtIn.localizedName)")
        } else if let external = allCameras.first {
            camera = external
            print("⚠️  No built-in camera found, using: \(external.localizedName)")
        } else {
            camera = nil
            print("❌ NO CAMERAS FOUND!")
        }
        
        guard let camera = camera else {
            showError("No camera found. Please check System Preferences > Security & Privacy > Camera")
            return
        }
        
        print("📷 Selected camera: \(camera.localizedName)")
        currentCamera = camera
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                print("✓ Camera input added")
            } else {
                print("❌ Cannot add camera input")
                return
            }
            
            videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
            videoOutput.alwaysDiscardsLateVideoFrames = true
            
            // Try different pixel formats for compatibility
            let preferredFormats: [NSNumber] = [
                NSNumber(value: kCVPixelFormatType_32BGRA),
                NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarFullRange),
                NSNumber(value: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange)
            ]
            
            videoOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: preferredFormats
            ]
            
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
                print("✓ Video output added")
                
                // Configure connection for proper orientation
                if let connection = videoOutput.connection(with: .video) {
                    if connection.isVideoOrientationSupported {
                        connection.videoOrientation = .portrait
                        print("✓ Video orientation set to portrait")
                    }
                    if connection.isVideoMirroringSupported {
                        connection.isVideoMirrored = false
                        print("✓ Video mirroring disabled")
                    }
                }
            } else {
                print("❌ Cannot add video output")
                return
            }
            
            // Start session on background queue
            sessionQueue.async { [weak self] in
                guard let self = self else { return }
                print("📹 Starting camera capture session...")
                self.captureSession.startRunning()
                let isRunning = self.captureSession.isRunning
                print("📹 Capture session running: \(isRunning)")
                if !isRunning {
                    print("❌ Failed to start capture session!")
                }
            }
            
        } catch {
            print("❌ Camera setup error: \(error)")
            showError("Camera setup failed: \(error.localizedDescription)")
        }
    }
    
    private func setupFilterProcessor() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal not supported")
        }
        filterProcessor = FilterProcessor(device: device)
    }
    
    @objc private func filterChanged() {
        let selectedIndex = filterSelector.indexOfSelectedItem
        let allFilters = FilterType.allAvailableFilters()
        if selectedIndex >= 0 && selectedIndex < allFilters.count {
            let filterType = allFilters[selectedIndex]
            filterProcessor.currentFilter = filterType
            updateFilterLabel(filterType.displayName)
        }
    }
    
    func updateFilterList() {
        filterSelector.removeAllItems()
        let allFilters = FilterType.allAvailableFilters()
        filterSelector.addItems(withTitles: allFilters.map { $0.displayName })
    }
    
    @objc func openBulgeEditor() {
        let editorVC = BulgeEditorViewController()
        editorVC.onSave = { [weak self] filter in
            BulgeFilterManager.shared.addFilter(filter)
            self?.updateFilterList()
            
            // Select the newly created filter
            let allFilters = FilterType.allAvailableFilters()
            if let index = allFilters.firstIndex(where: { 
                if case .custom(let id) = $0 {
                    return id == filter.id
                }
                return false
            }) {
                self?.filterSelector.selectItem(at: index)
                self?.filterChanged()
            }
        }
        
        presentAsSheet(editorVC)
    }
    
    @objc func manageBulgeFilters() {
        let alert = NSAlert()
        alert.messageText = "Manage Custom Bulge Filters"
        alert.informativeText = "You have \(BulgeFilterManager.shared.getAllFilters().count) custom bulge filters saved."
        alert.addButton(withTitle: "Export All")
        alert.addButton(withTitle: "Import")
        alert.addButton(withTitle: "Delete All")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        switch response {
        case .alertFirstButtonReturn: // Export All
            BulgeFilterManager.shared.exportAllFilters()
        case .alertSecondButtonReturn: // Import
            BulgeFilterManager.shared.importFiltersDialog()
            updateFilterList()
        case .alertThirdButtonReturn: // Delete All
            let confirmAlert = NSAlert()
            confirmAlert.messageText = "Delete All Custom Bulge Filters?"
            confirmAlert.informativeText = "This action cannot be undone."
            confirmAlert.alertStyle = .critical
            confirmAlert.addButton(withTitle: "Delete All")
            confirmAlert.addButton(withTitle: "Cancel")
            
            if confirmAlert.runModal() == .alertFirstButtonReturn {
                BulgeFilterManager.shared.deleteAllFilters()
                updateFilterList()
            }
        default:
            break
        }
    }
    
    @objc private func cameraChanged() {
        let cameras = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .externalUnknown],
            mediaType: .video,
            position: .unspecified
        ).devices
        
        let selectedIndex = cameraSelector.indexOfSelectedItem
        guard selectedIndex >= 0 && selectedIndex < cameras.count else { return }
        
        let newCamera = cameras[selectedIndex]
        switchCamera(to: newCamera)
    }
    
    private func updateCameraList() {
        let cameras = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .externalUnknown],
            mediaType: .video,
            position: .unspecified
        ).devices
        
        cameraSelector.removeAllItems()
        cameraSelector.addItems(withTitles: cameras.map { $0.localizedName })
        
        // Select current camera
        if let current = currentCamera,
           let index = cameras.firstIndex(of: current) {
            cameraSelector.selectItem(at: index)
        }
    }
    
    private func switchCamera(to newCamera: AVCaptureDevice) {
        sessionQueue.async { [weak self] in
            guard let self = self else { return }
            
            self.captureSession.beginConfiguration()
            
            // Remove current input
            if let currentInput = self.captureSession.inputs.first as? AVCaptureDeviceInput {
                self.captureSession.removeInput(currentInput)
            }
            
            // Add new input
            do {
                let newInput = try AVCaptureDeviceInput(device: newCamera)
                if self.captureSession.canAddInput(newInput) {
                    self.captureSession.addInput(newInput)
                    self.currentCamera = newCamera
                    
                    // Update UI on main thread
                    DispatchQueue.main.async {
                        self.updateCameraList()
                    }
                }
            } catch {
                print("Failed to switch camera: \(error)")
            }
            
            self.captureSession.commitConfiguration()
        }
    }
    
    private func cycleCamera() {
        let cameras = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera, .externalUnknown],
            mediaType: .video,
            position: .unspecified
        ).devices
        
        guard cameras.count > 1 else { return }
        
        // Find next camera
        if let current = currentCamera,
           let currentIndex = cameras.firstIndex(of: current) {
            let nextIndex = (currentIndex + 1) % cameras.count
            let nextCamera = cameras[nextIndex]
            switchCamera(to: nextCamera)
        } else if let firstCamera = cameras.first {
            switchCamera(to: firstCamera)
        }
    }
    
    private func toggleUI() {
        uiVisible.toggle()
        controlsView.isHidden = !uiVisible
    }
    
    private func toggleGrid() {
        filterProcessor.showGrid.toggle()
    }
    
    private func updateFilterLabel(_ filterName: String) {
        DispatchQueue.main.async { [weak self] in
            self?.filterLabel.stringValue = "Current Filter: \(filterName)"
        }
    }
    
    private func updateFPS(_ fps: Double) {
        DispatchQueue.main.async { [weak self] in
            self?.fpsLabel.stringValue = String(format: "FPS: %.1f", fps)
            
            // Color code FPS
            if fps < 25 {
                self?.fpsLabel.textColor = .red
            } else if fps < 45 {
                self?.fpsLabel.textColor = .yellow
            } else {
                self?.fpsLabel.textColor = .green
            }
        }
    }
    
    private func showError(_ message: String) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.messageText = "Error"
            alert.informativeText = message
            alert.alertStyle = .critical
            alert.addButton(withTitle: "OK")
            alert.runModal()
        }
    }
    
    func cleanup() {
        sessionQueue.async { [weak self] in
            self?.captureSession?.stopRunning()
        }
    }
    
    override func keyDown(with event: NSEvent) {
        switch event.keyCode {
        case 48: // Tab
            toggleUI()
        case 13: // W key - toggle grid overlay
            toggleGrid()
        case 49: // Spacebar
            // Random filter selection
            let allFilters = FilterType.allAvailableFilters()
            let allFiltersExceptNone = allFilters.filter { 
                if case .none = $0 { return false }
                return true
            }
            if let randomFilter = allFiltersExceptNone.randomElement() {
                let randomIndex = allFilters.firstIndex(of: randomFilter) ?? 0
                filterSelector.selectItem(at: randomIndex)
                filterChanged()
            }
        case 126: // Up arrow
            let currentIndex = filterSelector.indexOfSelectedItem
            if currentIndex > 0 {
                filterSelector.selectItem(at: currentIndex - 1)
                filterChanged()
            }
        case 125: // Down arrow
            let currentIndex = filterSelector.indexOfSelectedItem
            if currentIndex < filterSelector.numberOfItems - 1 {
                filterSelector.selectItem(at: currentIndex + 1)
                filterChanged()
            }
        case 34: // i/I key - cycle cameras
            cycleCamera()
        case 15: // r/R key - reload custom filters
            updateFilterList()
        case 11: // b/B key - open bulge editor
            openBulgeEditor()
        case 45: // n/N key - manage custom filters
            manageBulgeFilters()
        default:
            // Don't call super to prevent system beep
            break
        }
    }
    
    override func mouseDown(with event: NSEvent) {
        // Cycle to next filter on click
        let currentIndex = filterSelector.indexOfSelectedItem
        let nextIndex = (currentIndex + 1) % filterSelector.numberOfItems
        filterSelector.selectItem(at: nextIndex)
        filterChanged()
    }
    
    @objc private func checkForUpdatesMenu() {
        UpdateChecker.shared.checkForUpdates(showNoUpdateAlert: true)
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraViewController: AVCaptureVideoDataOutputSampleBufferDelegate {
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        // Calculate FPS
        let currentTime = CACurrentMediaTime()
        if lastFrameTime > 0 {
            let delta = currentTime - lastFrameTime
            fps = 1.0 / delta
            
            // Update FPS display every 10 frames
            if Int(currentTime * 60) % 10 == 0 {
                updateFPS(fps)
            }
        } else {
            print("✅ First frame received from camera!")
            print("   Format: BGRA8Unorm")
            print("   Timestamp: \(currentTime)")
        }
        lastFrameTime = currentTime
        
        // Get pixel buffer from sample buffer
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("❌ Failed to get pixel buffer from sample buffer")
            return
        }
        
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)
        
        // Safety check: ensure filter processor is initialized before processing
        guard filterProcessor != nil else {
            print("⚠️  Filter processor not yet initialized, skipping frame")
            return
        }
        
        // Process frame with filter
        if let filteredTexture = filterProcessor.processFrame(pixelBuffer: pixelBuffer) {
            // Debug first processed frame
            if lastFrameTime <= 0.1 {
                print("✅ Texture received by renderer: \(filteredTexture.width)x\(filteredTexture.height)")
                print("   Pixel format: \(filteredTexture.pixelFormat.rawValue)")
            }
            
            // Send to renderer
            metalRenderer.updateTexture(filteredTexture)
        } else {
            print("⚠️  Filter processing returned nil (this shouldn't happen)")
        }
    }
}
