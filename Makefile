.PHONY: build upload deliver run dev debug flutter-debug profile reset-dev

DEVICE_ID = 00008103-001255100ED1001E
XCODE_BETA = /Applications/Xcode-beta.app/Contents/Developer
FLUTTER = DEVELOPER_DIR=$(XCODE_BETA) flutter

build:
	@echo "Building release IPA with Xcode beta..."
	$(FLUTTER) build ipa --release

upload:
	@echo "Opening Transporter with the built IPA..."
	open -a Transporter build/ios/ipa/*.ipa

deliver: build upload

run:
	@echo "Launching release mode on Abdul's iPad..."
	$(FLUTTER) run --release -d $(DEVICE_ID)

dev:
	@echo "Launching debug mode with hot reload on Abdul's iPad..."
	$(FLUTTER) run --debug -d $(DEVICE_ID)

profile:
	@echo "Launching profile mode on Abdul's iPad..."
	$(FLUTTER) run --profile -d $(DEVICE_ID)

debug: dev

flutter-debug: dev

reset-dev:
	@echo "Resetting Flutter and CocoaPods development artifacts..."
	flutter clean
	flutter pub get
	cd ios && pod install
