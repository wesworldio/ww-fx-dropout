const { app, BrowserWindow, ipcMain, systemPreferences } = require('electron');
const path = require('path');

// Enable hardware acceleration for better FPS
app.commandLine.appendSwitch('enable-features', 'VaapiVideoDecoder,VaapiVideoEncoder');
app.commandLine.appendSwitch('ignore-gpu-blocklist');
app.commandLine.appendSwitch('enable-gpu-rasterization');
app.commandLine.appendSwitch('enable-zero-copy');
app.commandLine.appendSwitch('disable-frame-rate-limit');

let mainWindow;

function createWindow() {
  mainWindow = new BrowserWindow({
    width: 1280,
    height: 720,
    minWidth: 800,
    minHeight: 600,
    backgroundColor: '#000000',
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      contextIsolation: true,
      nodeIntegration: false,
      webSecurity: true,
      enableRemoteModule: false,
      // Enable hardware acceleration for canvas and WebGL
      hardwareAcceleration: true,
      // Enable WebAssembly
      enableWebAssembly: true,
      // Enable camera access
      enableMediaDevices: true
    },
    show: false, // Don't show until ready
    icon: path.join(__dirname, '..', 'assets', 'icons', 'icon.png')
  });

  // Load the app from the root directory
  mainWindow.loadFile(path.join(__dirname, '..', 'index.html'));

  // Show window when ready to prevent flashing
  mainWindow.once('ready-to-show', () => {
    mainWindow.show();
  });

  // Open DevTools in development mode
  if (process.env.NODE_ENV === 'development') {
    mainWindow.webContents.openDevTools();
  }

  // Handle window closed
  mainWindow.on('closed', () => {
    mainWindow = null;
  });

  // Optimize rendering
  mainWindow.webContents.on('did-finish-load', () => {
    // Inject performance optimizations
    mainWindow.webContents.executeJavaScript(`
      // Disable throttling when app is in background
      if (typeof navigator !== 'undefined' && navigator.scheduling) {
        navigator.scheduling.isInputPending = () => false;
      }
      
      // Mark as desktop app for potential optimizations
      window.isElectronApp = true;
      window.electronPlatform = '${process.platform}';
      
      console.log('WesWorld FX Desktop - Running on Electron');
      console.log('Platform:', '${process.platform}');
      console.log('Hardware acceleration:', ${app.commandLine.hasSwitch('enable-gpu-rasterization')});
    `);
  });
}

// Request camera permissions on macOS
async function requestCameraPermission() {
  if (process.platform === 'darwin') {
    try {
      const status = await systemPreferences.getMediaAccessStatus('camera');
      if (status !== 'granted') {
        const result = await systemPreferences.askForMediaAccess('camera');
        return result;
      }
      return true;
    } catch (error) {
      console.error('Error requesting camera permission:', error);
      return false;
    }
  }
  return true;
}

// App lifecycle
app.whenReady().then(async () => {
  // Request camera permission before creating window
  await requestCameraPermission();
  
  createWindow();

  app.on('activate', () => {
    if (BrowserWindow.getAllWindows().length === 0) {
      createWindow();
    }
  });
});

app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit();
  }
});

// IPC handlers
ipcMain.handle('get-app-version', () => {
  return app.getVersion();
});

ipcMain.handle('get-platform', () => {
  return {
    platform: process.platform,
    arch: process.arch,
    isElectron: true
  };
});

// GPU info for debugging
ipcMain.handle('get-gpu-info', async () => {
  const gpuFeatureStatus = app.getGPUFeatureStatus();
  return {
    gpuFeatureStatus,
    gpuInfo: await mainWindow.webContents.executeJavaScript(`
      (async () => {
        if (navigator.gpu) {
          try {
            const adapter = await navigator.gpu.requestAdapter();
            return {
              webgpu: true,
              adapterInfo: adapter ? 'Available' : 'Not available'
            };
          } catch (e) {
            return { webgpu: false, error: e.message };
          }
        }
        return { webgpu: false };
      })()
    `)
  };
});
