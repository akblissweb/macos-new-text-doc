import Cocoa
import FinderSync

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow!
    private var statusIcon: NSImageView!
    private var statusTitle: NSTextField!
    private var statusDetail: NSTextField!
    private var primaryButton: NSButton!

    func applicationDidFinishLaunching(_ notification: Notification) {
        buildWindow()
        refreshStatus()
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func applicationDidBecomeActive(_ notification: Notification) {
        refreshStatus()
    }

    func applicationShouldTerminateAfterLastWindowClosed(
        _ sender: NSApplication
    ) -> Bool {
        true
    }

    private func buildWindow() {
        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 560, height: 500),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = "New Text File"
        window.center()
        window.isReleasedWhenClosed = false

        let content = NSView()
        content.translatesAutoresizingMaskIntoConstraints = false
        window.contentView = content

        let appIcon = NSImageView()
        appIcon.translatesAutoresizingMaskIntoConstraints = false
        appIcon.image = NSImage(
            systemSymbolName: "doc.badge.plus",
            accessibilityDescription: "New text document"
        )
        appIcon.symbolConfiguration = NSImage.SymbolConfiguration(
            pointSize: 62,
            weight: .regular
        )
        appIcon.contentTintColor = .controlAccentColor

        let title = label(
            "New Text File for Finder",
            font: .systemFont(ofSize: 27, weight: .semibold),
            color: .labelColor
        )
        let subtitle = label(
            "Create an empty .txt document directly from Finder’s right-click menu.",
            font: .systemFont(ofSize: 14),
            color: .secondaryLabelColor
        )

        let statusBox = NSBox()
        statusBox.translatesAutoresizingMaskIntoConstraints = false
        statusBox.boxType = .custom
        statusBox.cornerRadius = 12
        statusBox.borderWidth = 1
        statusBox.borderColor = .separatorColor
        statusBox.fillColor = .controlBackgroundColor

        statusIcon = NSImageView()
        statusIcon.translatesAutoresizingMaskIntoConstraints = false
        statusTitle = label(
            "",
            font: .systemFont(ofSize: 17, weight: .semibold),
            color: .labelColor
        )
        statusDetail = label(
            "",
            font: .systemFont(ofSize: 13),
            color: .secondaryLabelColor
        )
        statusDetail.maximumNumberOfLines = 2

        let statusText = NSStackView(views: [statusTitle, statusDetail])
        statusText.orientation = .vertical
        statusText.alignment = .leading
        statusText.spacing = 4
        statusText.translatesAutoresizingMaskIntoConstraints = false

        statusBox.contentView?.addSubview(statusIcon)
        statusBox.contentView?.addSubview(statusText)
        NSLayoutConstraint.activate([
            statusIcon.leadingAnchor.constraint(
                equalTo: statusBox.contentView!.leadingAnchor,
                constant: 18
            ),
            statusIcon.centerYAnchor.constraint(
                equalTo: statusBox.contentView!.centerYAnchor
            ),
            statusIcon.widthAnchor.constraint(equalToConstant: 30),
            statusIcon.heightAnchor.constraint(equalToConstant: 30),
            statusText.leadingAnchor.constraint(
                equalTo: statusIcon.trailingAnchor,
                constant: 14
            ),
            statusText.trailingAnchor.constraint(
                equalTo: statusBox.contentView!.trailingAnchor,
                constant: -18
            ),
            statusText.centerYAnchor.constraint(
                equalTo: statusBox.contentView!.centerYAnchor
            ),
            statusBox.heightAnchor.constraint(equalToConstant: 86)
        ])

        let howToTitle = label(
            "How to use it",
            font: .systemFont(ofSize: 15, weight: .semibold),
            color: .labelColor
        )
        let howTo = label(
            "Open any Finder folder, right-click an empty area, then choose “New Text File.” Duplicate names are numbered automatically.",
            font: .systemFont(ofSize: 13),
            color: .secondaryLabelColor
        )
        howTo.maximumNumberOfLines = 3

        primaryButton = NSButton(
            title: "Enable Finder Extension…",
            target: self,
            action: #selector(primaryAction)
        )
        primaryButton.bezelStyle = .rounded
        primaryButton.keyEquivalent = "\r"
        primaryButton.controlSize = .large

        let checkButton = NSButton(
            title: "Check Again",
            target: self,
            action: #selector(checkAgain)
        )
        checkButton.bezelStyle = .rounded
        checkButton.controlSize = .large

        let buttons = NSStackView(views: [primaryButton, checkButton])
        buttons.orientation = .horizontal
        buttons.alignment = .centerY
        buttons.spacing = 10

        let publisherButton = NSButton(
            title: "Cute Cat Studios  •  cutecat.dev",
            target: self,
            action: #selector(openPublisherWebsite)
        )
        publisherButton.isBordered = false
        publisherButton.font = .systemFont(ofSize: 12)
        publisherButton.contentTintColor = .linkColor
        publisherButton.toolTip = "Visit Cute Cat Studios"

        let stack = NSStackView(
            views: [
                appIcon,
                title,
                subtitle,
                statusBox,
                howToTitle,
                howTo,
                buttons,
                publisherButton
            ]
        )
        stack.orientation = .vertical
        stack.alignment = .centerX
        stack.spacing = 12
        stack.setCustomSpacing(22, after: subtitle)
        stack.setCustomSpacing(22, after: statusBox)
        stack.setCustomSpacing(18, after: howTo)
        stack.setCustomSpacing(16, after: buttons)
        stack.translatesAutoresizingMaskIntoConstraints = false
        content.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: content.leadingAnchor, constant: 46),
            stack.trailingAnchor.constraint(equalTo: content.trailingAnchor, constant: -46),
            stack.centerYAnchor.constraint(equalTo: content.centerYAnchor),
            appIcon.widthAnchor.constraint(equalToConstant: 78),
            appIcon.heightAnchor.constraint(equalToConstant: 78),
            subtitle.widthAnchor.constraint(equalTo: stack.widthAnchor),
            statusBox.widthAnchor.constraint(equalTo: stack.widthAnchor),
            howToTitle.widthAnchor.constraint(equalTo: stack.widthAnchor),
            howTo.widthAnchor.constraint(equalTo: stack.widthAnchor)
        ])
    }

    private func label(
        _ text: String,
        font: NSFont,
        color: NSColor
    ) -> NSTextField {
        let field = NSTextField(labelWithString: text)
        field.font = font
        field.textColor = color
        field.alignment = .center
        field.lineBreakMode = .byWordWrapping
        return field
    }

    private func refreshStatus() {
        guard statusIcon != nil else { return }

        let enabled = FIFinderSyncController.isExtensionEnabled
        let symbol = enabled ? "checkmark.circle.fill" : "exclamationmark.circle.fill"
        statusIcon.image = NSImage(
            systemSymbolName: symbol,
            accessibilityDescription: enabled ? "Enabled" : "Action required"
        )
        statusIcon.symbolConfiguration = NSImage.SymbolConfiguration(
            pointSize: 27,
            weight: .medium
        )
        statusIcon.contentTintColor = enabled ? .systemGreen : .systemOrange

        if enabled {
            statusTitle.stringValue = "Ready to use"
            statusDetail.stringValue =
                "The Finder extension is enabled and available in monitored folders."
            primaryButton.title = "Open Finder"
        } else {
            statusTitle.stringValue = "One quick step remains"
            statusDetail.stringValue =
                "Enable “New Text File” under Finder Extensions in System Settings."
            primaryButton.title = "Enable Finder Extension…"
        }
    }

    @objc private func primaryAction() {
        if FIFinderSyncController.isExtensionEnabled {
            NSWorkspace.shared.open(
                FileManager.default.homeDirectoryForCurrentUser
            )
        } else {
            FIFinderSyncController.showExtensionManagementInterface()
        }
    }

    @objc private func checkAgain() {
        refreshStatus()
    }

    @objc private func openPublisherWebsite() {
        NSWorkspace.shared.open(URL(string: "https://cutecat.dev")!)
    }
}
