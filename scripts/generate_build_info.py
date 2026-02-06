#!/usr/bin/env python3
"""
Generate build-info.json from git commit information.
This file contains build number, commit hash, and commit timestamp.
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
        return timestamp_seconds * 1000  # Convert to milliseconds
    except (subprocess.CalledProcessError, FileNotFoundError, ValueError):
        return int(datetime.now().timestamp() * 1000)

def get_git_commit_count():
    """Get the total number of commits (for build number)."""
    try:
        result = subprocess.run(
            ['git', 'rev-list', '--count', 'HEAD'],
            capture_output=True,
            text=True,
            check=True
        )
        return int(result.stdout.strip())
    except (subprocess.CalledProcessError, FileNotFoundError, ValueError):
        return 0


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

def generate_build_info():
    """Generate build-info.json file."""
    repo_root = Path(__file__).parent.parent
    output_file = repo_root / 'build-info.json'

    version = get_app_version(repo_root)
    
    build_info = {
        'version': version or '0.0.0',
        'buildNumber': get_git_commit_count(),
        'buildTimestamp': get_git_commit_time(),
        'commitHash': get_git_commit_hash(),
        'commitTime': get_git_commit_time()
    }
    
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(build_info, f, indent=2)
    
    print("Generated build-info.json:")
    print(f"  Build Number: {build_info['buildNumber']}")
    print(f"  Commit Hash: {build_info['commitHash']}")
    print(f"  Commit Time: {datetime.fromtimestamp(build_info['commitTime'] / 1000).isoformat()}")
    
    return build_info

if __name__ == '__main__':
    try:
        generate_build_info()
        sys.exit(0)
    except (OSError, json.JSONDecodeError) as e:
        print(f"Error generating build-info.json: {e}", file=sys.stderr)
        sys.exit(1)

