APP_NAME := Wave
PROJECT := Wave.xcodeproj
SCHEME := Wave
CONFIGURATION := Release
DERIVED_DATA := $(CURDIR)/build
PRODUCTS_DIR := $(DERIVED_DATA)/Build/Products/$(CONFIGURATION)
APP_BUNDLE := $(PRODUCTS_DIR)/$(APP_NAME).app
STAGING_DIR := $(CURDIR)/dmg-staging
DMG_NAME ?= Wave-Installer
DMG_PATH := $(CURDIR)/$(DMG_NAME).dmg
UPDATES_DIR := $(CURDIR)/updates/releases
APP_ZIP := $(UPDATES_DIR)/$(APP_NAME).zip
GENERATE_APPCAST := $(shell command -v generate_appcast 2>/dev/null || find "$(HOME)/Library/Developer/Xcode/DerivedData" -type f -name generate_appcast 2>/dev/null | head -n 1)

.PHONY: all build release dmg zip appcast clean clean-dmg

all: build

build: $(APP_BUNDLE)

$(APP_BUNDLE):
	xcodebuild \
		-project "$(PROJECT)" \
		-scheme "$(SCHEME)" \
		-configuration "$(CONFIGURATION)" \
		-derivedDataPath "$(DERIVED_DATA)" \
		build

dmg: build
	@command -v create-dmg >/dev/null 2>&1 || { \
		echo "error: create-dmg not found. Install it (e.g. brew install create-dmg)."; \
		exit 1; \
	}
	rm -rf "$(STAGING_DIR)"
	mkdir -p "$(STAGING_DIR)"
	cp -R "$(APP_BUNDLE)" "$(STAGING_DIR)/"
	rm -f "$(DMG_PATH)"
	create-dmg \
		--volname "$(APP_NAME)" \
		--window-pos 200 120 \
		--window-size 640 360 \
		--icon-size 96 \
		--icon "$(APP_NAME).app" 180 170 \
		--hide-extension "$(APP_NAME).app" \
		--app-drop-link 460 170 \
		"$(DMG_PATH)" \
		"$(STAGING_DIR)"

zip: build
	mkdir -p "$(UPDATES_DIR)"
	rm -f "$(APP_ZIP)"
	ditto -c -k --sequesterRsrc --keepParent "$(APP_BUNDLE)" "$(APP_ZIP)"

appcast: zip
	@test -n "$(GENERATE_APPCAST)" || { \
		echo "error: generate_appcast not found. Build once in Xcode after adding Sparkle, or install Sparkle tools."; \
		exit 1; \
	}
	"$(GENERATE_APPCAST)" "$(UPDATES_DIR)"

release:
	./scripts/release.sh

clean:
	rm -rf "$(DERIVED_DATA)"

clean-dmg:
	rm -rf "$(STAGING_DIR)" "$(DMG_PATH)"
