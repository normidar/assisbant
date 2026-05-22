.DEFAULT_GOAL := help

.PHONY: help
help:
	@echo "List of available make commands";
	@echo "";
	@grep -hE '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}';
	@echo "";

# ci
.PHONY: ci
ci: fvm_use get tr build analyze format gen_icons

.PHONY: fvm_use
fvm_use: ## Use fvm: `make fvm_use`
	fvm use

# analyze
.PHONY: analyze
analyze: ## Analyze all apps with Flutter
	fvm dart analyze .

.PHONY: get
get: ## Get all dependencies
	fvm dart pub get

# format
.PHONY: format
format: ## Format all code
	fvm dart format .
	npx prettier --write "**/*.md"

# run build
.PHONY: build
build: ## Same functionality as `fvm dart run build_runner build` (made available at root level) Usage: `make build`
	fvm dart run build_runner build --delete-conflicting-outputs

# add_freezed: https://pub.dev/packages/freezed#install
.PHONY: add_freezed
add_freezed: ## Add freezed to package: `make add_freezed`
	fvm dart pub add freezed_annotation && \
	fvm dart pub add dev:build_runner && \
	fvm dart pub add dev:freezed && \
	fvm dart pub add json_annotation && \
	fvm dart pub add dev:json_serializable; \

.PHONY: add_riverpod
add_riverpod: ## Add riverpod to package: `make add_riverpod`
	fvm dart pub add riverpod_annotation && \
	fvm dart pub add flutter_riverpod && \
	fvm dart pub add dev:riverpod_generator && \
	fvm dart pub add dev:build_runner && \
	fvm dart pub add dev:custom_lint && \
	fvm dart pub add dev:riverpod_lint; \

# git branch clean
.PHONY: git_branch_clean
git_branch_clean: ## リモートに存在しないローカルブランチを削除する
	git fetch -p; \
	current_branch=$$(git branch --show-current); \
	for branch in $$(git branch | sed 's/..//'); do \
	  if [ "$$branch" == "$$current_branch" ]; then \
	    continue; \
	  fi; \
	  if ! git show-ref --quiet refs/remotes/origin/$$branch; then \
	    git branch -D "$$branch"; \
	  fi; \
	done

# git_create_tag
.PHONY: git_create_tag
git_create_tag: ## Create a tag: `make git_create_tag <tag_name>`
	if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "\033[0;31mPlease provide a tag name."; \
	else \
		git tag $(filter-out $@,$(MAKECMDGOALS)) && \
		git push origin $(filter-out $@,$(MAKECMDGOALS)); \
	fi

# git_my_tasks
.PHONY: git_my_tasks
git_my_tasks: ## Display my tasks: `make git_my_tasks`
	gh issue ls --assignee @me

.PHONY: pub_publish_dry_run
pub_publish_dry_run: ## Dry run for pub publish: `make pub_publish_dry_run`
	fvm dart pub publish --dry-run

.PHONY: pub_publish
pub_publish: ## Publish to pub.dev: `make pub_publish`
	fvm dart pub publish

.PHONY: add_dependency
add_dependency: ## Add a dependency to the package: `make add_dependency <dependency_name>`
	if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "\033[0;31mPlease provide a dependency name."; \
	else \
		fvm dart pub add $(filter-out $@,$(MAKECMDGOALS)); \
	fi

# build_appbundle
.PHONY: build_appbundle
build_appbundle: ## use this like: `make build_appbundle apps/app_name`
	(fvm flutter packages get && \
	fvm flutter clean && \
	fvm flutter pub get && \
	if [ -f "build_appbundle.sh" ]; then \
		chmod +x build_appbundle.sh && \
		./build_appbundle.sh; \
	else \
		fvm flutter build appbundle; \
	fi); \

# fastlane_android_release
.PHONY: fastlane_android_release
fastlane_android_release: gen_icons tr ## 同時にandroidをビルドしてreleaseにアップロードする: `make fastlane_android_release apps/app_name`
	make build_appbundle && \
	echo "start build android..." && \
	fastlane android_release && \
	echo "build android done."

