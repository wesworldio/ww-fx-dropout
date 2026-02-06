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

setup-hooks:
	@echo "Setting up git hooks to auto-update build-info.json..."
	@bash scripts/setup_git_hooks.sh

# macOS Native Build Commands (Primary Target)
setup:
	@echo "Setting up macOS Native app..."
	@cd $(NATIVE_DIR) && $(MAKE) setup

build:
	@echo "Building macOS Native app (Debug)..."
	@cd $(NATIVE_DIR) && $(MAKE) build

release:
	@echo "Incrementing version and build number..."
	@$(PYTHON) scripts/increment_version.py
	@echo "Building macOS Native app (Release)..."
	@cd $(NATIVE_DIR) && $(MAKE) release

run:
	@echo "Incrementing build number..."
	@$(PYTHON) scripts/increment_build.py
	@echo "Running macOS Native app..."
	@cd $(NATIVE_DIR) && $(MAKE) run

xcode:
	@echo "Opening macOS Native app in Xcode..."
	@cd $(NATIVE_DIR) && $(MAKE) xcode

clean:
	@echo "Cleaning all build artifacts..."
	@cd $(NATIVE_DIR) && $(MAKE) clean
	@echo "✅ All build artifacts cleaned"
