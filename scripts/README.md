# Build Info Automation

This directory contains scripts for automatically updating build information on each commit.

## Quick Setup

Run this once to enable automatic build info updates:

```bash
./scripts/setup_git_hooks.sh
```

## What Gets Updated Automatically

On every commit, the following files are automatically updated:

1. **build-info.json** - Contains:
   - `buildNumber` - Total number of commits
   - `buildTimestamp` - Current timestamp
   - `commitHash` - Current commit hash (short)
   - `commitTime` - Commit timestamp

2. **index.html** - The `EMBEDDED_BUILD_INFO` constant is updated to match build-info.json

## Manual Update

If you need to manually update build info without committing:

```bash
python3 scripts/update_build_info.py
```

## Scripts

- **update_build_info.py** - Updates both build-info.json and index.html
- **generate_build_info.py** - Updates only build-info.json (legacy)
- **pre-commit-hook** - Git pre-commit hook that runs update_build_info.py
- **setup_git_hooks.sh** - Installs the pre-commit hook

## How It Works

1. You make changes and run `git commit`
2. The pre-commit hook runs automatically
3. Build info is updated based on current git state
4. Updated files are added to the commit
5. Commit proceeds normally

## Verification

After committing, check the settings UI in the app:
- **Build number** should increment with each commit
- **Last Update** should show "X seconds/minutes ago"

## Disabling

To temporarily disable automatic updates:

```bash
rm .git/hooks/pre-commit
```

To re-enable, run `./scripts/setup_git_hooks.sh` again.
