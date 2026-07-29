#!/bin/bash

# Keep the canonical VERSION file and npm metadata on the same semantic version.
# Usage: npm run bump-version -- major|minor|patch

set -euo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
project_root="$(cd "$script_dir/.." && pwd)"
version_file="$project_root/VERSION"
package_json="$project_root/package.json"
package_lock="$project_root/package-lock.json"

usage() {
    echo "Usage: npm run bump-version -- major|minor|patch"
    echo
    echo "Current version: $(tr -d '[:space:]' < "$version_file")"
}

if [ "$#" -ne 1 ] || ! [[ "$1" =~ ^(major|minor|patch)$ ]]; then
    echo "Error: exactly one bump type is required." >&2
    usage
    exit 1
fi

current_version="$(tr -d '[:space:]' < "$version_file")"
package_version="$(node -p "require('$package_json').version")"
lock_version="$(node -p "require('$package_lock').packages[''].version")"

if ! [[ "$current_version" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Error: VERSION must contain x.y.z; got '$current_version'." >&2
    exit 1
fi

if [ "$current_version" != "$package_version" ] ||
   [ "$current_version" != "$lock_version" ]; then
    echo "Error: VERSION, package.json, and package-lock.json are out of sync." >&2
    echo "VERSION=$current_version package.json=$package_version package-lock.json=$lock_version" >&2
    exit 1
fi

IFS=. read -r major minor patch <<< "$current_version"
case "$1" in
    major)
        new_version="$((10#$major + 1)).0.0"
        ;;
    minor)
        new_version="$major.$((10#$minor + 1)).0"
        ;;
    patch)
        new_version="$major.$minor.$((10#$patch + 1))"
        ;;
esac

printf '%s\n' "$new_version" > "$version_file"
(cd "$project_root" && npm version "$new_version" --no-git-tag-version >/dev/null)

echo "Version bumped: $current_version -> $new_version"
echo
echo "Next:"
echo "  1. Review and commit the version files."
echo "  2. Push the commit."
echo "  3. Run npm run release."