# fastlane_android_test_release
.PHONY: fastlane_android_test_release
fastlane_android_test_release: gen_icons tr ## 同時にandroidをビルドして内部テストにアップロードする: `make fastlane_android_test_release apps/app_name`
	make build_appbundle && \
	echo "start build android for internal testing..." && \
	fastlane android_test_release && \
	echo "build android for internal testing done."

# fastlane_ios_release
.PHONY: fastlane_ios_release
fastlane_ios_release: gen_icons tr ## 同時にiosをビルドしてreleaseにアップロードする: `make fastlane_ios_release apps/app_name`
	make build_ipa && \
	echo "start build ios..." && \
	fastlane ios_release && \
	echo "build ios done."

# build_ipa
.PHONY: build_ipa
build_ipa: ## use this like: `make build_ipa apps/app_name`
	fvm flutter packages get && \
	fvm flutter clean && \
	fvm flutter pub get && \
	(cd ios && pod install --repo-update) && \
	if [ -f "build_ipa.sh" ]; then \
		chmod +x build_ipa.sh && \
		./build_ipa.sh; \
	else \
		fvm flutter build ipa; \
	fi; \

.PHONY: init_android
init_android: ## Initialize android project: `make init_android`
	fvm flutter create --platforms=android .

.PHONY: init_ios
init_ios: ## Initialize ios project: `make init_ios`
	fvm flutter create --platforms=ios .

.PHONY: init_web
init_web: ## Initialize web project: `make init_web`
	fvm flutter create --platforms=web .

.PHONY: build_web_release
build_web_release: ## Build web release and copy to specified path: `make build_web_release <path>`
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "\033[0;31mPlease provide a destination path."; \
		echo "\033[0;33mUsage: make build_web_release <path>"; \
		exit 1; \
	else \
		DEST_PATH=$(filter-out $@,$(MAKECMDGOALS)); \
		echo "\033[0;32mBuilding Flutter web release..."; \
		fvm flutter clean && \
		fvm flutter pub get && \
		fvm flutter build web --release && \
		echo "\033[0;32mCopying build output to $$DEST_PATH..."; \
		mkdir -p "$$DEST_PATH" && \
		cp -r build/web/* "$$DEST_PATH/" && \
		echo "\033[0;32mBuild completed and copied to $$DEST_PATH successfully!"; \
	fi

.PHONY: init_macos
init_macos: ## Initialize macos project: `make init_macos`
	fvm flutter create --platforms=macos .

.PHONY: gen_icons
gen_icons: ## Generate icons: `make gen_icons`
	fvm dart run icons_launcher:create

.PHONY: tr
tr: ## Translate all files: `make tr`
	fvm dart run colaxy_localization:gen

.PHONY: rename
rename: ## Rename in all files from flutterapptemp to <new_name>: `make rename <new_name>`
	@if [ -z "$(filter-out $@,$(MAKECMDGOALS))" ]; then \
		echo "\033[0;31mPlease provide a new name."; \
		echo "\033[0;33mUsage: make rename <new_name>"; \
		exit 1; \
	else \
		NEW_NAME=$(filter-out $@,$(MAKECMDGOALS)); \
		echo "\033[0;32mRenaming flutterapptemp to $$NEW_NAME in all files..."; \
		find . -type f \( -name "*.dart" -o -name "*.yaml" -o -name "*.yml" -o -name "*.md" -o -name "*.json" \) -not -path "./.dart_tool/*" -not -path "./build/*" -not -path "./.git/*" | xargs sed -i '' "s/flutterapptemp/$$NEW_NAME/g"; \
		echo "\033[0;32mRenaming lib/flutterapptemp.dart to lib/$$NEW_NAME.dart..."; \
		if [ -f "lib/flutterapptemp.dart" ]; then \
			mv "lib/flutterapptemp.dart" "lib/$$NEW_NAME.dart"; \
		fi; \
		echo "\033[0;32mRename completed successfully!"; \
		echo "\033[0;33mModified files:"; \
		git status --porcelain | grep -E "^\s*M" || echo "No files were modified."; \
	fi

%:
	@:
