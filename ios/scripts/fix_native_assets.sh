#!/bin/sh
# fix_native_assets.sh
# Patches MinimumOSVersion in embedded native-asset frameworks and re-signs them
# so that iOS device deployment (0xe8008001) does not fail.
#
# This script runs AFTER xcode_backend.sh embed_and_thin has copied and signed
# the frameworks into TARGET_BUILD_DIR. We patch the Info.plist and then
# re-sign with the correct identity so the signature remains valid.

set -e

FRAMEWORKS_DIR="${TARGET_BUILD_DIR}/${FRAMEWORKS_FOLDER_PATH}"

if [ ! -d "$FRAMEWORKS_DIR" ]; then
  echo "warning: Native assets framework directory not found: $FRAMEWORKS_DIR — skipping."
  exit 0
fi

echo "=== fix_native_assets: patching MinimumOSVersion in embedded frameworks ==="

# Determine the signing identity to use
# EXPANDED_CODE_SIGN_IDENTITY is the SHA1 hash Xcode uses — the most reliable value
SIGN_ID="${EXPANDED_CODE_SIGN_IDENTITY}"

# If empty or "-" (ad-hoc), try CODE_SIGN_IDENTITY string
if [ -z "$SIGN_ID" ] || [ "$SIGN_ID" = "-" ]; then
  SIGN_ID="${CODE_SIGN_IDENTITY}"
fi

# If still a display name (not a hash), look up the hash from the keychain
if [ -n "$SIGN_ID" ] && [ ${#SIGN_ID} -lt 40 ]; then
  SIGN_ID=$(security find-identity -v -p codesigning 2>/dev/null | \
    grep "Apple Development" | \
    head -1 | \
    awk '{print $2}')
fi

echo "  Signing identity: ${SIGN_ID:-<none>}"
echo "  Frameworks dir: $FRAMEWORKS_DIR"

# Patch and re-sign each native asset framework in TARGET_BUILD_DIR
find "$FRAMEWORKS_DIR" -maxdepth 1 -name "*.framework" | while read -r framework; do
  framework_name=$(basename "$framework" .framework)

  # Skip Flutter's own frameworks — they manage their own signing
  if [ "$framework_name" = "Flutter" ] || [ "$framework_name" = "App" ]; then
    continue
  fi

  plist="$framework/Info.plist"
  if [ ! -f "$plist" ]; then
    continue
  fi

  # Always re-sign, even if plist values look correct — the signature may already
  # be broken from a previous partial patch run (the root cause of 0xe8008001)
  current=$(/usr/libexec/PlistBuddy -c "Print :MinimumOSVersion" "$plist" 2>/dev/null || echo "")
  if [ "$current" != "$IPHONEOS_DEPLOYMENT_TARGET" ]; then
    echo "  Patching $framework_name: $current -> $IPHONEOS_DEPLOYMENT_TARGET"
    /usr/libexec/PlistBuddy -c "Set :MinimumOSVersion $IPHONEOS_DEPLOYMENT_TARGET" "$plist" 2>/dev/null || \
      /usr/libexec/PlistBuddy -c "Add :MinimumOSVersion string $IPHONEOS_DEPLOYMENT_TARGET" "$plist"
  fi

  # Re-sign the framework to repair the code signature after Info.plist mutation
  if [ -n "$SIGN_ID" ] && [ "$SIGN_ID" != "-" ]; then
    echo "  Re-signing $framework_name..."
    if codesign --force --sign "$SIGN_ID" \
        --preserve-metadata=identifier,entitlements,flags \
        --timestamp=none \
        "$framework" 2>&1; then
      echo "  ✓ Re-signed $framework_name"
    else
      echo "  ✗ Re-sign FAILED for $framework_name — trying ad-hoc"
      # Fallback to ad-hoc signing (sufficient for device dev builds)
      codesign --force --sign - "$framework" 2>&1 || true
    fi
  else
    echo "  warning: No signing identity — skipping re-sign for $framework_name"
  fi

  echo ""
done

# Also patch the SOURCE dir so the next incremental build starts clean
NATIVE_ASSETS_SOURCE="${SRCROOT}/../build/native_assets/ios"
if [ -d "$NATIVE_ASSETS_SOURCE" ]; then
  find "$NATIVE_ASSETS_SOURCE" -name "Info.plist" | while read -r plist; do
    current=$(/usr/libexec/PlistBuddy -c "Print :MinimumOSVersion" "$plist" 2>/dev/null || echo "")
    if [ "$current" != "$IPHONEOS_DEPLOYMENT_TARGET" ]; then
      /usr/libexec/PlistBuddy -c "Set :MinimumOSVersion $IPHONEOS_DEPLOYMENT_TARGET" "$plist" 2>/dev/null || \
        /usr/libexec/PlistBuddy -c "Add :MinimumOSVersion string $IPHONEOS_DEPLOYMENT_TARGET" "$plist"
      echo "  Patched source plist: $plist"
    fi
  done
fi

# Generate dSYMs for native asset frameworks (Release only)
if [ "$CONFIGURATION" = "Release" ]; then
  echo "=== fix_native_assets: generating dSYMs ==="
  find "$FRAMEWORKS_DIR" -maxdepth 1 -name "*.framework" | while read -r framework; do
    framework_name=$(basename "$framework" .framework)
    if [ "$framework_name" = "Flutter" ] || [ "$framework_name" = "App" ]; then
      continue
    fi
    binary="$framework/$framework_name"
    if [ ! -f "$binary" ]; then
      continue
    fi
    dsym_path="${DWARF_DSYM_FOLDER_PATH}/$framework_name.framework.dSYM"
    if [ ! -d "$dsym_path" ]; then
      echo "  Generating dSYM for $framework_name"
      dsymutil "$binary" -o "$dsym_path" 2>/dev/null || echo "  warning: dsymutil failed for $framework_name"
    fi
  done
fi

echo "=== fix_native_assets: done ==="

# Re-sign the outer .app bundle to repair its sealed resource map
# (modifying embedded frameworks invalidates the parent bundle's signature)
APP_BUNDLE="${CODESIGNING_FOLDER_PATH}"
if [ -n "$SIGN_ID" ] && [ "$SIGN_ID" != "-" ] && [ -d "$APP_BUNDLE" ]; then
  ENTITLEMENTS_PATH="${SRCROOT}/Runner/Runner.entitlements"
  echo "Re-signing outer app bundle: $(basename "$APP_BUNDLE")"
  if [ -f "$ENTITLEMENTS_PATH" ]; then
    codesign --force --sign "$SIGN_ID" \
      --entitlements "$ENTITLEMENTS_PATH" \
      --timestamp=none \
      "$APP_BUNDLE" 2>&1 || echo "warning: outer app bundle re-sign failed (non-fatal)"
  else
    codesign --force --sign "$SIGN_ID" \
      --preserve-metadata=entitlements \
      --timestamp=none \
      "$APP_BUNDLE" 2>&1 || echo "warning: outer app bundle re-sign failed (non-fatal)"
  fi
fi
