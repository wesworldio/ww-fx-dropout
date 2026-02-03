# GitHub Releases Guide

This guide explains how to create and manage GitHub releases for the WesWorld FX Desktop app.

## Automated Releases with GitHub Actions

The project uses GitHub Actions to automatically build and publish releases for all platforms.

### Creating a New Release

#### Option 1: Using the Release Script (Recommended)

**macOS/Linux:**
```bash
./scripts/create-release.sh
```

**Windows:**
```cmd
scripts\create-release.bat
```

The script will:
1. Prompt you for the new version number (e.g., 1.0.1, 1.1.0, 2.0.0)
2. Update `package.json` with the new version
3. Commit the version change
4. Create a git tag (e.g., `v1.0.1`)
5. Push the tag to GitHub
6. Trigger the automated build and release workflow

#### Option 2: Manual Tag Creation

```bash
# Update version in package.json
npm version 1.0.1 --no-git-tag-version

# Commit the change
git add package.json package-lock.json
git commit -m "Release v1.0.1"

# Create and push tag
git tag -a v1.0.1 -m "Release v1.0.1"
git push origin main
git push origin v1.0.1
```

### What Gets Built

When you push a version tag (e.g., `v1.0.1`), GitHub Actions automatically builds:

**macOS:**
- Intel Mac DMG: `WesWorld-FX-1.0.1-mac-intel.dmg`
- Apple Silicon DMG: `WesWorld-FX-1.0.1-mac-arm64.dmg`
- Intel Mac ZIP: `WesWorld-FX-1.0.1-mac-intel.zip`
- Apple Silicon ZIP: `WesWorld-FX-1.0.1-mac-arm64.zip`

**Windows:**
- x64 Installer: `WesWorld-FX-Setup-1.0.1-win-x64.exe`
- x64 Portable: `WesWorld-FX-1.0.1-win-x64-portable.exe`
- x86 Installer: `WesWorld-FX-Setup-1.0.1-win-ia32.exe`

**Linux:**
- AppImage: `WesWorld-FX-1.0.1-linux.AppImage`
- DEB Package: `wesworld-fx-desktop-1.0.1-linux-amd64.deb`

### Monitoring the Build

1. After pushing the tag, go to your repository's Actions tab:
   ```
   https://github.com/YOUR_USERNAME/ww-fx-1/actions
   ```

2. You'll see the "Build and Release Desktop App" workflow running

3. The workflow has 4 jobs that run in parallel:
   - Create Release
   - Build macOS
   - Build Windows  
   - Build Linux

4. Build time is typically 10-20 minutes total

### Finding Your Releases

Once the build completes, releases are available at:
```
https://github.com/YOUR_USERNAME/ww-fx-1/releases
```

Users can download installers directly from there.

## Version Numbering

Follow [Semantic Versioning](https://semver.org/):

- **MAJOR** version (1.x.x): Incompatible API changes
- **MINOR** version (x.1.x): New features, backwards compatible
- **PATCH** version (x.x.1): Bug fixes, backwards compatible

Examples:
- `1.0.0` - Initial release
- `1.0.1` - Bug fix release
- `1.1.0` - New features added
- `2.0.0` - Major changes/breaking changes

## Manual Builds (Without GitHub Actions)

If you want to build locally without GitHub Actions:

### Build for Current Platform
```bash
npm run build
```

### Build for macOS Only
```bash
npm run build:mac
```

### Build for Windows Only
```bash
npm run build:win
```

### Build for All Platforms (macOS only)
```bash
npm run build:all
```

Built installers will be in the `dist/` folder.

## Testing Before Release

Always test builds before creating a release:

1. **Update version locally** (don't commit yet):
   ```bash
   npm version 1.0.1 --no-git-tag-version
   ```

2. **Build and test**:
   ```bash
   npm run build
   ```

3. **Test the installer**:
   - Install the app from `dist/`
   - Test all features
   - Check performance
   - Verify camera access

4. **If everything works**, create the release:
   ```bash
   ./scripts/create-release.sh
   ```

5. **If issues found**, fix them and repeat

## Pre-release / Beta Versions

To create a pre-release (beta) version:

1. **Use pre-release version number**:
   ```bash
   npm version 1.1.0-beta.1 --no-git-tag-version
   ```

2. **Create tag**:
   ```bash
   git add package.json
   git commit -m "Release v1.1.0-beta.1"
   git tag -a v1.1.0-beta.1 -m "Beta release v1.1.0-beta.1"
   git push origin main
   git push origin v1.1.0-beta.1
   ```

3. **Mark as pre-release in GitHub**:
   - Edit the release on GitHub
   - Check "This is a pre-release"

## Troubleshooting

### Build Fails on GitHub Actions

**Check the logs:**
1. Go to Actions tab
2. Click on the failed workflow
3. Click on the failed job
4. Review error messages

**Common issues:**
- Missing dependencies: Update `package.json`
- File not found: Check `package.json` build config
- Permission errors: Check file paths and permissions

### Tag Already Exists

If you try to create a tag that already exists:

```bash
# Delete local tag
git tag -d v1.0.1

# Delete remote tag
git push origin :refs/tags/v1.0.1

# Create new tag
git tag -a v1.0.1 -m "Release v1.0.1"
git push origin v1.0.1
```

### Release Not Triggering

**Check:**
1. Tag format is correct: `v1.0.1` (with 'v' prefix)
2. Tag was pushed to GitHub: `git push origin v1.0.1`
3. Workflow file exists: `.github/workflows/release-desktop.yml`
4. Actions are enabled in repository settings

## Distribution

### Direct Links

Share direct download links:
```
https://github.com/YOUR_USERNAME/ww-fx-1/releases/download/v1.0.1/WesWorld-FX-1.0.1-mac-intel.dmg
```

### Latest Release Badge

Add to README:
```markdown
[![Latest Release](https://img.shields.io/github/v/release/YOUR_USERNAME/ww-fx-1)](https://github.com/YOUR_USERNAME/ww-fx-1/releases/latest)
```

### Update Notifications

Consider implementing auto-update checking in the app using [electron-updater](https://www.electron.build/auto-update).

## Best Practices

1. **Test locally first** - Always build and test before releasing
2. **Write release notes** - Document changes, new features, bug fixes
3. **Version consistently** - Follow semantic versioning
4. **Tag meaningful commits** - Don't tag work-in-progress
5. **Keep changelog** - Update CHANGELOG.md with each release
6. **Announce releases** - Share on social media, Discord, etc.

## Release Checklist

- [ ] All features tested locally
- [ ] Version number updated
- [ ] CHANGELOG.md updated
- [ ] Documentation updated
- [ ] Build tested locally
- [ ] Tag created and pushed
- [ ] GitHub Actions build successful
- [ ] All installers downloaded and tested
- [ ] Release notes written
- [ ] Release announced

## Support

For issues with releases or builds:
1. Check GitHub Actions logs
2. Review this documentation
3. Check [electron-builder docs](https://www.electron.build/)
4. Open an issue on GitHub
