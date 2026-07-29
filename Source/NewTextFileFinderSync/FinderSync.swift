import Cocoa
import FinderSync

final class FinderSync: FIFinderSync {
    override init() {
        super.init()

        // Monitoring the filesystem root makes the command available in normal
        // Finder folders, the Desktop, and mounted drives.
        FIFinderSyncController.default().directoryURLs = [
            URL(fileURLWithPath: "/", isDirectory: true)
        ]
    }

    override func menu(for menuKind: FIMenuKind) -> NSMenu {
        let menu = NSMenu(title: "")
        let item = NSMenuItem(
            title: "New Text File",
            action: #selector(createTextFile(_:)),
            keyEquivalent: ""
        )
        item.image = NSImage(
            systemSymbolName: "doc.badge.plus",
            accessibilityDescription: "New Text File"
        )?.withSymbolConfiguration(
            NSImage.SymbolConfiguration(pointSize: 14, weight: .regular)
        )
        menu.addItem(item)
        return menu
    }

    @objc private func createTextFile(_ sender: Any?) {
        let controller = FIFinderSyncController.default()
        let selectedURLs = controller.selectedItemURLs() ?? []

        guard let directoryURL = destinationDirectory(
            targetedURL: controller.targetedURL(),
            selectedURLs: selectedURLs
        ) else {
            NSSound.beep()
            return
        }

        let fileManager = FileManager.default
        var candidateURL = directoryURL.appendingPathComponent("New Text File.txt")
        var number = 2

        while fileManager.fileExists(atPath: candidateURL.path) {
            candidateURL = directoryURL.appendingPathComponent(
                "New Text File \(number).txt"
            )
            number += 1
        }

        guard fileManager.createFile(
            atPath: candidateURL.path,
            contents: Data(),
            attributes: nil
        ) else {
            NSSound.beep()
            return
        }

        NSWorkspace.shared.activateFileViewerSelecting([candidateURL])
    }

    private func destinationDirectory(
        targetedURL: URL?,
        selectedURLs: [URL]
    ) -> URL? {
        // Finder supplies the displayed folder as targetedURL when its empty
        // background is clicked. If an item is targeted instead, create the
        // new document inside that folder or beside that file.
        guard let target = targetedURL ?? selectedURLs.first else {
            return nil
        }

        var isDirectory: ObjCBool = false
        if FileManager.default.fileExists(
            atPath: target.path,
            isDirectory: &isDirectory
        ), isDirectory.boolValue {
            return target
        }

        return target.deletingLastPathComponent()
    }
}
