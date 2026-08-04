SHELL := /bin/zsh

PROJECT ?= DELTREE.xcodeproj
SCHEME ?= DELTREE
DESTINATION ?= platform=macOS
DERIVED_DATA_PATH ?= build/DerivedData
XCODEBUILD ?= xcodebuild

.PHONY: analyze appcast-check build check cli-dry-run format lint package-check release swift-test test ui-test

build:
	$(XCODEBUILD) build -scheme $(SCHEME) -project $(PROJECT) -destination '$(DESTINATION)' -derivedDataPath '$(DERIVED_DATA_PATH)' CODE_SIGNING_ALLOWED=NO

test:
	$(XCODEBUILD) test -scheme $(SCHEME) -project $(PROJECT) -destination '$(DESTINATION)' -derivedDataPath '$(DERIVED_DATA_PATH)' -skip-testing:DELTREEUITests CODE_SIGNING_ALLOWED=NO

ui-test:
	$(XCODEBUILD) test -scheme $(SCHEME) -project $(PROJECT) -destination '$(DESTINATION)' -derivedDataPath '$(DERIVED_DATA_PATH)' -only-testing:DELTREEUITests

swift-test:
	swift test

analyze:
	$(XCODEBUILD) analyze -scheme $(SCHEME) -project $(PROJECT) -destination '$(DESTINATION)' -derivedDataPath '$(DERIVED_DATA_PATH)' CODE_SIGNING_ALLOWED=NO

lint:
	zsh Scripts/lint.sh lint

format:
	zsh Scripts/lint.sh format

cli-dry-run:
	Tools/deltree --dry-run --json

package-check:
	DELTREE_DEVELOPER_ID_APPLICATION='Developer ID Application: Example' \
	DELTREE_TEAM_ID='TEAMID1234' \
	DELTREE_NOTARY_PROFILE='deltree-notary-profile' \
	zsh Scripts/package-release.sh --dry-run --notarize

appcast-check:
	zsh Scripts/generate-appcast.sh --dry-run

release:
	zsh Scripts/package-release.sh --notarize
	zsh Scripts/generate-appcast.sh

check: lint build test swift-test analyze cli-dry-run package-check appcast-check
