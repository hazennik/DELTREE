SHELL := /bin/zsh

PROJECT ?= DELTREE.xcodeproj
SCHEME ?= DELTREE
DESTINATION ?= platform=macOS,arch=arm64
DERIVED_DATA_PATH ?= build/DerivedData
XCODEBUILD ?= xcodebuild

.PHONY: analyze appcast-check build check cli-dry-run format lint package-check release repository-check swift-test test ui-test

build:
	$(XCODEBUILD) build -scheme $(SCHEME) -project $(PROJECT) -destination '$(DESTINATION)' -derivedDataPath '$(DERIVED_DATA_PATH)' CODE_SIGNING_ALLOWED=NO

test:
	DELTREE_DISABLE_INITIAL_SCAN=1 $(XCODEBUILD) test -scheme $(SCHEME) -project $(PROJECT) -destination '$(DESTINATION)' -derivedDataPath '$(DERIVED_DATA_PATH)' -parallel-testing-enabled NO -skip-testing:DELTREEUITests CODE_SIGNING_ALLOWED=NO

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

repository-check:
	zsh Scripts/check-repository-size.sh

appcast-check:
	zsh Scripts/generate-appcast.sh --dry-run

release:
	zsh Scripts/package-release.sh --notarize
	zsh Scripts/generate-appcast.sh

check: lint repository-check build test swift-test analyze cli-dry-run package-check appcast-check
