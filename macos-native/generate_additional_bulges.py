#!/usr/bin/env python3
"""
Generate additional bulge effects to expand the FX library
Creates diverse bulge and pinch effects with varied configurations
"""

import json
from datetime import datetime
from uuid import uuid4
import sys


def generate_point(x, y, radius=0.15, strength=0.65):
    """Create a bulge point"""
    return {
        "x": round(x, 2),
        "y": round(y, 2),
        "radius": round(radius, 2),
        "strength": round(strength, 2)
    }


def create_filter(name, points):
    """Create a custom bulge filter"""
    now = datetime.utcnow().isoformat() + "Z"
    return {
        "id": str(uuid4()),
        "name": name,
        "points": points,
        "createdDate": now,
        "modifiedDate": now
    }


def generate_bulges():
    """Generate a collection of diverse bulge effects"""
    effects = []
    
    # Eye Effects (varied styles)
    effects.append(create_filter("Anime Eyes", [
        generate_point(0.35, 0.38, 0.14, 0.85),
        generate_point(0.65, 0.38, 0.14, 0.85),
    ]))
    
    effects.append(create_filter("Sleepy Eyes", [
        generate_point(0.35, 0.42, 0.11, 0.45),
        generate_point(0.65, 0.42, 0.11, 0.45),
    ]))
    
    effects.append(create_filter("Wide Eyed", [
        generate_point(0.35, 0.35, 0.16, 0.75),
        generate_point(0.65, 0.35, 0.16, 0.75),
    ]))
    
    effects.append(create_filter("Surprised", [
        generate_point(0.35, 0.30, 0.18, 0.88),
        generate_point(0.65, 0.30, 0.18, 0.88),
        generate_point(0.5, 0.62, 0.12, -0.6),
    ]))
    
    # Face Shape Effects
    effects.append(create_filter("Round Face", [
        generate_point(0.5, 0.5, 0.35, 0.55),
    ]))
    
    effects.append(create_filter("Heart Shape", [
        generate_point(0.35, 0.35, 0.12, 0.7),
        generate_point(0.65, 0.35, 0.12, 0.7),
        generate_point(0.5, 0.7, 0.15, 0.5),
    ]))
    
    effects.append(create_filter("Diamond Face", [
        generate_point(0.5, 0.25, 0.12, 0.6),
        generate_point(0.5, 0.75, 0.12, 0.6),
        generate_point(0.2, 0.5, 0.1, -0.5),
        generate_point(0.8, 0.5, 0.1, -0.5),
    ]))
    
    effects.append(create_filter("Triangle Down", [
        generate_point(0.35, 0.3, 0.11, 0.65),
        generate_point(0.65, 0.3, 0.11, 0.65),
        generate_point(0.5, 0.75, 0.18, 0.7),
    ]))
    
    # Cheek & Mouth Effects
    effects.append(create_filter("Rosy Cheeks", [
        generate_point(0.25, 0.55, 0.18, 0.7),
        generate_point(0.75, 0.55, 0.18, 0.7),
    ]))
    
    effects.append(create_filter("Hollow Cheeks", [
        generate_point(0.25, 0.55, 0.12, -0.75),
        generate_point(0.75, 0.55, 0.12, -0.75),
    ]))
    
    effects.append(create_filter("Pout", [
        generate_point(0.5, 0.65, 0.14, 0.8),
    ]))
    
    effects.append(create_filter("Big Smile", [
        generate_point(0.35, 0.65, 0.12, 0.6),
        generate_point(0.65, 0.65, 0.12, 0.6),
    ]))
    
    # Nose Effects
    effects.append(create_filter("Bulbous Nose", [
        generate_point(0.5, 0.45, 0.13, 0.75),
    ]))
    
    effects.append(create_filter("Pinched Nose", [
        generate_point(0.5, 0.45, 0.11, -0.65),
    ]))
    
    effects.append(create_filter("Upturned Nose", [
        generate_point(0.5, 0.42, 0.1, 0.55),
        generate_point(0.5, 0.48, 0.08, -0.4),
    ]))
    
    # Multi-point Geometric
    effects.append(create_filter("Four Corners", [
        generate_point(0.25, 0.25, 0.12, 0.6),
        generate_point(0.75, 0.25, 0.12, 0.6),
        generate_point(0.25, 0.75, 0.12, 0.6),
        generate_point(0.75, 0.75, 0.12, 0.6),
    ]))
    
    effects.append(create_filter("Compass", [
        generate_point(0.5, 0.2, 0.12, 0.65),
        generate_point(0.5, 0.8, 0.12, 0.65),
        generate_point(0.2, 0.5, 0.12, 0.65),
        generate_point(0.8, 0.5, 0.12, 0.65),
    ]))
    
    effects.append(create_filter("Pinch Corners", [
        generate_point(0.25, 0.25, 0.12, -0.65),
        generate_point(0.75, 0.25, 0.12, -0.65),
        generate_point(0.25, 0.75, 0.12, -0.65),
        generate_point(0.75, 0.75, 0.12, -0.65),
    ]))
    
    effects.append(create_filter("Triangle Up", [
        generate_point(0.5, 0.2, 0.15, 0.75),
        generate_point(0.25, 0.75, 0.12, -0.4),
        generate_point(0.75, 0.75, 0.12, -0.4),
    ]))
    
    # Contrast Effects
    effects.append(create_filter("Push Out", [
        generate_point(0.5, 0.5, 0.4, 0.8),
    ]))
    
    effects.append(create_filter("Vortex Inward", [
        generate_point(0.5, 0.5, 0.35, -0.8),
    ]))
    
    effects.append(create_filter("Pucker Up", [
        generate_point(0.5, 0.5, 0.25, -0.85),
    ]))
    
    # Double Point Effects
    effects.append(create_filter("Top Bottom", [
        generate_point(0.5, 0.25, 0.18, 0.7),
        generate_point(0.5, 0.75, 0.18, 0.7),
    ]))
    
    effects.append(create_filter("Left Right", [
        generate_point(0.2, 0.5, 0.18, 0.7),
        generate_point(0.8, 0.5, 0.18, 0.7),
    ]))
    
    effects.append(create_filter("Opposing Pressures", [
        generate_point(0.5, 0.25, 0.15, 0.75),
        generate_point(0.5, 0.75, 0.15, -0.75),
    ]))
    
    # Diagonal Effects
    effects.append(create_filter("Diagonal Push", [
        generate_point(0.25, 0.25, 0.15, 0.65),
        generate_point(0.75, 0.75, 0.15, 0.65),
    ]))
    
    effects.append(create_filter("X Forces", [
        generate_point(0.25, 0.25, 0.12, 0.6),
        generate_point(0.75, 0.75, 0.12, 0.6),
        generate_point(0.75, 0.25, 0.12, -0.5),
        generate_point(0.25, 0.75, 0.12, -0.5),
    ]))
    
    # Subtle Effects
    effects.append(create_filter("Gentle Lift", [
        generate_point(0.5, 0.4, 0.25, 0.35),
    ]))
    
    effects.append(create_filter("Soft Pinch", [
        generate_point(0.5, 0.5, 0.2, -0.35),
    ]))
    
    effects.append(create_filter("Minimal Eyes", [
        generate_point(0.35, 0.4, 0.08, 0.5),
        generate_point(0.65, 0.4, 0.08, 0.5),
    ]))
    
    # Extreme Effects
    effects.append(create_filter("Maximum Bulge", [
        generate_point(0.5, 0.5, 0.45, 0.95),
    ]))
    
    effects.append(create_filter("Strong Pinch", [
        generate_point(0.5, 0.5, 0.3, -0.9),
    ]))
    
    effects.append(create_filter("Orbital Bulge", [
        generate_point(0.35, 0.35, 0.15, 0.75),
        generate_point(0.65, 0.35, 0.15, 0.75),
        generate_point(0.35, 0.65, 0.15, 0.75),
        generate_point(0.65, 0.65, 0.15, 0.75),
        generate_point(0.5, 0.5, 0.08, -0.4),
    ]))
    
    return effects


