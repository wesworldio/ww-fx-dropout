.PHONY: help setup run clean build-info setup-hooks \
	native-setup native-build native-run native-release native-clean native-xcode native-kill native-rebuild \
	web-build web-clean web-watch web-daemon web-daemon-stop web-daemon-status web-daemon-logs

PYTHON = python3
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m

help:
	@echo "WesWorld FX - macOS Native Build System"
	@echo ""
	@echo "$(YELLOW)PRIMARY: macOS Native (Metal GPU):$(NC)"
	@echo "  make run              - Build and run native macOS app (primary)"
	@echo "  make setup            - Initial setup for native app"
	@echo "  make native-build     - Build native app (debug)"
	@echo "  make native-release   - Build release version"
	@echo "  make native-xcode     - Open in Xcode"
	@echo "  make native-clean     - Clean build artifacts"
	@echo ""
	@echo "$(YELLOW)SECONDARY: Web Target (Testing & Comparison):$(NC)"
	@echo "  make web-build        - Build web assets"
	@echo "  make web-watch        - Watch files and rebuild (foreground)"
	@echo "  make web-daemon       - Start watcher daemon"
	@echo "  make web-daemon-stop  - Stop watcher daemon"
	@echo "  make web-daemon-logs  - View watcher logs"
	@echo "  make web-clean        - Clean web artifacts"
	@echo ""
	@echo "$(YELLOW)Utilities:$(NC)"
	@echo "  make build-info       - Generate build-info.json from git"
	@echo "  make setup-hooks      - Install git hooks"
	@echo ""
	@echo "$(YELLOW)Development:$(NC)"
	@echo "  make native-rebuild   - Clean and rebuild native app"
	@echo "  make native-kill      - Kill running app instance"

build-info:
	@echo "Generating build-info.json from git..."
	@$(PYTHON) scripts/generate_build_info.py
	@bash scripts/copy_build_info.sh

setup-hooks:
	@echo "Setting up git hooks to auto-update build-info.json..."
	@bash scripts/setup_git_hooks.sh

# ============================================================================
# Web Build Commands (Secondary)
# ============================================================================

web-build:
	@echo "$(YELLOW)Building web assets...$(NC)"
	@echo "✓ Web files ready (index.html, web-grid-generator.html)"

web-clean:
	@echo "$(YELLOW)Cleaning web build artifacts...$(NC)"
	@rm -f static/wasm/wwfx_module.js static/wasm/wwfx_module.wasm 2>/dev/null || true
	@echo "$(GREEN)✓ Web clean complete$(NC)"

web-watch:
	@echo "$(YELLOW)Starting file watcher for web (foreground)...$(NC)"
	@echo "Watching for changes in web files"
	@echo "Press Ctrl+C to stop"
	@$(PYTHON) scripts/watch_wasm.py

web-daemon:
	@echo "$(YELLOW)Starting web watcher as daemon...$(NC)"
	@if [ -f /tmp/ww_fx_wasm.pid ]; then \
		PID=$$(cat /tmp/ww_fx_wasm.pid); \
		if ps -p $$PID > /dev/null 2>&1; then \
			echo "$(YELLOW)⚠️  Watcher already running (PID: $$PID)$(NC)"; \
			echo "   Stop with: make web-daemon-stop"; \
			exit 1; \
		fi; \
	fi
	@nohup $(PYTHON) scripts/watch_wasm.py > /tmp/ww_fx_wasm.log 2>&1 & \
	echo $$! > /tmp/ww_fx_wasm.pid && \
	echo "$(GREEN)✓ Watcher started (PID: $$(cat /tmp/ww_fx_wasm.pid))$(NC)"
	@echo "   View logs: make web-daemon-logs"
	@echo "   Stop: make web-daemon-stop"

web-daemon-stop:
	@if [ -f /tmp/ww_fx_wasm.pid ]; then \
		PID=$$(cat /tmp/ww_fx_wasm.pid); \
		if ps -p $$PID > /dev/null 2>&1; then \
			kill $$PID && echo "$(GREEN)✓ Stopped watcher (PID: $$PID)$(NC)"; \
		else \
			echo "$(YELLOW)⚠️  Process $$PID not found$(NC)"; \
		fi; \
		rm -f /tmp/ww_fx_wasm.pid; \
	else \
		echo "$(YELLOW)⚠️  No watcher PID file found$(NC)"; \
	fi

