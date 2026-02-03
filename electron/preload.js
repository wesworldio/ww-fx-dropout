const { contextBridge, ipcRenderer } = require('electron');

// Expose protected methods that allow the renderer process to use
// ipcRenderer without exposing the entire object
contextBridge.exposeInMainWorld('electronAPI', {
  getAppVersion: () => ipcRenderer.invoke('get-app-version'),
  getPlatform: () => ipcRenderer.invoke('get-platform'),
  getGPUInfo: () => ipcRenderer.invoke('get-gpu-info'),
  isElectron: true
});

// Performance optimizations for desktop
contextBridge.exposeInMainWorld('desktopOptimizations', {
  // Request high performance mode
  requestHighPerformance: () => {
    return new Promise((resolve) => {
      // Signal to main process that we want high performance
      resolve({ enabled: true, mode: 'high-performance' });
    });
  },
  
  // Get system info for optimization
  getSystemInfo: () => ipcRenderer.invoke('get-platform')
});
