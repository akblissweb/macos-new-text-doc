<p align="center">
  <img src="Installer/Resources/CuteCatStudiosLogo.png" width="210" alt="Cute Cat Studios">
</p>

<h1 align="center">New Text File for Finder</h1>

<p align="center">
  A native Finder extension that adds the missing <strong>New Text File</strong>
  command to macOS.
  <br>
  Published by <a href="https://cutecat.dev">Cute Cat Studios</a>.
</p>

## What it does

New Text File adds a command to Finder’s background contextual menu. Open any
folder, right-click an empty area, and select **New Text File** to create an
empty plain-text document in that folder.

- Creates `New Text File.txt`.
- Avoids overwriting existing files.
- Automatically uses `New Text File 2.txt`, `New Text File 3.txt`, and so on.
- Selects the new document in Finder after creating it.
- Works in normal Finder folders, on the Desktop, and on mounted drives.
- Includes a setup app that checks whether the Finder extension is enabled.
- Does not install a daemon, login item, browser extension, or background app.
- Does not collect analytics or transmit file information.

## System requirements

| Requirement | Support |
|---|---|
| Minimum macOS | macOS 13 Ventura |
| Newer macOS | Sonoma, Sequoia, Tahoe, and compatible later releases |
| Apple silicon | Native `arm64` |
| Intel Macs | Native `x86_64` |
| Package format | Signed and notarized universal macOS `.pkg` |

The app and Finder extension are both universal Mach-O binaries. One installer
covers supported Intel and Apple-silicon Macs; separate architecture downloads
are not required.

## Installation

1. Download the latest `new-text-file-x.y.z-release.pkg` from
   [GitHub Releases](https://github.com/akblissweb/macos-new-text-doc/releases)
   or the [Cute Cat Studios release server](https://area90.com/releases/new-text-file/).
2. Open the package and complete the macOS Installer.
3. Open **New Text File** from `/Applications`.
4. If the setup window says the extension is disabled, click
   **Enable Finder Extension…**.
5. Enable **New Text File** in the Finder Extensions section of System Settings.
6. Return to the setup app and click **Check Again**.

macOS requires Finder extensions to be approved per user. This one-time step
cannot be silently bypassed by an installer.

## Using it

1. Open a folder in Finder.
2. Right-click or Control-click an empty area inside the folder.
3. Choose **New Text File**.
4. Rename the selected document if desired.

The command also appears when Finder is showing the Desktop. If an existing
document already uses the default name, the extension selects the next
available numbered name.

## Updating

Download and run the newer installer. It replaces the application in
`/Applications` while preserving the user’s Finder-extension preference where
macOS permits it.

## Uninstalling

1. Disable **New Text File** under Finder Extensions in System Settings.
2. Move `/Applications/New Text File.app` to the Trash.

The app stores no document database or user account, so no additional data
cleanup is needed.

## Privacy and security

The installed software performs one local operation: creating an empty file in
the Finder folder where the command was invoked. It does not read document
contents, track usage, contact a server, or run continuously outside Finder’s
extension host. The optional Cute Cat Studios link in the setup window opens
`https://cutecat.dev` only when clicked.

Public releases are:

- Signed with **Developer ID Application** and **Developer ID Installer**
  certificates.
- Built with the hardened runtime.
- Submitted to Apple’s notarization service.
- Stapled with the resulting notarization ticket.
- Verified with `codesign`, `pkgutil`, `stapler`, and Gatekeeper’s `spctl`.

## Building from source

Requirements:

- macOS 13 or later
- Xcode with the macOS SDK
- Node.js and npm only when using the FTPS deployment workflow

Create an unsigned local test installer:

```sh
git clone https://github.com/akblissweb/macos-new-text-doc.git
cd macos-new-text-doc
./Scripts/build-package.sh
```

The semantic release version comes from [`VERSION`](VERSION). The output is:

```text
Builds/New Text File Installer x.y.z.pkg
```

Without Developer ID identities, the build script intentionally produces an
ad-hoc-signed application and unsigned package suitable for local testing.

### Signed and notarized build

Run the build while logged into the macOS account whose keychain contains:

- `Developer ID Application`
- `Developer ID Installer`
- A stored `notarytool` credentials profile

```sh
NOTARY_PROFILE="your-notary-profile" ./Scripts/build-package.sh
```

The identities are discovered automatically. They may also be selected
explicitly:

```sh
APP_SIGN_IDENTITY="Developer ID Application: Cute Cat Studios (TEAMID)" \
INSTALLER_SIGN_IDENTITY="Developer ID Installer: Cute Cat Studios (TEAMID)" \
NOTARY_PROFILE="your-notary-profile" \
./Scripts/build-package.sh
```

## Release deployment

The release workflow mirrors the CatnipTV deploy process. It:

1. Requires the configured macOS release account (`cutecat` by default).
2. Builds fresh universal `arm64` and `x86_64` binaries.
3. Developer ID–signs the app, extension, and Installer package.
4. Submits the package for Apple notarization and waits for acceptance.
5. Staples and validates the notarization ticket.
6. Verifies the app signature, hardened runtime, package signature, both
   architectures, and Gatekeeper acceptance.
7. Names the release `new-text-file-x.y.z-release.pkg`.
8. Uploads it to Area90 over FTPS.
9. Verifies the uploaded byte count.
10. Uploads `latest-release.php`, which redirects to the highest semantic
    version.

Set up the deployer:

```sh
cp .env.example .env
# Add the notary profile and Area90 FTPS credentials to .env.
npm install
```

Build, verify, and upload:

```sh
npm run deploy
```

Build and verify without uploading:

```sh
npm run deploy -- --no-upload
```

Verify and upload the already-built current version:

```sh
npm run upload
```

The default public release location is:

```text
https://area90.com/releases/new-text-file/
```

The stable latest-release redirect is:

```text
https://area90.com/releases/new-text-file/latest-release.php?action=redirect
```

Real credentials belong only in `.env`, which is excluded from Git.

## Repository layout

```text
Installer/     Installer distribution definition, branded pages, and artwork
Scripts/       Local build, release deployment, and latest-release endpoint
Source/        Xcode project, setup application, and Finder Sync extension
VERSION        Canonical semantic release version
```

## License

Released under the [MIT License](LICENSE).

Copyright © 2026
[Cute Cat Studios](https://cutecat.dev).
