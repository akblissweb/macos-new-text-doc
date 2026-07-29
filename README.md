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
- Stapled with Apple’s notarization ticket.
- Checked for acceptance by macOS Gatekeeper.

## Troubleshooting

### The command does not appear

Open **New Text File** from the Applications folder and check the status shown
in the setup window. If necessary, click **Enable Finder Extension…**, enable
**New Text File** in System Settings, and then click **Check Again**.

If it is already enabled, turn the extension off and on again. Relaunching
Finder or logging out and back in can also refresh Finder’s extension list.

### The command is unavailable in a folder

Make sure you right-click an empty area inside the folder, rather than an
existing file. The destination must also allow your macOS account to create
files.

### macOS blocks the installer

Download the installer from the official links above. Public releases are
Developer ID signed and notarized by Apple. If macOS still reports a problem,
please contact Cute Cat Studios rather than bypassing its security warning.

## Support

For product information and support, visit
[Cute Cat Studios](https://cutecat.dev).

Developers who want to build the project or maintain a release can read the
[development and deployment guide](docs/DEVELOPMENT.md).

## License

Released under the [MIT License](LICENSE).

Copyright © 2026
[Cute Cat Studios](https://cutecat.dev).
