#!/usr/bin/env python3
"""
Increment the build number in build-info.json.
Preserves version number and other metadata.
"""

import json
import plistlib
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


def get_app_version(repo_root: Path) -> str:
    """Get app version from macOS Info.plist if available."""
    info_plist = repo_root / 'macos-native' / 'WesWorldFX' / 'Resources' / 'Info.plist'
    if not info_plist.exists():
        return ''
    try:
        with open(info_plist, 'rb') as f:
            plist = plistlib.load(f)
        return str(plist.get('CFBundleShortVersionString', '')).strip()
    except (OSError, plistlib.InvalidFileException):
        return ''


def increment_build():
    """Increment build number in build-info.json."""
    repo_root = Path(__file__).parent.parent
    build_file = repo_root / 'build-info.json'
    
    # Load existing build info or create new
    if build_file.exists():
        with open(build_file, 'r', encoding='utf-8') as f:
            build_info = json.load(f)
    else:
        build_info = {
            'version': '0.0.1',
            'buildNumber': 0,
            'buildTimestamp': 0,
            'commitHash': 'unknown',
            'commitTime': 0
        }
    
    # Ensure version is present
    if not build_info.get('version'):
        version = get_app_version(repo_root)
        if version:
            build_info['version'] = version

    # Increment build number
    old_build = build_info.get('buildNumber', 0)
    build_info['buildNumber'] = old_build + 1
    build_info['buildTimestamp'] = int(datetime.now().timestamp() * 1000)
    build_info['commitHash'] = get_git_commit_hash()
    build_info['commitTime'] = get_git_commit_time()
    
    # Save updated build info
    with open(build_file, 'w', encoding='utf-8') as f:
        json.dump(build_info, f, indent=2)
    
    print(f"✓ Build number incremented: {old_build} → {build_info['buildNumber']}")
    print(f"  Version: {build_info.get('version', 'N/A')}")
    print(f"  Commit: {build_info['commitHash']}")
    
    return build_info


if __name__ == '__main__':
    try:
        increment_build()
        sys.exit(0)
    except (OSError, json.JSONDecodeError) as e:
        print(f"Error incrementing build: {e}", file=sys.stderr)
        sys.exit(1)
