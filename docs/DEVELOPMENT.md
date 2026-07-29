# Development and deployment

This guide is for Cute Cat Studios maintainers and developers building New Text
File from source. Customer installation and usage instructions belong in the
main [README](../README.md).

## Requirements

- macOS 13 or later
- Xcode with the macOS SDK
- Node.js and npm when using the FTPS deployment workflow
- Cute Cat Studios Developer ID certificates and Apple notarization credentials
  for a public release

## Building from source

Clone the repository and run the package builder:

```sh
git clone https://github.com/akblissweb/macos-new-text-doc.git
cd macos-new-text-doc
./Scripts/build-package.sh
```

The semantic release version comes from [`VERSION`](../VERSION). Output is
written to:

```text
Builds/New Text File Installer x.y.z.pkg
```

The app and Finder extension are built as universal Mach-O binaries containing
both `arm64` and `x86_64`. One package therefore covers supported Apple-silicon
and Intel Macs.

Without Developer ID identities, the script produces an ad-hoc-signed
application and unsigned Installer package for local testing. Do not distribute
that build as a public release.

## Signed and notarized builds

Run the build from the macOS account whose keychain contains:

- `Developer ID Application`
- `Developer ID Installer`
- A stored `notarytool` credentials profile

The build script discovers the signing identities automatically:

```sh
NOTARY_PROFILE="your-notary-profile" ./Scripts/build-package.sh
```

They can also be selected explicitly:

```sh
APP_SIGN_IDENTITY="Developer ID Application: Cute Cat Studios (TEAMID)" \
INSTALLER_SIGN_IDENTITY="Developer ID Installer: Cute Cat Studios (TEAMID)" \
NOTARY_PROFILE="your-notary-profile" \
./Scripts/build-package.sh
```

## Release deployment

The release workflow is implemented in
[`Scripts/deploy-release.js`](../Scripts/deploy-release.js). It:

1. Requires the configured macOS release account (`cutecat` by default).
2. Builds fresh universal `arm64` and `x86_64` binaries.
3. Developer ID signs the app, extension, and Installer package.
4. Submits the package to Apple and waits for notarization.
5. Staples and validates the notarization ticket.
6. Verifies signatures, hardened runtime, architectures, and Gatekeeper
   acceptance.
7. Names the release `new-text-file-x.y.z-release.pkg`.
8. Uploads it to Area90 over FTPS and verifies the remote byte count.
9. Uploads `latest-release.php`, which redirects to the highest semantic
   version.

### Initial setup

Copy the environment template, add the Apple and Area90 credentials, and install
the Node.js dependency:

```sh
cp .env.example .env
npm install
```

Real credentials belong only in `.env`. It is excluded from Git.

### Commands

Before starting a release, bump all version metadata together:

```sh
npm run bump-version -- patch
```

Use `minor` or `major` in place of `patch` when appropriate. Review, commit,
and push the version change before publishing.

Build, notarize, verify, and publish the package to both GitHub Releases and
the area90 mirror:

```sh
npm run release
```

The command builds only once. It creates or updates `vX.Y.Z`, uploads the
versioned universal package, a stable `new-text-file-latest.pkg` alias, and its
SHA-256 checksum, marks it as the latest GitHub release, and uploads the same
verified versioned package to area90. Signing and notarization stay local, so
the Developer ID private keys do not need to be stored in GitHub Actions.

Build, verify, and upload an optional mirror to area90:

```sh
npm run deploy
```

Build and verify without uploading:

```sh
npm run deploy -- --no-upload
```

Verify and upload the already-built current version to area90:

```sh
npm run upload
```

The optional mirror directory is:

```text
https://area90.com/releases/new-text-file/
```

The stable latest-release redirect is:

```text
https://area90.com/releases/new-text-file/latest-release.php?action=redirect
```

## Repository layout

```text
Installer/     Installer distribution definition, branded pages, and artwork
Scripts/       Local build, release deployment, and latest-release endpoint
Source/        Xcode project, settings launcher, and Finder Sync extension
docs/          Maintainer documentation
VERSION        Canonical semantic release version
```
