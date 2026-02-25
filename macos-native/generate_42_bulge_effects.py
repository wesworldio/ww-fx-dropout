#!/usr/bin/env python3
"""
Generate 42 unique bulge effects for WesWorld FX macOS native app
Creates diverse, creative bulge filter configurations for E2E testing
"""

import json
import uuid
from datetime import datetime
from typing import List, Dict, Any
import math

class BulgePoint:
    """Represents a single bulge point"""
    def __init__(self, x: float, y: float, radius: float = 0.15, strength: float = 0.65):
        self.x = x
        self.y = y
        self.radius = radius
        self.strength = strength
    
    def to_dict(self) -> Dict[str, float]:
        return {
            "x": self.x,
            "y": self.y,
            "radius": self.radius,
            "strength": self.strength
        }

class CustomBulgeFilter:
    """Represents a custom bulge filter"""
    def __init__(self, name: str, points: List[BulgePoint]):
        self.id = str(uuid.uuid4())
        self.name = name
        self.points = points
        self.createdDate = datetime.now().isoformat() + "Z"
        self.modifiedDate = self.createdDate
    
    def to_dict(self) -> Dict[str, Any]:
        return {
            "id": self.id,
            "name": self.name,
            "points": [p.to_dict() for p in self.points],
            "createdDate": self.createdDate,
            "modifiedDate": self.modifiedDate
        }

