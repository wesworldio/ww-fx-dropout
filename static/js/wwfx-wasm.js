/**
 * WesWorld FX WASM Module
 * MIT License - See LICENSE file
 * 
 * JavaScript wrapper for WASM-based face filter processing
 * Works in browsers, mobile devices, and can be compiled to native for desktop
 */

class WWFXWasm {
    constructor() {
        this.module = null;
        this.ready = false;
        this.initializing = false;
    }

    /**
     * Initialize the WASM module
     * @param {string} wasmPath - Path to the WASM file
     * @returns {Promise<void>}
     */
    async init(wasmPath = 'wasm/wwfx_module.wasm') {
        if (this.ready) {
            return Promise.resolve();
        }

        if (this.initializing) {
            // Wait for existing initialization
            return new Promise((resolve) => {
                const checkReady = setInterval(() => {
                    if (this.ready) {
                        clearInterval(checkReady);
                        resolve();
                    }
                }, 100);
            });
        }

        this.initializing = true;

        try {
            // Load WASM module
            // This assumes the WASM module is built with Emscripten
            // and exports createWasmModule function
            if (typeof createWasmModule === 'undefined') {
                throw new Error('WASM module not found. Make sure wwfx_module.js is loaded first.');
            }

            const wasmModule = await createWasmModule({
                locateFile: (path) => {
                    if (path.endsWith('.wasm')) {
                        return wasmPath;
                    }
                    return path;
                }
            });

            this.module = wasmModule;
            this.ready = true;
            this.initializing = false;

            console.log('WASM module loaded successfully');
        } catch (error) {
            this.initializing = false;
            console.error('Failed to load WASM module:', error);
            throw error;
        }
    }

    /**
     * Check if WASM is supported
     * @returns {boolean}
     */
    static isSupported() {
        return typeof WebAssembly !== 'undefined';
    }

    /**
     * Create an image buffer from canvas ImageData
     * @param {ImageData} imageData - Canvas ImageData
     * @returns {ImageBuffer}
     */
    createImageBuffer(imageData) {
        if (!this.ready) {
            throw new Error('WASM module not initialized. Call init() first.');
        }

        const buffer = new this.module.ImageBuffer(
            imageData.width,
            imageData.height,
            4 // RGBA
        );

        // Copy image data
        const data = new Uint8Array(imageData.data);
        buffer.setData(data);

        return buffer;
    }

    /**
     * Apply filter to image buffer
     * @param {ImageBuffer} imageBuffer - Image buffer
     * @param {number} filterType - Filter type enum value
     * @param {Object|null} faceRect - Face rectangle {x, y, width, height, confidence}
     * @param {number} frameCount - Frame count for animated filters
     * @returns {number} 0 on success, non-zero on error
     */
    applyFilter(imageBuffer, filterType, faceRect = null, frameCount = 0) {
        if (!this.ready) {
            throw new Error('WASM module not initialized.');
        }

        let face = null;
        if (faceRect) {
            face = new this.module.FaceRect(
                faceRect.x,
                faceRect.y,
                faceRect.width,
                faceRect.height,
                faceRect.confidence || 1.0
            );
        }

        return this.module.applyFilter(imageBuffer, filterType, face, frameCount);
    }

    /**
     * Apply face mask to image buffer
     * @param {ImageBuffer} imageBuffer - Image buffer
     * @param {Object} faceRect - Face rectangle
     * @param {ImageData} maskImageData - Mask image data (RGBA)
     * @returns {number} 0 on success, non-zero on error
     */
    applyFaceMask(imageBuffer, faceRect, maskImageData) {
        if (!this.ready) {
            throw new Error('WASM module not initialized.');
        }

        const face = new this.module.FaceRect(
            faceRect.x,
            faceRect.y,
            faceRect.width,
            faceRect.height,
            faceRect.confidence || 1.0
        );

        const maskData = new Uint8Array(maskImageData.data);

        return this.module.applyFaceMask(
            imageBuffer,
            face,
            maskData,
            maskImageData.width,
            maskImageData.height
        );
    }

    /**
     * Get image data from buffer
     * @param {ImageBuffer} imageBuffer - Image buffer
     * @returns {Uint8ClampedArray} Image data
     */
    getImageData(imageBuffer) {
        if (!this.ready) {
            throw new Error('WASM module not initialized.');
        }

        return imageBuffer.getData();
    }

    /**
     * Process canvas frame with filter
     * @param {HTMLCanvasElement} inputCanvas - Input canvas
     * @param {HTMLCanvasElement} outputCanvas - Output canvas
     * @param {number} filterType - Filter type
     * @param {Object|null} faceRect - Face rectangle
     * @param {number} frameCount - Frame count
     */
    processFrame(inputCanvas, outputCanvas, filterType, faceRect = null, frameCount = 0) {
        if (!this.ready) {
            throw new Error('WASM module not initialized.');
        }

        const inputCtx = inputCanvas.getContext('2d');
        const outputCtx = outputCanvas.getContext('2d');

        // Get input image data
        const inputData = inputCtx.getImageData(0, 0, inputCanvas.width, inputCanvas.height);

        // Create WASM image buffer
        const imageBuffer = this.createImageBuffer(inputData);

        // Apply filter
        const result = this.applyFilter(imageBuffer, filterType, faceRect, frameCount);

        if (result === 0) {
            // Get processed data
            const outputData = this.getImageData(imageBuffer);

            // Create new ImageData
            const newImageData = new ImageData(
                new Uint8ClampedArray(outputData),
                inputCanvas.width,
                inputCanvas.height
            );

            // Draw to output canvas
            outputCtx.putImageData(newImageData, 0, 0);
        }

        // Cleanup
        imageBuffer.delete();
        if (faceRect) {
            faceRect.delete();
        }
    }

    /**
     * Get filter count
     * @returns {number}
     */
    getFilterCount() {
        if (!this.ready) {
            return 0;
        }

        return this.module.getFilterCount();
    }
}

// Export for use in modules or global scope
if (typeof module !== 'undefined' && module.exports) {
    module.exports = WWFXWasm;
} else {
    window.WWFXWasm = WWFXWasm;
}

