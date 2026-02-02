#!/usr/bin/env python3
"""
Update build info in both build-info.json and index.html EMBEDDED_BUILD_INFO.
Run this script before committing to ensure build info is up to date.
"""

import json
import re
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

def update_build_info_json():
    """Update build-info.json file."""
    repo_root = Path(__file__).parent.parent
    output_file = repo_root / 'build-info.json'
    
    # Use current time since this runs during pre-commit (before the new commit is created)
    current_time = int(datetime.now().timestamp() * 1000)
    
    build_info = {
        'buildNumber': get_git_commit_count() + 1,  # +1 because this will be the next commit
        'buildTimestamp': current_time,
        'commitHash': get_git_commit_hash(),
        'commitTime': current_time
    }
    
    with open(output_file, 'w') as f:
        json.dump(build_info, f, indent=2)
    
    print(f"✓ Updated build-info.json:")
    print(f"  Build Number: {build_info['buildNumber']}")
    print(f"  Commit Hash: {build_info['commitHash']}")
    print(f"  Commit Time: {datetime.fromtimestamp(build_info['commitTime'] / 1000).isoformat()}")
    
    return build_info

def update_embedded_build_info(build_info):
    """Update EMBEDDED_BUILD_INFO constant in index.html."""
    repo_root = Path(__file__).parent.parent
    index_file = repo_root / 'index.html'
    
    if not index_file.exists():
        print(f"Warning: {index_file} not found", file=sys.stderr)
        return False
    
    # Read the file
    with open(index_file, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Pattern to match EMBEDDED_BUILD_INFO constant
    pattern = r'(const EMBEDDED_BUILD_INFO = \{[\s\S]*?\})'
    
    # New embedded build info
    new_embedded = f'''const EMBEDDED_BUILD_INFO = {{
            "buildNumber": {build_info['buildNumber']},
            "buildTimestamp": {build_info['buildTimestamp']},
            "commitHash": "{build_info['commitHash']}",
            "commitTime": {build_info['commitTime']}
        }}'''
    
    # Replace the old embedded build info
    new_content, count = re.subn(pattern, new_embedded, content)
    
    if count == 0:
        print("Warning: Could not find EMBEDDED_BUILD_INFO in index.html", file=sys.stderr)
        return False
    
    # Write back
    with open(index_file, 'w', encoding='utf-8') as f:
        f.write(new_content)
    
    print(f"✓ Updated EMBEDDED_BUILD_INFO in index.html")
    return True

def main():
    """Main function."""
    try:
        # Update build-info.json
        build_info = update_build_info_json()
        
        # Update embedded build info in index.html
        update_embedded_build_info(build_info)
        
        print("\n✅ Build info updated successfully!")
        print("Files updated: build-info.json, index.html")
        return 0
        
    except Exception as e:
        print(f"\n❌ Error updating build info: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        return 1

if __name__ == '__main__':
    sys.exit(main())
