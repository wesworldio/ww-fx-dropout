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
        private func getCPURAMAndMachineInfo() -> [String: String] {
            let cpuUsage = DiagnosticLogger.shared.getCPUUsage()
            let mem = DiagnosticLogger.shared.getMemoryUsage()
            let machine = DiagnosticLogger.shared.getMacModel()
            return [
                "cpu_percent": String(format: "%.1f", cpuUsage),
                "ram_used": String(format: "%llu", mem.usedBytes),
                "ram_total": String(format: "%llu", mem.totalBytes),
                "ram_percent": String(format: "%.1f", mem.usedPercent),
                "machine": machine
            ]
        }
    
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
    private var versionLabel: NSTextField!
    private var filterLabel: NSTextField!
    private var filterSelector: NSPopUpButton!
    private var cameraSelector: NSPopUpButton!
    private var uiVisible: Bool = false
    
    // Performance tracking
    private var lastFrameTime: CFTimeInterval = 0
    private var fps: Double = 0.0
    
    // MARK: - Build Info Helper
    
    private func getBuildVersionString() -> String {
        // Try to read build-info.json from the project root
        let buildInfoPath = "/Users/wes/Sites/wesworld/ww-fx-dropout/build-info.json"
        
        var version = "2.1.3"
        var buildNumber = 190
        
        if FileManager.default.fileExists(atPath: buildInfoPath) {
            do {
                let data = try Data(contentsOf: URL(fileURLWithPath: buildInfoPath))
                if let jsonDict = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    version = jsonDict["version"] as? String ?? "2.1.3"
                    buildNumber = jsonDict["buildNumber"] as? Int ?? 190
                }
            } catch {
                print("Error reading build-info.json: \(error)")
            }
        }
        
        // Check if this is the latest version
        checkIfLatestVersion(currentVersion: version)
        
        let latestTag = isLatestVersion ? " (Latest)" : ""
        return "WesWorld FX v\(version)\(latestTag) (Build \(buildNumber))"
    }
    
    private var isLatestVersion = false
    
    private func checkIfLatestVersion(currentVersion: String) {
        let urlString = "https://api.github.com/repos/wesworldio/ww-fx-dropout/releases/latest"
        guard let url = URL(string: urlString) else { return }
        
        var request = URLRequest(url: url)
        request.setValue("application/vnd.github.v3+json", forHTTPHeaderField: "Accept")
        request.timeoutInterval = 5
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            guard let self = self,
                  let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let tagName = json["tag_name"] as? String else {
                return
            }
            
            let latestVersion = tagName.replacingOccurrences(of: "v", with: "")
            self.isLatestVersion = (currentVersion == latestVersion)
            
            // Update UI on main thread
            DispatchQueue.main.async {
                self.updateVersionDisplay()
            }
        }.resume()
    }
    
    private func updateVersionDisplay() {
        // Re-read and update the version label
        versionLabel.stringValue = getBuildVersionString()
    }
    
    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 1920, height: 1080))
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.black.cgColor
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        DiagnosticLogger.shared.info("CameraViewController viewDidLoad started", category: "LIFECYCLE")
        print("CameraViewController viewDidLoad started")
        
        setupMetalView()
        print("Metal view setup complete")
        DiagnosticLogger.shared.info("Metal view setup complete", category: "GRAPHICS")
        
        setupUI()
        print("UI setup complete")
        DiagnosticLogger.shared.info("UI setup complete", category: "UI")
        
        setupCamera()
        print("Camera setup complete")
        
        setupFilterProcessor()
        print("Filter processor setup complete")
        DiagnosticLogger.shared.info("Filter processor setup complete", category: "FILTERS")
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
        versionLabel = NSTextField(labelWithString: getBuildVersionString())
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
        filterSelector.addItems(withTitles: FilterType.allCases.map { $0.displayName })
        filterSelector.target = self
        filterSelector.action = #selector(filterChanged)
        controlsView.addSubview(filterSelector)
        
        // Instructions
        let instructions = NSTextField(labelWithString: "TAB=Menu SPACE=Random ↑↓=Browse")
        instructions.frame = NSRect(x: 10, y: 5, width: 280, height: 20)
        instructions.textColor = .white.withAlphaComponent(0.7)
        instructions.font = .systemFont(ofSize: 11)
        controlsView.addSubview(instructions)
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .hd1920x1080 // 1080p for best quality with OBS
        
        guard let camera = AVCaptureDevice.default(for: .video) else {
            showError("No camera found")
            DiagnosticLogger.shared.error("No camera device found", category: "CAMERA")
            return
        }
        
        currentCamera = camera
        DiagnosticLogger.shared.logCameraStatus(
            status: "Found camera",
            details: [
                "Name": camera.localizedName,
                "Model": camera.modelID,
                "Supports 1080p": camera.formats.contains { format in
                    let dimensions = CMVideoFormatDescriptionGetDimensions(format.formatDescription)
                    return dimensions.width == 1920 && dimensions.height == 1080
                }
            ]
        )
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                DiagnosticLogger.shared.info("Camera input added to session", category: "CAMERA")
            }
            
            videoOutput = AVCaptureVideoDataOutput()
            videoOutput.setSampleBufferDelegate(self, queue: sessionQueue)
            videoOutput.alwaysDiscardsLateVideoFrames = true
            
            // Use BGRA format for best Metal compatibility
            videoOutput.videoSettings = [
                kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
            ]
            
            if captureSession.canAddOutput(videoOutput) {
                captureSession.addOutput(videoOutput)
                DiagnosticLogger.shared.info("Video output added to session", category: "CAMERA")
            }
            
            // Start session
            sessionQueue.async { [weak self] in
                print("Starting camera capture session...")
                self?.captureSession.startRunning()
                let isRunning = self?.captureSession.isRunning ?? false
                print("Camera capture session started: \(isRunning)")
                if isRunning {
                    DiagnosticLogger.shared.info("Camera capture session started successfully", category: "CAMERA")
                } else {
                    DiagnosticLogger.shared.warning("Camera capture session failed to start", category: "CAMERA")
                }
            }
            
        } catch {
            print("Camera setup error: \(error)")
            DiagnosticLogger.shared.error("Camera setup error", error: error, category: "CAMERA")
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
        if selectedIndex >= 0 && selectedIndex < FilterType.allCases.count {
            let filterType = FilterType.allCases[selectedIndex]
            filterProcessor.currentFilter = filterType
            updateFilterLabel(filterType.displayName)
            DiagnosticLogger.shared.info("Filter changed to: \(filterType.displayName)", category: "FILTERS")
                // Log filter change to remote server
                let sysInfo = getCPURAMAndMachineInfo()
                Task {
                    await WesWorldReporter.shared.logInfo("Filter changed", additionalInfo: [
                        "event": "filter_changed",
                        "filter": filterType.displayName
                    ].merging(sysInfo) { $1 })
                }
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

            // Log camera change to remote server
            let sysInfo = getCPURAMAndMachineInfo()
            Task {
                await WesWorldReporter.shared.logInfo("Camera changed", additionalInfo: [
                    "event": "camera_changed",
                    "camera": newCamera.localizedName
                ].merging(sysInfo) { $1 })
            }
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
        case 49: // Spacebar
            // Random filter selection
            let allFiltersExceptNone = FilterType.allCases.filter { $0 != .none }
            if let randomFilter = allFiltersExceptNone.randomElement() {
                let randomIndex = FilterType.allCases.firstIndex(of: randomFilter) ?? 0
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
            print("First frame received from camera!")
        }
        lastFrameTime = currentTime
        
        // Get pixel buffer from sample buffer
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            print("Failed to get pixel buffer from sample buffer")
            return
        }
        
        // Process frame with filter
        if let filteredTexture = filterProcessor.processFrame(pixelBuffer: pixelBuffer) {
            // Send to renderer
            metalRenderer.updateTexture(filteredTexture)
        } else {
            print("Filter processing failed")
        }
    }
}
