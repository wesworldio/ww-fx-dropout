# Makefile for WesWorld FX Native Mac App
# Simplified build process

.PHONY: all build run clean help setup release

APP_NAME = WesWorldFX
BUNDLE_ID = io.wesworld.fx.native
BUILD_DIR = build
SCHEME = $(APP_NAME)

# Colors for terminal output
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m # No Color

all: build

help:
	@echo "$(GREEN)WesWorld FX Native Mac - Build Commands$(NC)"
	@echo ""
	@echo "  $(YELLOW)make setup$(NC)      - Initial setup (create Xcode project)"
	@echo "  $(YELLOW)make build$(NC)      - Build debug version"
	@echo "  $(YELLOW)make release$(NC)    - Build release version"
	@echo "  $(YELLOW)make run$(NC)        - Build and run the app"
	@echo "  $(YELLOW)make clean$(NC)      - Clean build artifacts"
	@echo "  $(YELLOW)make xcode$(NC)      - Open in Xcode"
	@echo ""
	@echo "$(GREEN)Quick Start:$(NC)"
	@echo "  1. make setup"
	@echo "  2. make run"
	@echo ""

setup:
	@echo "$(YELLOW)Setting up WesWorld FX Native...$(NC)"
	@if [ ! -f "$(APP_NAME).xcodeproj/project.pbxproj" ]; then \
		echo "Creating Xcode project..."; \
		./create-xcode-project.sh; \
	else \
		echo "$(GREEN)✓ Xcode project already exists$(NC)"; \
	fi

build: setup
	@echo "$(YELLOW)Building $(APP_NAME) (Debug)...$(NC)"
	@xcodebuild -project $(APP_NAME).xcodeproj \
		-scheme $(SCHEME) \
		-configuration Debug \
		-derivedDataPath $(BUILD_DIR) \
		build | xcpretty || xcodebuild -project $(APP_NAME).xcodeproj -scheme $(SCHEME) -configuration Debug build
	@echo "$(GREEN)✓ Build complete!$(NC)"

release: setup
	@echo "$(YELLOW)Building $(APP_NAME) (Release)...$(NC)"
	@xcodebuild -project $(APP_NAME).xcodeproj \
		-scheme $(SCHEME) \
		-configuration Release \
		-derivedDataPath $(BUILD_DIR) \
		build | xcpretty || xcodebuild -project $(APP_NAME).xcodeproj -scheme $(SCHEME) -configuration Release build
	@echo "$(GREEN)✓ Release build complete!$(NC)"
	@echo "App: $(BUILD_DIR)/Build/Products/Release/$(APP_NAME).app"
	@echo "Creating DMG installer..."
	@bash create-dmg.sh

run: build
	@echo "$(YELLOW)Launching $(APP_NAME)...$(NC)"
	@open $(BUILD_DIR)/Build/Products/Debug/$(APP_NAME).app

xcode:
	@if [ -f "$(APP_NAME).xcodeproj/project.pbxproj" ]; then \
		open $(APP_NAME).xcodeproj; \
	else \
		echo "$(RED)Error: Xcode project not found. Run 'make setup' first.$(NC)"; \
	fi

clean:
	@echo "$(YELLOW)Cleaning build artifacts...$(NC)"
	@rm -rf $(BUILD_DIR)
	@rm -rf DerivedData
	@echo "$(GREEN)✓ Clean complete$(NC)"

# Swift Package Manager alternative
spm-build:
	@echo "$(YELLOW)Building with Swift Package Manager...$(NC)"
	@swift build -c debug

spm-run:
	@echo "$(YELLOW)Running with Swift Package Manager...$(NC)"
	@swift run

spm-release:
	@echo "$(YELLOW)Building release with Swift Package Manager...$(NC)"
	@swift build -c release
	@echo "$(GREEN)✓ Binary: .build/release/$(APP_NAME)$(NC)"
