# Remove app, containers, and reset camera permissions for a fresh install
full-clean:
	@echo "Removing WesWorld FX app from /Applications..."
	rm -rf /Applications/WesWorldFX.app
	@echo "Removing WesWorld FX app from ~/Applications..."
	rm -rf ~/Applications/WesWorldFX.app
	@echo "Removing WesWorld FX container data..."
	rm -rf ~/Library/Containers/io.wesworld.fx.native
	rm -rf ~/Library/Application\ Support/io.wesworld.fx.native
	rm -rf ~/Library/Preferences/io.wesworld.fx.native.plist
	@echo "Resetting camera permissions (requires sudo)..."
	sudo tccutil reset Camera io.wesworld.fx.native || true
	@echo "Full clean complete. Reinstall the app and launch to trigger camera prompt."
.PHONY: help build clean run setup release xcode build-info setup-hooks

PYTHON = python3
NATIVE_DIR = macos-native

help:
	@echo "WesWorld FX - macOS Native Build System"
	@echo ""
	@echo "Main Commands:"
	@echo "  make setup           - Initial setup (create Xcode project)"
	@echo "  make build           - Build debug version of native app"
	@echo "  make release         - Build release version of native app"
	@echo "  make run             - Build and run the native app"
	@echo "  make xcode           - Open native app in Xcode"
	@echo "  make clean           - Clean all build artifacts"
	@echo ""
	@echo "Utilities:"
	@echo "  make build-info      - Generate build-info.json from git"
	@echo "  make setup-hooks     - Install git hooks to auto-update build-info.json"
	@echo ""
	@echo "Target: macOS Native App (Metal GPU Acceleration, 60+ FPS)"
	@echo "Docs: macos-native/README.md"

build-info:
	@echo "Generating build-info.json from git..."
	@$(PYTHON) scripts/generate_build_info.py
	@bash scripts/copy_build_info.sh

setup-hooks:
	@echo "Setting up git hooks to auto-update build-info.json..."
	@bash scripts/setup_git_hooks.sh

# macOS Native Build Commands (Primary Target)
setup:
	@echo "Setting up macOS Native app..."
	@cd $(NATIVE_DIR) && $(MAKE) setup

build:
	@echo "Copying latest build-info.json to Resources..."
	@bash scripts/copy_build_info.sh
	@echo "Building macOS Native app (Debug)..."
	@cd $(NATIVE_DIR) && $(MAKE) build

release:
	@echo "Incrementing version and build number..."
	@$(PYTHON) scripts/increment_version.py
	@bash scripts/copy_build_info.sh
	@echo "Updating Info.plist version/build..."
	@$(PYTHON) scripts/update_info_plist.py
	@echo "Building macOS Native app (Release)..."
	@cd $(NATIVE_DIR) && $(MAKE) release
	@echo "Creating DMG installer..."
	@cd $(NATIVE_DIR) && bash create-dmg.sh
	@echo "Uploading DMG to GitHub release..."
	@latest_ver=$(shell $(PYTHON) -c "import json; print(json.load(open('macos-native/WesWorldFX/Resources/build-info.json'))['version'])") && \
	  gh release create v$$latest_ver ./releases/WesWorld-FX-$$latest_ver-mac-arm64.dmg --title "WesWorld FX $$latest_ver" --notes "Release $$latest_ver: See CHANGELOG.md for details." || \
	  gh release upload v$$latest_ver ./releases/WesWorld-FX-$$latest_ver-mac-arm64.dmg --clobber

run:
	@echo "Incrementing build number..."
	@$(PYTHON) scripts/increment_build.py
	@bash scripts/copy_build_info.sh
	@echo "Running macOS Native app..."
	@cd $(NATIVE_DIR) && $(MAKE) run

xcode:
	@echo "Opening macOS Native app in Xcode..."
	@cd $(NATIVE_DIR) && $(MAKE) xcode

clean:
	@echo "Cleaning all build artifacts..."
	@cd $(NATIVE_DIR) && $(MAKE) clean
	@echo "✅ All build artifacts cleaned"
