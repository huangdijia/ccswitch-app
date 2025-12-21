# CCSwitch Makefile

# Project variables
PROJECT_NAME = CCSwitch
PROJECT_DIR = CCSwitch
XCODEPROJ = $(PROJECT_DIR)/$(PROJECT_NAME).xcodeproj
SCHEME = $(PROJECT_NAME)
BUILD_DIR = $(PROJECT_DIR)/build
APP_NAME = $(PROJECT_NAME).app
DEST_APP = $(PROJECT_DIR)/$(APP_NAME)

# Tools
XCODEBUILD = xcodebuild

.PHONY: all build fast-build run test test-app clean help

all: build

help:
	@echo "Usage:"
	@echo "  make build       - Build the project using xcodebuild (Release, requires Xcode)"
	@echo "  make fast-build  - Build the project using swiftc (via compile_swift.sh)"
	@echo "  make run         - Build and run the app"
	@echo "  make test        - Run unit tests (requires Xcode)"
	@echo "  make test-app    - Run manual test script to verify app functionality"
	@echo "  make clean       - Remove build artifacts"
	@echo ""
	@echo "If you don't have Xcode installed, use 'make fast-build' instead."

build:
	@echo "🔨 Building $(PROJECT_NAME)..."
	@if ! xcode-select -p &>/dev/null || [ "$$(xcode-select -p)" = "/Library/Developer/CommandLineTools" ]; then \
		echo "❌ Full Xcode installation is required for building."; \
		echo "Please install Xcode from the App Store and run:"; \
		echo "  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"; \
		echo ""; \
		echo "Alternatively, use fast-build which doesn't require Xcode:"; \
		echo "  make fast-build"; \
		exit 1; \
	fi
	@mkdir -p $(BUILD_DIR)
	@$(XCODEBUILD) \
		-project $(XCODEPROJ) \
		-scheme $(SCHEME) \
		-configuration Release \
		-derivedDataPath $(BUILD_DIR) \
		build
	@APP_PATH=$$(find $(BUILD_DIR) -name "$(APP_NAME)" -type d | head -n 1); \
	if [ -n "$$APP_PATH" ]; then \
		cp -R "$$APP_PATH" "$(PROJECT_DIR)/"; \
		echo "✅ Built $(DEST_APP)"; \
	else \
		echo "❌ Build failed: $(APP_NAME) not found"; \
		exit 1; \
	fi

fast-build:
	@echo "⚙️  Fast building $(PROJECT_NAME) with swiftc..."
	@./compile_swift.sh

run:
	@echo "🚀 Launching $(PROJECT_NAME)..."
	@if ! xcode-select -p &>/dev/null || [ "$$(xcode-select -p)" = "/Library/Developer/CommandLineTools" ]; then \
		echo "⚠️  Xcode not found, using fast-build..."; \
		$(MAKE) fast-build; \
	fi
	@./run_dev.sh

test:
	@echo "🧪 Running tests..."
	@if ! xcode-select -p &>/dev/null || [ "$$(xcode-select -p)" = "/Library/Developer/CommandLineTools" ]; then \
		echo "❌ Xcode is required for running tests."; \
		echo "Please install Xcode from the App Store and run:"; \
		echo "  sudo xcode-select -s /Applications/Xcode.app/Contents/Developer"; \
		echo ""; \
		echo "Alternatively, you can test the app manually:"; \
		echo "  make fast-build  # Build the app"; \
		echo "  make test-app    # Run manual test script"; \
		exit 1; \
	fi
	@$(XCODEBUILD) test \
		-project $(XCODEPROJ) \
		-scheme $(SCHEME) \
		-destination 'platform=macOS'

test-app:
	@echo "🧪 Running manual app test..."
	@./test_app.sh

clean:
	@echo "🧹 Cleaning..."
	@rm -rf $(BUILD_DIR)
	@rm -rf $(PROJECT_DIR)/DerivedData
	@rm -rf $(DEST_APP)
	@rm -rf $(PROJECT_DIR)/build
