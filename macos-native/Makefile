# Makefile for WesWorld FX Native Mac App
# Swift Package Manager build process

.PHONY: all build run clean help setup release xcode

APP_NAME = WesWorldFX
BUNDLE_ID = io.wesworld.fx.native

# Colors for terminal output
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m # No Color

all: build

help:
	@echo "$(GREEN)WesWorld FX Native Mac - Build Commands$(NC)"
	@echo ""
	@echo "  $(YELLOW)make setup$(NC)      - Initial setup (create Package.swift)"
	@echo "  $(YELLOW)make build$(NC)      - Build debug version"
	@echo "  $(YELLOW)make release$(NC)    - Build release version"
	@echo "  $(YELLOW)make run$(NC)        - Build and run the app"
	@echo "  $(YELLOW)make clean$(NC)      - Clean build artifacts"
	@echo "  $(YELLOW)make xcode$(NC)      - Open in Xcode (generates Xcode project)"
	@echo ""
	@echo "$(GREEN)Quick Start:$(NC)"
	@echo "  1. make setup"
	@echo "  2. make run"
	@echo ""

setup:
	@echo "$(YELLOW)Setting up WesWorld FX Native...$(NC)"
	@if [ ! -f "Package.swift" ]; then \
		echo "Creating Xcode project..."; \
		./create-xcode-project.sh; \
	else \
		echo "$(GREEN)✓ Package.swift already exists$(NC)"; \
	fi

build: setup
	@echo "$(YELLOW)Building $(APP_NAME) (Debug)...$(NC)"
	@swift build -c debug
	@echo "$(GREEN)✓ Build complete!$(NC)"

release: setup
	@echo "$(YELLOW)Building $(APP_NAME) (Release)...$(NC)"
	@swift build -c release
	@echo "$(GREEN)✓ Release build complete!$(NC)"
	@echo "Binary: .build/release/$(APP_NAME)"

run: build
	@echo "$(YELLOW)Launching $(APP_NAME)...$(NC)"
	@swift run

xcode: setup
	@echo "$(YELLOW)Opening in Xcode...$(NC)"
	@open Package.swift

clean:
	@echo "$(YELLOW)Cleaning build artifacts...$(NC)"
	@swift package clean
	@rm -rf .build
	@echo "$(GREEN)✓ Clean complete$(NC)"
	@echo "$(GREEN)✓ Binary: .build/release/$(APP_NAME)$(NC)"
