.PHONY: help wasm-build wasm-clean wasm-watch wasm-daemon wasm-daemon-stop wasm-daemon-status wasm-daemon-logs build-info setup-hooks

PYTHON = python3

help:
	@echo "WesWorld FX - WASM Version Commands:"
	@echo ""
	@echo "WASM Build:"
	@echo "  make wasm-build       - Build WASM module"
	@echo "  make wasm-clean       - Clean WASM build artifacts"
	@echo "  make wasm-watch       - Watch WASM files and rebuild on changes (foreground)"
	@echo "  make wasm-daemon      - Start WASM watcher as daemon with auto-rebuild"
	@echo "  make wasm-daemon-stop - Stop WASM watcher daemon"
	@echo "  make wasm-daemon-status - Check WASM watcher status"
	@echo "  make wasm-daemon-logs - View WASM watcher logs (tail -f)"
	@echo ""
	@echo "Utilities:"
	@echo "  make build-info       - Generate build-info.json from git"
	@echo "  make setup-hooks     - Install git hooks to auto-update build-info.json"
	@echo ""
	@echo "Note: This is the WASM-only version. Python backend code has been archived."
	@echo "      See archive/README.md for archived code."

build-info:
	@echo "Generating build-info.json from git..."
	@$(PYTHON) scripts/generate_build_info.py

setup-hooks:
	@echo "Setting up git hooks to auto-update build-info.json..."
	@bash scripts/setup_git_hooks.sh

# WASM Build Commands
wasm-build:
	@echo "Building WASM module..."
	@if [ ! -f wasm/build.sh ]; then \
		echo "❌ Error: wasm/build.sh not found"; \
		exit 1; \
	fi
	@chmod +x wasm/build.sh
	@cd wasm && ./build.sh

wasm-clean:
	@echo "Cleaning WASM build artifacts..."
	@rm -rf wasm/build 2>/dev/null || true
	@rm -f static/wasm/wwfx_module.js static/wasm/wwfx_module.wasm 2>/dev/null || true
	@echo "✅ WASM build artifacts cleaned"

wasm-watch:
	@echo "Starting WASM file watcher (foreground)..."
	@echo "Watching for changes in wasm/src/, wasm/include/, and wasm/CMakeLists.txt"
	@echo "Press Ctrl+C to stop"
	@$(PYTHON) scripts/watch_wasm.py

wasm-daemon:
	@echo "Starting WASM watcher as daemon..."
	@if [ -f /tmp/ww_fx_wasm.pid ]; then \
		PID=$$(cat /tmp/ww_fx_wasm.pid); \
		if ps -p $$PID > /dev/null 2>&1; then \
			echo "⚠️  WASM watcher already running (PID: $$PID)"; \
			echo "   Stop with: make wasm-daemon-stop"; \
			exit 1; \
		fi; \
	fi
	@echo "Building WASM module initially..."
	@$(MAKE) wasm-build || true
	@echo "Starting watcher daemon..."
	@nohup $(PYTHON) scripts/watch_wasm.py > /tmp/ww_fx_wasm.log 2>&1 & \
	echo $$! > /tmp/ww_fx_wasm.pid && \
	echo "✅ WASM watcher started (PID: $$(cat /tmp/ww_fx_wasm.pid))"
	@echo "To view logs: make wasm-daemon-logs"
	@echo "To stop: make wasm-daemon-stop"

wasm-daemon-stop:
	@if [ -f /tmp/ww_fx_wasm.pid ]; then \
		PID=$$(cat /tmp/ww_fx_wasm.pid); \
		if ps -p $$PID > /dev/null 2>&1; then \
			kill $$PID && echo "✅ Stopped WASM watcher (PID: $$PID)"; \
		else \
			echo "⚠️  Process $$PID not found"; \
		fi; \
		rm -f /tmp/ww_fx_wasm.pid; \
	else \
		echo "⚠️  No WASM watcher PID file found"; \
	fi

wasm-daemon-status:
	@if [ -f /tmp/ww_fx_wasm.pid ]; then \
		PID=$$(cat /tmp/ww_fx_wasm.pid); \
		if ps -p $$PID > /dev/null 2>&1; then \
			echo "✅ WASM watcher running (PID: $$PID)"; \
		else \
			echo "⚠️  WASM watcher not running (PID file exists but process not found)"; \
		fi; \
	else \
		echo "⚠️  WASM watcher not running"; \
	fi

wasm-daemon-logs:
	@if [ -f /tmp/ww_fx_wasm.log ]; then \
		tail -f /tmp/ww_fx_wasm.log; \
	else \
		echo "⚠️  No log file found. Start watcher with: make wasm-daemon"; \
	fi