def generate_bulge_effects() -> List[CustomBulgeFilter]:
    """Generate 42 unique bulge effects"""
    filters = []
    
    # 1. Classic Eye Bulge (dual eyes)
    filters.append(CustomBulgeFilter("Classic Eye Bulge", [
        BulgePoint(0.35, 0.4, 0.12, 0.8),
        BulgePoint(0.65, 0.4, 0.12, 0.8)
    ]))
    
    # 2. Alien Eyes (large eyes)
    filters.append(CustomBulgeFilter("Alien Eyes", [
        BulgePoint(0.35, 0.35, 0.18, 0.95),
        BulgePoint(0.65, 0.35, 0.18, 0.95)
    ]))
    
    # 3. Fish Eye Center (single center bulge)
    filters.append(CustomBulgeFilter("Fish Eye Center", [
        BulgePoint(0.5, 0.5, 0.35, 0.75)
    ]))
    
    # 4. Pinch Face (facial compression)
    filters.append(CustomBulgeFilter("Pinch Face", [
        BulgePoint(0.5, 0.5, 0.25, -0.7)
    ]))
    
    # 5. Bulge Cheeks (plump cheeks)
    filters.append(CustomBulgeFilter("Bulge Cheeks", [
        BulgePoint(0.3, 0.55, 0.15, 0.65),
        BulgePoint(0.7, 0.55, 0.15, 0.65)
    ]))
    
    # 6. Forehead Dome (prominent forehead)
    filters.append(CustomBulgeFilter("Forehead Dome", [
        BulgePoint(0.5, 0.25, 0.2, 0.8)
    ]))
    
    # 7. Chin Bulge (prominent chin)
    filters.append(CustomBulgeFilter("Chin Bulge", [
        BulgePoint(0.5, 0.75, 0.15, 0.7)
    ]))
    
    # 8. Nose Pinch (slender nose)
    filters.append(CustomBulgeFilter("Nose Pinch", [
        BulgePoint(0.5, 0.5, 0.08, -0.6)
    ]))
    
    # 9. Quad Bulge (four corners)
    filters.append(CustomBulgeFilter("Quad Bulge", [
        BulgePoint(0.25, 0.25, 0.15, 0.6),
        BulgePoint(0.75, 0.25, 0.15, 0.6),
        BulgePoint(0.25, 0.75, 0.15, 0.6),
        BulgePoint(0.75, 0.75, 0.15, 0.6)
    ]))
    
    # 10. Vertical Stretch (top/bottom bulge)
    filters.append(CustomBulgeFilter("Vertical Stretch", [
        BulgePoint(0.5, 0.15, 0.25, 0.65),
        BulgePoint(0.5, 0.85, 0.25, 0.65)
    ]))
    
    # 11. Horizontal Squeeze (sides pinch)
    filters.append(CustomBulgeFilter("Horizontal Squeeze", [
        BulgePoint(0.15, 0.5, 0.2, -0.6),
        BulgePoint(0.85, 0.5, 0.2, -0.6)
    ]))
    
    # 12. Circular Wave (ring pattern)
    circle_points = []
    for i in range(8):
        angle = (i / 8) * 2 * math.pi
        x = 0.5 + 0.35 * math.cos(angle)
        y = 0.5 + 0.35 * math.sin(angle)
        circle_points.append(BulgePoint(x, y, 0.1, 0.5))
    filters.append(CustomBulgeFilter("Circular Wave", circle_points))
    
    # 13. Spiral Distortion (spiral pattern)
    spiral_points = []
    for i in range(6):
        angle = (i / 6) * 2 * math.pi
        radius = 0.15 + (i / 12)
        x = 0.5 + radius * math.cos(angle)
        y = 0.5 + radius * math.sin(angle)
        spiral_points.append(BulgePoint(x, y, 0.12, 0.55))
    filters.append(CustomBulgeFilter("Spiral Distortion", spiral_points))
    
    # 14. Diamond Pattern (diamond shape)
    filters.append(CustomBulgeFilter("Diamond Pattern", [
        BulgePoint(0.5, 0.2, 0.15, 0.65),
        BulgePoint(0.2, 0.5, 0.15, 0.65),
        BulgePoint(0.8, 0.5, 0.15, 0.65),
        BulgePoint(0.5, 0.8, 0.15, 0.65)
    ]))
    
    # 15. Grid 3x3 (uniform grid)
    grid_points = []
    for row in range(3):
        for col in range(3):
            x = 0.25 + col * 0.25
            y = 0.25 + row * 0.25
            grid_points.append(BulgePoint(x, y, 0.1, 0.45))
    filters.append(CustomBulgeFilter("Grid 3x3", grid_points))
    
    # 16. Asymmetric Face (unbalanced)
    filters.append(CustomBulgeFilter("Asymmetric Face", [
        BulgePoint(0.3, 0.35, 0.15, 0.8),
        BulgePoint(0.7, 0.45, 0.12, -0.6),
        BulgePoint(0.4, 0.65, 0.1, 0.5)
    ]))
    
    # 17. Triple Eye (three eyes)
    filters.append(CustomBulgeFilter("Triple Eye", [
        BulgePoint(0.3, 0.4, 0.12, 0.75),
        BulgePoint(0.5, 0.35, 0.12, 0.75),
        BulgePoint(0.7, 0.4, 0.12, 0.75)
    ]))
    
    # 18. Bug Eyes Wide (wide-set eyes)
    filters.append(CustomBulgeFilter("Bug Eyes Wide", [
        BulgePoint(0.2, 0.4, 0.15, 0.9),
        BulgePoint(0.8, 0.4, 0.15, 0.9)
    ]))
    
    # 19. Cartoon Smile (bulge around mouth)
    filters.append(CustomBulgeFilter("Cartoon Smile", [
        BulgePoint(0.5, 0.65, 0.2, 0.6),
        BulgePoint(0.35, 0.6, 0.1, 0.4),
        BulgePoint(0.65, 0.6, 0.1, 0.4)
    ]))
    
    # 20. Extreme Fisheye (very large center)
    filters.append(CustomBulgeFilter("Extreme Fisheye", [
        BulgePoint(0.5, 0.5, 0.45, 0.85)
    ]))
    
    # 21. Pinched Corners (all corners pinched)
    filters.append(CustomBulgeFilter("Pinched Corners", [
        BulgePoint(0.15, 0.15, 0.12, -0.7),
        BulgePoint(0.85, 0.15, 0.12, -0.7),
        BulgePoint(0.15, 0.85, 0.12, -0.7),
        BulgePoint(0.85, 0.85, 0.12, -0.7)
    ]))
    
    # 22. Wave Left-Right (alternating bulge/pinch)
    filters.append(CustomBulgeFilter("Wave Left-Right", [
        BulgePoint(0.2, 0.5, 0.18, 0.7),
        BulgePoint(0.5, 0.5, 0.18, -0.7),
        BulgePoint(0.8, 0.5, 0.18, 0.7)
    ]))
    
    # 23. Ripple Effect (concentric circles)
    filters.append(CustomBulgeFilter("Ripple Effect", [
        BulgePoint(0.5, 0.5, 0.15, 0.8),
        BulgePoint(0.5, 0.5, 0.25, -0.4),
        BulgePoint(0.5, 0.5, 0.35, 0.3)
    ]))
    
    # 24. Subtle Eye Enhance (realistic enhancement)
    filters.append(CustomBulgeFilter("Subtle Eye Enhance", [
        BulgePoint(0.35, 0.4, 0.1, 0.35),
        BulgePoint(0.65, 0.4, 0.1, 0.35)
    ]))
    
    # 25. Dramatic Center Pull (strong center pinch)
    filters.append(CustomBulgeFilter("Dramatic Center Pull", [
        BulgePoint(0.5, 0.5, 0.3, -0.85)
    ]))
    
    # 26. Upper Face Bulge (forehead and eyes)
    filters.append(CustomBulgeFilter("Upper Face Bulge", [
        BulgePoint(0.5, 0.25, 0.18, 0.6),
        BulgePoint(0.35, 0.4, 0.12, 0.7),
        BulgePoint(0.65, 0.4, 0.12, 0.7)
    ]))
    
    # 27. Lower Face Squeeze (chin area pinch)
    filters.append(CustomBulgeFilter("Lower Face Squeeze", [
        BulgePoint(0.5, 0.7, 0.2, -0.65),
        BulgePoint(0.35, 0.65, 0.12, -0.4),
        BulgePoint(0.65, 0.65, 0.12, -0.4)
    ]))
    
    # 28. Random Chaos (random placements)
    import random
    random.seed(42)
    chaos_points = []
    for _ in range(7):
        chaos_points.append(BulgePoint(
            random.uniform(0.2, 0.8),
            random.uniform(0.2, 0.8),
            random.uniform(0.08, 0.15),
            random.uniform(-0.6, 0.8)
        ))
    filters.append(CustomBulgeFilter("Random Chaos", chaos_points))
    
    # 29. Hourglass Figure (middle pinch)
    filters.append(CustomBulgeFilter("Hourglass Figure", [
        BulgePoint(0.5, 0.5, 0.15, -0.7),
        BulgePoint(0.5, 0.25, 0.2, 0.5),
        BulgePoint(0.5, 0.75, 0.2, 0.5)
    ]))
    
    # 30. Split Personality (left vs right)
    filters.append(CustomBulgeFilter("Split Personality", [
        BulgePoint(0.25, 0.35, 0.18, 0.75),
        BulgePoint(0.25, 0.65, 0.18, 0.75),
        BulgePoint(0.75, 0.35, 0.18, -0.75),
        BulgePoint(0.75, 0.65, 0.18, -0.75)
    ]))
    
    # 31. Tunnel Vision (center bulge, edge pinch)
    filters.append(CustomBulgeFilter("Tunnel Vision", [
        BulgePoint(0.5, 0.5, 0.2, 0.8),
        BulgePoint(0.5, 0.5, 0.4, -0.5)
    ]))
    
    # 32. Cross Pattern (+ shape)
    filters.append(CustomBulgeFilter("Cross Pattern", [
        BulgePoint(0.5, 0.3, 0.12, 0.6),
        BulgePoint(0.3, 0.5, 0.12, 0.6),
        BulgePoint(0.7, 0.5, 0.12, 0.6),
        BulgePoint(0.5, 0.7, 0.12, 0.6)
    ]))
    
    # 33. X Pattern (diagonal)
    filters.append(CustomBulgeFilter("X Pattern", [
        BulgePoint(0.3, 0.3, 0.12, 0.65),
        BulgePoint(0.7, 0.3, 0.12, 0.65),
        BulgePoint(0.3, 0.7, 0.12, 0.65),
        BulgePoint(0.7, 0.7, 0.12, 0.65)
    ]))
    
    # 34. Star Burst (5-point star)
    star_points = []
    for i in range(5):
        angle = (i / 5) * 2 * math.pi - math.pi / 2
        x = 0.5 + 0.3 * math.cos(angle)
        y = 0.5 + 0.3 * math.sin(angle)
        star_points.append(BulgePoint(x, y, 0.12, 0.65))
    filters.append(CustomBulgeFilter("Star Burst", star_points))
    
    # 35. Hexagon (6 points)
    hex_points = []
    for i in range(6):
        angle = (i / 6) * 2 * math.pi
        x = 0.5 + 0.3 * math.cos(angle)
        y = 0.5 + 0.3 * math.sin(angle)
        hex_points.append(BulgePoint(x, y, 0.11, 0.55))
    filters.append(CustomBulgeFilter("Hexagon", hex_points))
    
    # 36. Tiny Eyes (small bulges)
    filters.append(CustomBulgeFilter("Tiny Eyes", [
        BulgePoint(0.4, 0.4, 0.08, 0.9),
        BulgePoint(0.6, 0.4, 0.08, 0.9)
    ]))
    
    # 37. Giant Nose (center prominence)
    filters.append(CustomBulgeFilter("Giant Nose", [
        BulgePoint(0.5, 0.5, 0.15, 0.85)
    ]))
    
    # 38. Elf Ears (side bulges)
    filters.append(CustomBulgeFilter("Elf Ears", [
        BulgePoint(0.1, 0.4, 0.12, 0.7),
        BulgePoint(0.9, 0.4, 0.12, 0.7)
    ]))
    
    # 39. Gradient Bulge (increasing strength)
    filters.append(CustomBulgeFilter("Gradient Bulge", [
        BulgePoint(0.5, 0.2, 0.12, 0.3),
        BulgePoint(0.5, 0.4, 0.12, 0.5),
        BulgePoint(0.5, 0.6, 0.12, 0.7),
        BulgePoint(0.5, 0.8, 0.12, 0.9)
    ]))
    
    # 40. Kaleidoscope (symmetrical complex)
    filters.append(CustomBulgeFilter("Kaleidoscope", [
        BulgePoint(0.5, 0.3, 0.1, 0.6),
        BulgePoint(0.35, 0.5, 0.1, -0.5),
        BulgePoint(0.65, 0.5, 0.1, -0.5),
        BulgePoint(0.5, 0.7, 0.1, 0.6),
        BulgePoint(0.3, 0.3, 0.08, 0.4),
        BulgePoint(0.7, 0.3, 0.08, 0.4),
        BulgePoint(0.3, 0.7, 0.08, 0.4),
        BulgePoint(0.7, 0.7, 0.08, 0.4)
    ]))
    
    # 41. Dual Fisheye (two fish eyes)
    filters.append(CustomBulgeFilter("Dual Fisheye", [
        BulgePoint(0.3, 0.5, 0.25, 0.75),
        BulgePoint(0.7, 0.5, 0.25, 0.75)
    ]))
    
    # 42. Portal Effect (center pull with ring)
    filters.append(CustomBulgeFilter("Portal Effect", [
        BulgePoint(0.5, 0.5, 0.15, -0.9),
        BulgePoint(0.5, 0.5, 0.28, 0.6)
    ]))
    
    return filters

def save_filters(filters: List[CustomBulgeFilter], output_path: str):
    """Save filters in WesWorld FX export format"""
    export_data = {
        "version": "1.0",
        "appName": "WesWorld FX",
        "exportDate": datetime.now().isoformat() + "Z",
        "filters": [f.to_dict() for f in filters]
    }
    
    with open(output_path, 'w', encoding='utf-8') as f:
        json.dump(export_data, f, indent=2)
    
    print(f"✅ Generated {len(filters)} bulge effects")
    print(f"📁 Saved to: {output_path}")
    
    # Print summary
    print("\n📊 Filter Summary:")
    for i, f in enumerate(filters, 1):
        print(f"  {i}. {f.name} ({len(f.points)} points)")

def main():
    filters = generate_bulge_effects()
    output_path = "42_bulge_effects.wwfxbulge"
    save_filters(filters, output_path)

if __name__ == "__main__":
    main()