def merge_with_existing(new_filters, existing_path):
    """Load existing filters and add new ones"""
    try:
        with open(existing_path, 'r') as f:
            data = json.load(f)
        existing_names = {f['name'] for f in data['filters']}
        print(f"Found {len(existing_names)} existing filters")
        
        # Only add new filters that don't exist
        new_filters = [f for f in new_filters if f['name'] not in existing_names]
        data['filters'].extend(new_filters)
        return data
    except FileNotFoundError:
        return {
            "version": "1.0",
            "appName": "WesWorld FX",
            "exportDate": datetime.utcnow().isoformat() + "Z",
            "filters": new_filters
        }


def main():
    """Generate and save bulge effects"""
    bulge_path = "/Users/wes/Sites/wesworld/ww-fx-dropout/macos-native/42_bulge_effects.wwfxbulge"
    
    print("🎨 Generating additional bulge effects...")
    new_effects = generate_bulges()
    print(f"✓ Generated {len(new_effects)} new bulge effects")
    
    print(f"📦 Merging with existing effects from {bulge_path}...")
    merged_data = merge_with_existing(new_effects, bulge_path)
    print(f"✓ Total filters after merge: {len(merged_data['filters'])}")
    
    # Update export date
    merged_data['exportDate'] = datetime.utcnow().isoformat() + "Z"
    
    # Save back to file
    with open(bulge_path, 'w') as f:
        json.dump(merged_data, f, indent=2)
    
    print(f"✅ Updated {bulge_path}")
    print(f"📊 Total bulge effects: {len(merged_data['filters'])}")
    
    # Print summary
    print("\n📋 New Bulge Effects Added:")
    for effect in new_effects:
        print(f"  • {effect['name']} ({len(effect['points'])} point{'s' if len(effect['points']) != 1 else ''})")


if __name__ == "__main__":
    main()
