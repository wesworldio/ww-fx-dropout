#!/usr/bin/env python3
"""
update_info_plist.py
Update Info.plist version and build number from build-info.json.
"""
import plistlib
import json
import sys
from pathlib import Path

root = Path(__file__).parent.parent
build_info_path = root / 'macos-native' / 'WesWorldFX' / 'Resources' / 'build-info.json'
plist_path = root / 'macos-native' / 'WesWorldFX' / 'Resources' / 'Info.plist'

with open(build_info_path) as f:
    build_info = json.load(f)

with open(plist_path, 'rb') as f:
    plist = plistlib.load(f)

plist['CFBundleShortVersionString'] = build_info['version']
plist['CFBundleVersion'] = str(build_info['buildNumber'])

with open(plist_path, 'wb') as f:
    plistlib.dump(plist, f)

print(f"Updated Info.plist: version={build_info['version']} build={build_info['buildNumber']}")