web-daemon-status:
	@if [ -f /tmp/ww_fx_wasm.pid ]; then \
		PID=$$(cat /tmp/ww_fx_wasm.pid); \
		if ps -p $$PID > /dev/null 2>&1; then \
			echo "$(GREEN)✓ Watcher running (PID: $$PID)$(NC)"; \
		else \
			echo "$(YELLOW)⚠️  Watcher not running (PID file exists but process not found)$(NC)"; \
		fi; \
	else \
		echo "$(YELLOW)⚠️  Watcher not running$(NC)"; \
	fi

web-daemon-logs:
	@if [ -f /tmp/ww_fx_wasm.log ]; then \
		tail -f /tmp/ww_fx_wasm.log; \
	else \
		echo "$(YELLOW)⚠️  No log file found. Start watcher with: make web-daemon$(NC)"; \
	fi

# ============================================================================
# Native macOS Metal App Build Commands (PRIMARY)
# ============================================================================

MACOS_DIR = macos-native
NATIVE_APP_NAME = WesWorldFX
BUILD_DIR = $(MACOS_DIR)/build
RELEASE_DIR = $(BUILD_DIR)/Build/Products/Release
DEBUG_DIR = $(BUILD_DIR)/Build/Products/Debug

# Default targets
setup: native-setup
	@echo "$(GREEN)✓ Setup complete - Ready to build and run$(NC)"

run: native-run
	@echo "$(GREEN)✓ App launched$(NC)"

clean: native-clean
	@echo "$(GREEN)✓ Clean complete$(NC)"

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
	if [ -f "$(NATIVE_APP_NAME).xcodeproj/project.pbxproj" ]; then \
		xcodebuild -project $(NATIVE_APP_NAME).xcodeproj \
			-scheme $(NATIVE_APP_NAME) \
			-configuration Debug \
			-derivedDataPath build \
			build 2>&1 | tail -20 || true; \
	else \
		echo "$(YELLOW)⚠️  Xcode project missing; using SwiftPM build$(NC)"; \
		swift build -c debug; \
	fi
	@echo "$(GREEN)✓ Build complete$(NC)"

# Build and run native app
native-run: native-build
	@echo "$(YELLOW)Launching WesWorldFX...$(NC)"
	@if [ -d "$(DEBUG_DIR)/$(NATIVE_APP_NAME).app" ]; then \
		open "$(DEBUG_DIR)/$(NATIVE_APP_NAME).app"; \
		echo "$(GREEN)✓ WesWorldFX launched (Press B to open Custom Bulge Editor)$(NC)"; \
	elif [ -f "$(MACOS_DIR)/Package.swift" ]; then \
		echo "$(YELLOW)⚠️  Xcode app not found; running SwiftPM binary$(NC)"; \
		cd $(MACOS_DIR) && swift run; \
	else \
		echo "$(RED)❌ App not found at $(DEBUG_DIR)/$(NATIVE_APP_NAME).app$(NC)"; \
		echo "$(RED)❌ Package.swift not found in $(MACOS_DIR)$(NC)"; \
		exit 1; \
	fi

# Build release version
native-release: native-setup
	@echo "$(YELLOW)Building WesWorldFX (Release)...$(NC)"
	@cd $(MACOS_DIR) && \
	if [ -f "$(NATIVE_APP_NAME).xcodeproj/project.pbxproj" ]; then \
		xcodebuild -project $(NATIVE_APP_NAME).xcodeproj \
			-scheme $(NATIVE_APP_NAME) \
			-configuration Release \
			-derivedDataPath build \
			build 2>&1 | tail -20 || true; \
		echo "$(GREEN)✓ Release build complete$(NC)"; \
		echo "   App: $(RELEASE_DIR)/$(NATIVE_APP_NAME).app"; \
	else \
		echo "$(YELLOW)⚠️  Xcode project missing; using SwiftPM release build$(NC)"; \
		swift build -c release; \
		echo "$(GREEN)✓ Binary: $(MACOS_DIR)/.build/release/$(NATIVE_APP_NAME)$(NC)"; \
	fi

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
		echo "$(GREEN)✓ Opened in Xcode$(NC)"; \
	elif [ -f "$(MACOS_DIR)/Package.swift" ]; then \
		echo "$(YELLOW)⚠️  Xcode project missing; opening Package.swift$(NC)"; \
		open "$(MACOS_DIR)/Package.swift"; \
	else \
		echo "$(RED)❌ Xcode project not found. Run 'make native-setup' first.$(NC)"; \
		exit 1; \
	fi

# Kill any running instance
native-kill:
	@pkill -9 $(NATIVE_APP_NAME) 2>/dev/null || true
	@echo "$(GREEN)✓ Killed any running instances$(NC)"

# Quick rebuild and rerun
native-rebuild: native-clean native-run
