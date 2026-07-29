#!/bin/zsh
set -euo pipefail

script_dir=${0:A:h}
project_root=${script_dir:h}
source_dir="$project_root/Source"
build_dir="$project_root/.build"
output_dir="$project_root/Builds"
derived_data="$build_dir/DerivedData"
unsigned_product="$build_dir/New Text File-unsigned.pkg"
version=$(tr -d '[:space:]' < "$project_root/VERSION")
build_number=${BUILD_NUMBER:-1}
final_product="$output_dir/New Text File Installer $version.pkg"
generated_distribution="$build_dir/Distribution.xml"
package_root="$build_dir/package-root"
component_plist="$project_root/Installer/Components.plist"
installer_scripts="$project_root/Installer/Scripts"
installer_resources="$project_root/Installer/Resources"
generated_resources="$build_dir/installer-resources"

if [[ ! "$version" =~ '^[0-9]+\.[0-9]+\.[0-9]+$' ]]; then
    print -u2 "VERSION must contain an x.y.z semantic version; got: $version"
    exit 1
fi

mkdir -p "$build_dir/packages" "$output_dir"
if [[ -d "$derived_data" ]]; then
    find "$derived_data" -mindepth 1 -delete
fi
if [[ -d "$package_root" ]]; then
    find "$package_root" -mindepth 1 -delete
fi
if [[ -d "$generated_resources" ]]; then
    find "$generated_resources" -mindepth 1 -delete
fi
mkdir -p "$package_root/Applications"
mkdir -p "$generated_resources"
sed "s/__VERSION__/$version/g" \
    "$project_root/Installer/Distribution.xml" \
    > "$generated_distribution"
ditto "$installer_resources" "$generated_resources"
icon_base64=$(base64 < "$installer_resources/NewTextFileIcon.png" | tr -d '\n')
sed "s|__NEW_TEXT_FILE_ICON__|data:image/png;base64,$icon_base64|" \
    "$installer_resources/Welcome.html" \
    > "$generated_resources/Welcome.html"

app_identity=${APP_SIGN_IDENTITY:-}
installer_identity=${INSTALLER_SIGN_IDENTITY:-}

if [[ -z "$app_identity" ]]; then
    app_identity=$(security find-identity -v -p codesigning 2>/dev/null |
        sed -n 's/.*"\(Developer ID Application:.*\)"/\1/p' |
        head -1)
fi

if [[ -z "$installer_identity" ]]; then
    installer_identity=$(security find-identity -v -p basic 2>/dev/null |
        sed -n 's/.*"\(Developer ID Installer:.*\)"/\1/p' |
        head -1)
fi

if [[ -z "$app_identity" ]]; then
    if [[ "${REQUIRE_RELEASE_SIGNING:-0}" == "1" ]]; then
        print -u2 "A Developer ID Application identity is required for release deployment."
        exit 1
    fi
    app_identity="-"
    print "No Developer ID Application identity found; building an ad-hoc signed app."
else
    print "App signing identity: $app_identity"
fi

if [[ -z "$installer_identity" && "${REQUIRE_RELEASE_SIGNING:-0}" == "1" ]]; then
    print -u2 "A Developer ID Installer identity is required for release deployment."
    exit 1
fi

if [[ "${REQUIRE_RELEASE_SIGNING:-0}" == "1" && -z "${NOTARY_PROFILE:-}" ]]; then
    print -u2 "NOTARY_PROFILE is required for release deployment."
    exit 1
fi

xcodebuild \
    -project "$source_dir/NewTextFile.xcodeproj" \
    -scheme NewTextFile \
    -configuration Release \
    -destination "generic/platform=macOS" \
    -derivedDataPath "$derived_data" \
    MARKETING_VERSION="$version" \
    CURRENT_PROJECT_VERSION="$build_number" \
    CODE_SIGN_IDENTITY="$app_identity" \
    CODE_SIGN_STYLE=Manual \
    CODE_SIGNING_REQUIRED=YES \
    CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO \
    ENABLE_HARDENED_RUNTIME=YES \
    OTHER_CODE_SIGN_FLAGS="--timestamp" \
    build

built_app="$derived_data/Build/Products/Release/New Text File.app"
codesign --verify --deep --strict --verbose=2 "$built_app"

for signed_bundle in \
    "$built_app/Contents/PlugIns/NewTextFileFinderSync.appex" \
    "$built_app"; do
    signature_details=$(codesign --display --verbose=4 "$signed_bundle" 2>&1)
    if [[ "$signature_details" != *"Timestamp="* ]]; then
        print -u2 "Secure timestamp is missing from: $signed_bundle"
        exit 1
    fi
done

ditto "$built_app" "$package_root/Applications/New Text File.app"

pkgbuild \
    --root "$package_root" \
    --component-plist "$component_plist" \
    --scripts "$installer_scripts" \
    --identifier com.cutecatstudios.newtextfile.pkg \
    --version "$version" \
    "$build_dir/packages/NewTextFile-component.pkg"

productbuild \
    --distribution "$generated_distribution" \
    --resources "$generated_resources" \
    --package-path "$build_dir/packages" \
    "$unsigned_product"

if [[ -n "$installer_identity" ]]; then
    print "Installer signing identity: $installer_identity"
    productsign \
        --sign "$installer_identity" \
        --timestamp \
        "$unsigned_product" \
        "$final_product"
else
    print "No Developer ID Installer identity found; producing an unsigned installer."
    cp "$unsigned_product" "$final_product"
fi

if [[ -n "${NOTARY_PROFILE:-}" && -n "$installer_identity" ]]; then
    notary_args=(--keychain-profile "$NOTARY_PROFILE")
    if [[ -n "${APPLE_KEYCHAIN:-}" ]]; then
        notary_args+=(--keychain "$APPLE_KEYCHAIN")
    fi
    xcrun notarytool submit "$final_product" "${notary_args[@]}" --wait
    xcrun stapler staple "$final_product"
fi

pkgutil --check-signature "$final_product" || true
print
print "Built: $final_product"
