SHELL := /bin/zsh

PROJECT ?= DELTREE.xcodeproj
SCHEME ?= DELTREE
DESTINATION ?= platform=macOS,arch=arm64
DERIVED_DATA_PATH ?= build/DerivedData
XCODEBUILD ?= xcodebuild
UI_TEST_TIMEOUT_SECONDS ?= 120

.PHONY: analyze appcast-check build check cli-dry-run docs-check format homebrew-check icon-check lint package-check release repository-check script-test spark-sign-check swift-test test ui-test workflow-check

build:
	$(XCODEBUILD) build -scheme $(SCHEME) -project $(PROJECT) -destination '$(DESTINATION)' -derivedDataPath '$(DERIVED_DATA_PATH)' CODE_SIGNING_ALLOWED=NO

test:
	DELTREE_DISABLE_INITIAL_SCAN=1 $(XCODEBUILD) test -scheme $(SCHEME) -project $(PROJECT) -destination '$(DESTINATION)' -derivedDataPath '$(DERIVED_DATA_PATH)' -parallel-testing-enabled NO -skip-testing:DELTREEUITests CODE_SIGNING_ALLOWED=NO

ui-test:
	DELTREE_DISABLE_INITIAL_SCAN=1 ruby Scripts/run-with-timeout.rb $(UI_TEST_TIMEOUT_SECONDS) -- $(XCODEBUILD) test -scheme $(SCHEME) -project $(PROJECT) -destination '$(DESTINATION)' -derivedDataPath '$(DERIVED_DATA_PATH)' -only-testing:DELTREEUITests -parallel-testing-enabled NO -test-timeouts-enabled YES -default-test-execution-time-allowance 30 -maximum-test-execution-time-allowance 45

swift-test:
	swift test

analyze:
	$(XCODEBUILD) analyze -scheme $(SCHEME) -project $(PROJECT) -destination '$(DESTINATION)' -derivedDataPath '$(DERIVED_DATA_PATH)' CODE_SIGNING_ALLOWED=NO

lint:
	zsh Scripts/lint.sh lint

format:
	zsh Scripts/lint.sh format

workflow-check:
	zsh Scripts/check-workflows.sh

script-test:
	zsh -n Scripts/*.sh Tools/deltree
	ruby -c Scripts/run-with-timeout.rb
	zsh Scripts/test_release_artifacts.sh
	zsh Scripts/test_release_pipeline.sh
	zsh Scripts/test_repository_size.sh
	zsh Scripts/test_cli_diagnostics.sh

cli-dry-run:
	Tools/deltree --dry-run --json

package-check:
	DELTREE_DEVELOPER_ID_APPLICATION='Developer ID Application: Example' \
	DELTREE_TEAM_ID='TEAMID1234' \
	DELTREE_NOTARY_PROFILE='deltree-notary-profile' \
	zsh Scripts/package-release.sh --dry-run --notarize --distribution developer-id
	DELTREE_DEVELOPER_ID_APPLICATION='Developer ID Application: Example' \
	DELTREE_TEAM_ID='TEAMID1234' \
	DELTREE_NOTARY_PROFILE='deltree-notary-profile' \
	zsh Scripts/package-release.sh --dry-run --notarize --distribution homebrew

repository-check:
	zsh Scripts/check-repository-size.sh

appcast-check:
	zsh Scripts/generate-appcast.sh --dry-run

spark-sign-check:
	zsh Scripts/sign-sparkle-update.sh --dry-run

docs-check:
	ruby Scripts/check-docs-links.rb

icon-check:
	zsh Scripts/build-icon.sh --check

homebrew-check:
	zsh Scripts/generate-homebrew-cask.sh --version 1.0.0 --sha256 aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa >/dev/null

release:
	zsh Scripts/package-release.sh --notarize
	zsh Scripts/generate-appcast.sh

check: lint workflow-check repository-check docs-check icon-check homebrew-check script-test build test swift-test analyze cli-dry-run package-check appcast-check spark-sign-check
