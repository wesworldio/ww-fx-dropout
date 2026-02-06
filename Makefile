.PHONY: help build clean watch daemon daemon-stop daemon-status daemon-logs build-info setup-hooks \
	native-build native-run native-clean native-release native-setup native-xcode \
	all run setup

PYTHON = python3

help:
	@echo "$(GREEN)WesWorld FX - Build Commands$(NC)"
	@echo ""
	@echo "$(YELLOW)Quick Start (Native macOS Metal App):$(NC)"
	@echo "  make run              - Build and run the OSX native Metal version"
	@echo "  make setup            - Initial setup for native app"
	@echo ""
	@echo "$(YELLOW)Web/WASM Commands:$(NC)"
	@echo "  make build            - Build WASM module"
	@echo "  make clean            - Clean WASM artifacts"
	@echo "  make watch            - Watch files and rebuild (foreground)"
	@echo "  make daemon           - Start watcher daemon"
	@echo "  make daemon-stop      - Stop watcher daemon"
	@echo "  make daemon-status    - Check watcher status"
	@echo "  make daemon-logs      - View watcher logs"
	@echo ""
	@echo "$(YELLOW)Native macOS App Commands:$(NC)"
	@echo "  make native-setup     - Create Xcode project for native app"
	@echo "  make native-build     - Build native app (debug)"
	@echo "  make native-run       - Build and run native app"
	@echo "  make native-release   - Build release version"
	@echo "  make native-clean     - Clean native build artifacts"
	@echo "  make native-xcode     - Open Xcode project"
	@echo ""
	@echo "$(YELLOW)Utilities:$(NC)"
	@echo "  make build-info       - Generate build-info.json from git"
	@echo "  make setup-hooks      - Install git hooks"
	@echo ""
	@echo "$(YELLOW)Notes:$(NC)"
	@echo "  • Native app uses Metal GPU acceleration"
	@echo "  • WASM version is web-based"
	@echo "  • Python backend code archived in archive/"

build-info:
	@echo "Generating build-info.json from git..."
	@$(PYTHON) scripts/generate_build_info.py

setup-hooks:
	@echo "Setting up git hooks to auto-update build-info.json..."
	@bash scripts/setup_git_hooks.sh

# Build Commands
build:
	@echo "Building WASM module..."
	@if [ ! -f wasm/build.sh ]; then \
		echo "❌ Error: wasm/build.sh not found"; \
		exit 1; \
	fi
	@chmod +x wasm/build.sh
	@cd wasm && ./build.sh

clean:
	@echo "Cleaning build artifacts..."
	@rm -rf wasm/build 2>/dev/null || true
	@rm -f static/wasm/wwfx_module.js static/wasm/wwfx_module.wasm 2>/dev/null || true
	@echo "✅ Build artifacts cleaned"

watch:
	@echo "Starting file watcher (foreground)..."
	@echo "Watching for changes in wasm/src/, wasm/include/, and wasm/CMakeLists.txt"
	@echo "Press Ctrl+C to stop"
	@$(PYTHON) scripts/watch_wasm.py

daemon:
	@echo "Starting watcher as daemon..."
	@if [ -f /tmp/ww_fx_wasm.pid ]; then \
		PID=$$(cat /tmp/ww_fx_wasm.pid); \
		if ps -p $$PID > /dev/null 2>&1; then \
			echo "⚠️  Watcher already running (PID: $$PID)"; \
			echo "   Stop with: make daemon-stop"; \
			exit 1; \
		fi; \
	fi
	@echo "Building WASM module initially..."
	@$(MAKE) build || true
	@echo "Starting watcher daemon..."
	@nohup $(PYTHON) scripts/watch_wasm.py > /tmp/ww_fx_wasm.log 2>&1 & \
	echo $$! > /tmp/ww_fx_wasm.pid && \
	echo "✅ Watcher started (PID: $$(cat /tmp/ww_fx_wasm.pid))"
	@echo "To view logs: make daemon-logs"
	@echo "To stop: make daemon-stop"

daemon-stop:
	@if [ -f /tmp/ww_fx_wasm.pid ]; then \
		PID=$$(cat /tmp/ww_fx_wasm.pid); \
		if ps -p $$PID > /dev/null 2>&1; then \
			kill $$PID && echo "✅ Stopped watcher (PID: $$PID)"; \
		else \
			echo "⚠️  Process $$PID not found"; \
		fi; \
		rm -f /tmp/ww_fx_wasm.pid; \
	else \
		echo "⚠️  No watcher PID file found"; \
	fi

daemon-status:
	@if [ -f /tmp/ww_fx_wasm.pid ]; then \
		PID=$$(cat /tmp/ww_fx_wasm.pid); \
		if ps -p $$PID > /dev/null 2>&1; then \
			echo "✅ Watcher running (PID: $$PID)"; \
		else \
			echo "⚠️  Watcher not running (PID file exists but process not found)"; \
		fi; \
	else \
		echo "⚠️  Watcher not running"; \
	fi

