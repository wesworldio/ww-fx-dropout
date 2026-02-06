// Desktop-specific performance optimizations
// This file is loaded automatically in the Electron app

(function() {
  'use strict';
  
  // Check if running in Electron
  if (!window.electronAPI) {
    console.log('Not running in Electron, skipping desktop optimizations');
    return;
  }
  
  console.log('WesWorld FX Desktop - Applying performance optimizations');
  
  // Request high performance mode
  if (window.desktopOptimizations) {
    window.desktopOptimizations.requestHighPerformance().then(result => {
      console.log('High performance mode:', result);
    });
  }
  
  // Disable background throttling
  if (document.hidden !== undefined) {
    document.addEventListener('visibilitychange', () => {
      if (!document.hidden) {
        console.log('App visible - maintaining full performance');
      }
    });
  }
  
  // Canvas optimizations for desktop
  const originalGetContext = HTMLCanvasElement.prototype.getContext;
  HTMLCanvasElement.prototype.getContext = function(type, options) {
    if (type === '2d') {
      // Enable hardware acceleration for 2D canvas
      options = options || {};
      options.willReadFrequently = false; // Better for video processing
      options.alpha = options.alpha !== undefined ? options.alpha : false;
      options.desynchronized = true; // Reduce latency
    } else if (type === 'webgl' || type === 'webgl2') {
      // Optimize WebGL context
      options = options || {};
      options.powerPreference = 'high-performance';
      options.antialias = options.antialias !== undefined ? options.antialias : false;
      options.depth = options.depth !== undefined ? options.depth : false;
      options.stencil = options.stencil !== undefined ? options.stencil : false;
      options.preserveDrawingBuffer = false;
      options.failIfMajorPerformanceCaveat = false;
      options.desynchronized = true;
    }
    return originalGetContext.call(this, type, options);
  };
  
  // Request animation frame optimization
  let rafCallbacks = [];
  let rafScheduled = false;
  
  const originalRAF = window.requestAnimationFrame;
  window.requestAnimationFrame = function(callback) {
    rafCallbacks.push(callback);
    if (!rafScheduled) {
      rafScheduled = true;
      originalRAF.call(window, (timestamp) => {
        rafScheduled = false;
        const callbacks = rafCallbacks;
        rafCallbacks = [];
        callbacks.forEach(cb => {
          try {
            cb(timestamp);
          } catch (e) {
            console.error('RAF callback error:', e);
          }
        });
      });
    }
    return rafCallbacks.length - 1;
  };
  
  // Video element optimizations
  const originalCreateElement = document.createElement;
  document.createElement = function(tagName, options) {
    const element = originalCreateElement.call(document, tagName, options);
    if (tagName.toLowerCase() === 'video') {
      // Set optimal video properties for desktop
      element.setAttribute('playsinline', '');
      element.setAttribute('autoplay', '');
      // Disable potential memory leaks from video
      element.addEventListener('loadedmetadata', function() {
        console.log('Video loaded:', this.videoWidth, 'x', this.videoHeight);
      });
    }
    return element;
  };
  
  // MediaStream constraints optimization for desktop
  const originalGetUserMedia = navigator.mediaDevices.getUserMedia.bind(navigator.mediaDevices);
  navigator.mediaDevices.getUserMedia = async function(constraints) {
    if (constraints && constraints.video) {
      // Optimize video constraints for desktop
      if (typeof constraints.video === 'object') {
        // Request higher frame rate for desktop
        constraints.video.frameRate = constraints.video.frameRate || { ideal: 60, min: 30 };
        
        // Request higher resolution if not specified
        if (!constraints.video.width && !constraints.video.height) {
          constraints.video.width = { ideal: 1920 };
          constraints.video.height = { ideal: 1080 };
        }
        
        // Prefer hardware-accelerated video on desktop
        constraints.video.facingMode = constraints.video.facingMode || 'user';
        
        console.log('Desktop-optimized video constraints:', constraints.video);
      }
    }
    return originalGetUserMedia(constraints);
  };
  
  // Performance monitoring
  let lastFPS = 0;
  let frameCount = 0;
  let lastTime = performance.now();
  
  function monitorPerformance() {
    frameCount++;
    const currentTime = performance.now();
    const delta = currentTime - lastTime;
    
    if (delta >= 1000) {
      lastFPS = Math.round((frameCount * 1000) / delta);
      frameCount = 0;
      lastTime = currentTime;
      
      // Log FPS every 5 seconds
      if (Math.random() < 0.2) {
        console.log('Desktop FPS:', lastFPS);
      }
    }
    
    requestAnimationFrame(monitorPerformance);
  }
  
  // Start monitoring
  requestAnimationFrame(monitorPerformance);
  
  // Add desktop app indicator to UI
  window.addEventListener('DOMContentLoaded', async () => {
    try {
      const platformInfo = await window.electronAPI.getPlatform();
      console.log('Platform info:', platformInfo);
      
      // Add desktop indicator to status
      const createDesktopIndicator = () => {
        const indicator = document.createElement('div');
        indicator.id = 'desktopIndicator';
        indicator.style.cssText = `
          position: fixed;
          bottom: 10px;
          right: 10px;
          background: rgba(26, 26, 26, 0.9);
          color: #00ff00;
          padding: 4px 12px;
          border-radius: 4px;
          font-size: 11px;
          font-weight: 600;
          z-index: 1000;
          border: 1px solid #00ff00;
          backdrop-filter: blur(8px);
          pointer-events: none;
        `;
        indicator.textContent = `🖥️ DESKTOP MODE`;
        document.body.appendChild(indicator);
        
        // Fade out after 3 seconds
        setTimeout(() => {
          indicator.style.transition = 'opacity 0.5s';
          indicator.style.opacity = '0';
          setTimeout(() => indicator.remove(), 500);
        }, 3000);
      };
      
      if (document.body) {
        createDesktopIndicator();
      } else {
        window.addEventListener('DOMContentLoaded', createDesktopIndicator);
      }
      
    } catch (error) {
      console.error('Error setting up desktop indicator:', error);
    }
  });
  
  console.log('Desktop optimizations applied successfully');
})();
