/**
 * Shared Filter Implementations
 * Used by both standalone.html and static/index.html
 */

// Filter implementations for canvas image data manipulation
const FilterImplementations = {
    // Color filters
    applyBlackWhite(data) {
        for (let i = 0; i < data.length; i += 4) {
            const gray = data[i] * 0.299 + data[i + 1] * 0.587 + data[i + 2] * 0.114;
            data[i] = gray;
            data[i + 1] = gray;
            data[i + 2] = gray;
        }
    },
    
    applySepia(data) {
        for (let i = 0; i < data.length; i += 4) {
            const r = data[i];
            const g = data[i + 1];
            const b = data[i + 2];
            data[i] = Math.min(255, (r * 0.393) + (g * 0.769) + (b * 0.189));
            data[i + 1] = Math.min(255, (r * 0.349) + (g * 0.686) + (b * 0.168));
            data[i + 2] = Math.min(255, (r * 0.272) + (g * 0.534) + (b * 0.131));
        }
    },
    
    applyNegative(data) {
        for (let i = 0; i < data.length; i += 4) {
            data[i] = 255 - data[i];
            data[i + 1] = 255 - data[i + 1];
            data[i + 2] = 255 - data[i + 2];
        }
    },
    
    applyVintage(data) {
        for (let i = 0; i < data.length; i += 4) {
            const r = data[i];
            const g = data[i + 1];
            const b = data[i + 2];
            data[i] = Math.min(255, r * 0.9 + 20);
            data[i + 1] = Math.min(255, g * 0.85 + 15);
            data[i + 2] = Math.min(255, b * 0.8 + 10);
        }
    },
    
    applyNeonGlow(data) {
        for (let i = 0; i < data.length; i += 4) {
            const r = data[i];
            const g = data[i + 1];
            const b = data[i + 2];
            const brightness = (r + g + b) / 3;
            data[i] = Math.min(255, brightness * 1.5);
            data[i + 1] = Math.min(255, brightness * 1.2);
            data[i + 2] = Math.min(255, brightness * 2);
        }
    },
    
    applyRedTint(data) {
        for (let i = 0; i < data.length; i += 4) {
            data[i] = Math.min(255, data[i] * 1.5);
        }
    },
    
    applyBlueTint(data) {
        for (let i = 0; i < data.length; i += 4) {
            data[i + 2] = Math.min(255, data[i + 2] * 1.5);
        }
    },
    
    applyGreenTint(data) {
        for (let i = 0; i < data.length; i += 4) {
            data[i + 1] = Math.min(255, data[i + 1] * 1.5);
        }
    },
    
    applyPosterize(data) {
        const levels = 4;
        for (let i = 0; i < data.length; i += 4) {
            data[i] = Math.floor(data[i] / (256 / levels)) * (256 / levels);
            data[i + 1] = Math.floor(data[i + 1] / (256 / levels)) * (256 / levels);
            data[i + 2] = Math.floor(data[i + 2] / (256 / levels)) * (256 / levels);
        }
    },
    
    applyThermal(data) {
        for (let i = 0; i < data.length; i += 4) {
            const gray = (data[i] + data[i + 1] + data[i + 2]) / 3;
            if (gray < 85) {
                data[i] = 0;
                data[i + 1] = 0;
                data[i + 2] = gray * 3;
            } else if (gray < 170) {
                data[i] = (gray - 85) * 3;
                data[i + 1] = 255;
                data[i + 2] = 255;
            } else {
                data[i] = 255;
                data[i + 1] = 255 - (gray - 170) * 3;
                data[i + 2] = 0;
            }
        }
    },
    
    // Spatial filters
    applyPixelate(data, width, height) {
        const pixelSize = 10;
        for (let y = 0; y < height; y += pixelSize) {
            for (let x = 0; x < width; x += pixelSize) {
                let r = 0, g = 0, b = 0, count = 0;
                for (let dy = 0; dy < pixelSize && y + dy < height; dy++) {
                    for (let dx = 0; dx < pixelSize && x + dx < width; dx++) {
                        const idx = ((y + dy) * width + (x + dx)) * 4;
                        r += data[idx];
                        g += data[idx + 1];
                        b += data[idx + 2];
                        count++;
                    }
                }
                r = Math.floor(r / count);
                g = Math.floor(g / count);
                b = Math.floor(b / count);
                for (let dy = 0; dy < pixelSize && y + dy < height; dy++) {
                    for (let dx = 0; dx < pixelSize && x + dx < width; dx++) {
                        const idx = ((y + dy) * width + (x + dx)) * 4;
                        data[idx] = r;
                        data[idx + 1] = g;
                        data[idx + 2] = b;
                    }
                }
            }
        }
    },
    
    applyBlur(data, width, height) {
        const radius = 5;
        const temp = new Uint8ClampedArray(data);
        for (let y = 0; y < height; y++) {
            for (let x = 0; x < width; x++) {
                let r = 0, g = 0, b = 0, count = 0;
                for (let dy = -radius; dy <= radius; dy++) {
                    for (let dx = -radius; dx <= radius; dx++) {
                        const nx = x + dx;
                        const ny = y + dy;
                        if (nx >= 0 && nx < width && ny >= 0 && ny < height) {
                            const idx = (ny * width + nx) * 4;
                            r += temp[idx];
                            g += temp[idx + 1];
                            b += temp[idx + 2];
                            count++;
                        }
                    }
                }
                const idx = (y * width + x) * 4;
                data[idx] = r / count;
                data[idx + 1] = g / count;
                data[idx + 2] = b / count;
            }
        }
    },
    
    applySharpen(data, width, height) {
        const kernel = [[0, -1, 0], [-1, 5, -1], [0, -1, 0]];
        const temp = new Uint8ClampedArray(data);
        for (let y = 1; y < height - 1; y++) {
            for (let x = 1; x < width - 1; x++) {
                let r = 0, g = 0, b = 0;
                for (let ky = -1; ky <= 1; ky++) {
                    for (let kx = -1; kx <= 1; kx++) {
                        const idx = ((y + ky) * width + (x + kx)) * 4;
                        const weight = kernel[ky + 1][kx + 1];
                        r += temp[idx] * weight;
                        g += temp[idx + 1] * weight;
                        b += temp[idx + 2] * weight;
                    }
                }
                const idx = (y * width + x) * 4;
                data[idx] = Math.max(0, Math.min(255, r));
                data[idx + 1] = Math.max(0, Math.min(255, g));
                data[idx + 2] = Math.max(0, Math.min(255, b));
            }
        }
    },
    
    applyEmboss(data, width, height) {
        const kernel = [[-2, -1, 0], [-1, 1, 1], [0, 1, 2]];
        const temp = new Uint8ClampedArray(data);
        for (let y = 1; y < height - 1; y++) {
            for (let x = 1; x < width - 1; x++) {
                let r = 0, g = 0, b = 0;
                for (let ky = -1; ky <= 1; ky++) {
                    for (let kx = -1; kx <= 1; kx++) {
                        const idx = ((y + ky) * width + (x + kx)) * 4;
                        const weight = kernel[ky + 1][kx + 1];
                        r += temp[idx] * weight;
                        g += temp[idx + 1] * weight;
                        b += temp[idx + 2] * weight;
                    }
                }
                const idx = (y * width + x) * 4;
                const gray = (r + g + b) / 3;
                data[idx] = Math.max(0, Math.min(255, gray + 128));
                data[idx + 1] = Math.max(0, Math.min(255, gray + 128));
                data[idx + 2] = Math.max(0, Math.min(255, gray + 128));
            }
        }
    },
    
    applySketch(data, width, height) {
        this.applyBlur(data, width, height);
        for (let i = 0; i < data.length; i += 4) {
            const gray = (data[i] + data[i + 1] + data[i + 2]) / 3;
            const inverted = 255 - gray;
            data[i] = Math.min(255, inverted);
            data[i + 1] = Math.min(255, inverted);
            data[i + 2] = Math.min(255, inverted);
        }
    },
    
    applyCartoon(data, width, height) {
        this.applyBlur(data, width, height);
        this.applyPosterize(data);
    },
    
    applyRainbow(data, width, height) {
        for (let y = 0; y < height; y++) {
            const hue = (y / height) * 360;
            for (let x = 0; x < width; x++) {
                const idx = (y * width + x) * 4;
                const gray = (data[idx] + data[idx + 1] + data[idx + 2]) / 3;
                const rgb = this.hslToRgb(hue / 360, 1, gray / 255);
                data[idx] = rgb[0];
                data[idx + 1] = rgb[1];
                data[idx + 2] = rgb[2];
            }
        }
    },
    
    applyBulge(data, width, height) {
        const centerX = width / 2;
        const centerY = height / 2;
        const radius = Math.min(width, height) / 2;
        const strength = 0.5;
        
        const temp = new Uint8ClampedArray(data);
        for (let y = 0; y < height; y++) {
            for (let x = 0; x < width; x++) {
                const dx = x - centerX;
                const dy = y - centerY;
                const dist = Math.sqrt(dx * dx + dy * dy);
                
                if (dist < radius) {
                    const angle = Math.atan2(dy, dx);
                    const r = dist / radius;
                    const newR = r * (1 - strength * (1 - r));
                    const newX = Math.round(centerX + Math.cos(angle) * newR * radius);
                    const newY = Math.round(centerY + Math.sin(angle) * newR * radius);
                    
                    if (newX >= 0 && newX < width && newY >= 0 && newY < height) {
                        const srcIdx = (y * width + x) * 4;
                        const dstIdx = (newY * width + newX) * 4;
                        data[srcIdx] = temp[dstIdx];
                        data[srcIdx + 1] = temp[dstIdx + 1];
                        data[srcIdx + 2] = temp[dstIdx + 2];
                        data[srcIdx + 3] = temp[dstIdx + 3];
                    }
                }
            }
        }
    },
    
    // Helper function
    hslToRgb(h, s, l) {
        let r, g, b;
        if (s === 0) {
            r = g = b = l;
        } else {
            const hue2rgb = (p, q, t) => {
                if (t < 0) t += 1;
                if (t > 1) t -= 1;
                if (t < 1/6) return p + (q - p) * 6 * t;
                if (t < 1/2) return q;
                if (t < 2/3) return p + (q - p) * (2/3 - t) * 6;
                return p;
            };
            const q = l < 0.5 ? l * (1 + s) : l + s - l * s;
            const p = 2 * l - q;
            r = hue2rgb(p, q, h + 1/3);
            g = hue2rgb(p, q, h);
            b = hue2rgb(p, q, h - 1/3);
        }
        return [Math.round(r * 255), Math.round(g * 255), Math.round(b * 255)];
    }
};

