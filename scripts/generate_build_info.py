#!/usr/bin/env python3
"""
Generate build-info.json from git commit information.
This file contains build number, commit hash, and commit timestamp.
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

def generate_build_info():
    """Generate build-info.json file."""
    repo_root = Path(__file__).parent.parent
    output_file = repo_root / 'build-info.json'
    
    build_info = {
        'buildNumber': get_git_commit_count(),
        'buildTimestamp': get_git_commit_time(),
        'commitHash': get_git_commit_hash(),
        'commitTime': get_git_commit_time()
    }
    
    with open(output_file, 'w') as f:
        json.dump(build_info, f, indent=2)
    
    print(f"Generated build-info.json:")
    print(f"  Build Number: {build_info['buildNumber']}")
    print(f"  Commit Hash: {build_info['commitHash']}")
    print(f"  Commit Time: {datetime.fromtimestamp(build_info['commitTime'] / 1000).isoformat()}")
    
    return build_info

if __name__ == '__main__':
    try:
        generate_build_info()
        sys.exit(0)
    except Exception as e:
        print(f"Error generating build-info.json: {e}", file=sys.stderr)
        sys.exit(1)

