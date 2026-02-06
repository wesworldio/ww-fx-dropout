#!/usr/bin/env python3
"""
Increment the version number in build-info.json.
Also increments the build number.
Uses semantic versioning (major.minor.patch).
"""

import json
import subprocess
import sys
from datetime import datetime
from pathlib import Path


def get_git_commit_hash():
    """Get the latest commit hash (short)."""
    try:
        result = subprocess.run(
            ['git', 'rev-parse', '--short', 'HEAD'],
            capture_output=True,
            text=True,
            check=True
        )
        return result.stdout.strip()
    except (subprocess.CalledProcessError, FileNotFoundError):
        return 'unknown'


def get_git_commit_time():
    """Get the latest commit timestamp in milliseconds since epoch."""
    try:
        result = subprocess.run(
            ['git', 'log', '-1', '--format=%ct'],
            capture_output=True,
            text=True,
            check=True
        )
        timestamp_seconds = int(result.stdout.strip())
        return timestamp_seconds * 1000
    except (subprocess.CalledProcessError, FileNotFoundError, ValueError):
        return int(datetime.now().timestamp() * 1000)


def increment_patch_version(version_str):
    """Increment the patch version (x.y.z -> x.y.z+1)."""
    try:
        parts = version_str.split('.')
        if len(parts) != 3:
            raise ValueError(f"Invalid version format: {version_str}")
        
        major, minor, patch = int(parts[0]), int(parts[1]), int(parts[2])
        patch += 1
        return f"{major}.{minor}.{patch}"
    except (ValueError, IndexError):
        raise ValueError(f"Invalid version format: {version_str}")


def increment_version():
    """Increment version and build number in build-info.json."""
    repo_root = Path(__file__).parent.parent
    build_file = repo_root / 'build-info.json'
    
    # Load existing build info or create new
    if build_file.exists():
        with open(build_file, 'r') as f:
            build_info = json.load(f)
    else:
        build_info = {
            'version': '0.0.1',
            'buildNumber': 0,
            'buildTimestamp': 0,
            'commitHash': 'unknown',
            'commitTime': 0
        }
    
    # Increment version
    old_version = build_info.get('version', '0.0.1')
    new_version = increment_patch_version(old_version)
    
    # Increment build number
    old_build = build_info.get('buildNumber', 0)
    new_build = old_build + 1
    
    # Update build info
    build_info['version'] = new_version
    build_info['buildNumber'] = new_build
    build_info['buildTimestamp'] = int(datetime.now().timestamp() * 1000)
    build_info['commitHash'] = get_git_commit_hash()
    build_info['commitTime'] = get_git_commit_time()
    
    # Save updated build info
    with open(build_file, 'w') as f:
        json.dump(build_info, f, indent=2)
    
    print(f"✓ Version incremented: {old_version} → {new_version}")
    print(f"✓ Build number incremented: {old_build} → {new_build}")
    print(f"  Commit: {build_info['commitHash']}")
    
    return build_info


if __name__ == '__main__':
    try:
        increment_version()
        sys.exit(0)
    except Exception as e:
        print(f"Error incrementing version: {e}", file=sys.stderr)
        sys.exit(1)