daemon-logs:
	@if [ -f /tmp/ww_fx_wasm.log ]; then \
		tail -f /tmp/ww_fx_wasm.log; \
	else \
		echo "⚠️  No log file found. Start watcher with: make daemon"; \
	fi

# ============================================================================
# Native macOS Metal App Build Commands
# ============================================================================

MACOS_DIR = macos-native
NATIVE_APP_NAME = WesWorldFX
BUILD_DIR = $(MACOS_DIR)/build
RELEASE_DIR = $(BUILD_DIR)/Build/Products/Release
DEBUG_DIR = $(BUILD_DIR)/Build/Products/Debug
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m

setup: native-setup
	@echo "$(GREEN)✓ Setup complete$(NC)"

run: native-spm-run
	@echo "$(GREEN)✓ App launched$(NC)"

# Setup native Xcode project
native-setup:
	@echo "$(YELLOW)Setting up Native macOS Metal App...$(NC)"
	@cd $(MACOS_DIR) && \
	if [ ! -f "$(NATIVE_APP_NAME).xcodeproj/project.pbxproj" ]; then \
		echo "Creating Xcode project..."; \
		if [ -f "create-xcode-project.sh" ]; then \
			chmod +x create-xcode-project.sh && ./create-xcode-project.sh; \
		else \
			echo "$(RED)❌ create-xcode-project.sh not found$(NC)"; \
			exit 1; \
		fi; \
	else \
		echo "$(GREEN)✓ Xcode project already exists$(NC)"; \
	fi

# Build native debug version
native-build: native-setup
	@echo "$(YELLOW)Building WesWorldFX (Debug)...$(NC)"
	@cd $(MACOS_DIR) && \
	xcodebuild -project $(NATIVE_APP_NAME).xcodeproj \
		-scheme $(NATIVE_APP_NAME) \
		-configuration Debug \
		-derivedDataPath build \
		build 2>&1 | tail -20 || true
	@echo "$(GREEN)✓ Build complete$(NC)"

# Build and run native app
native-run: native-build
	@echo "$(YELLOW)Launching WesWorldFX...$(NC)"
	@if [ -d "$(DEBUG_DIR)/$(NATIVE_APP_NAME).app" ]; then \
		open "$(DEBUG_DIR)/$(NATIVE_APP_NAME).app"; \
		echo "$(GREEN)✓ WesWorldFX launched (Press B to open Custom Bulge Editor)$(NC)"; \
	else \
		echo "$(RED)❌ App not found at $(DEBUG_DIR)/$(NATIVE_APP_NAME).app$(NC)"; \
		exit 1; \
	fi

# Build release version
native-release: native-setup
	@echo "$(YELLOW)Building WesWorldFX (Release)...$(NC)"
	@cd $(MACOS_DIR) && \
	xcodebuild -project $(NATIVE_APP_NAME).xcodeproj \
		-scheme $(NATIVE_APP_NAME) \
		-configuration Release \
		-derivedDataPath build \
		build 2>&1 | tail -20 || true
	@echo "$(GREEN)✓ Release build complete$(NC)"
	@echo "App: $(RELEASE_DIR)/$(NATIVE_APP_NAME).app"

# Clean native build
native-clean:
	@echo "$(YELLOW)Cleaning native build artifacts...$(NC)"
	@rm -rf $(MACOS_DIR)/build
	@rm -rf $(MACOS_DIR)/DerivedData
	@echo "$(GREEN)✓ Clean complete$(NC)"

# Open in Xcode
native-xcode: native-setup
	@if [ -f "$(MACOS_DIR)/$(NATIVE_APP_NAME).xcodeproj/project.pbxproj" ]; then \
		open "$(MACOS_DIR)/$(NATIVE_APP_NAME).xcodeproj"; \
	else \
		echo "$(RED)❌ Xcode project not found. Run 'make native-setup' first.$(NC)"; \
		exit 1; \
	fi

# Swift Package Manager alternative (faster builds)
native-spm-build:
	@echo "$(YELLOW)Building with Swift Package Manager...$(NC)"
	@cd $(MACOS_DIR) && swift build -c debug

native-spm-run: native-spm-build
	@echo "$(YELLOW)Running with Swift Package Manager...$(NC)"
	@cd $(MACOS_DIR) && swift run

native-spm-release:
	@echo "$(YELLOW)Building release with Swift Package Manager...$(NC)"
	@cd $(MACOS_DIR) && swift build -c release
	@echo "$(GREEN)✓ Binary: $(MACOS_DIR)/.build/release/$(NATIVE_APP_NAME)$(NC)"

# Kill any running instance
native-kill:
	@pkill -9 $(NATIVE_APP_NAME) 2>/dev/null || true
	@echo "$(GREEN)✓ Killed any running instances$(NC)"

# Quick rebuild and rerun
native-rebuild: native-clean native-run
