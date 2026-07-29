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
        menu.addItem(
            withTitle: "New Text File",
            action: #selector(createTextFile(_:)),
            keyEquivalent: ""
        )
        return menu
    }

    @objc private func createTextFile(_ sender: Any?) {
        let controller = FIFinderSyncController.default()
        let selectedURLs = controller.selectedItemURLs() ?? []

        let directoryURL: URL
        if let selectedURL = selectedURLs.first {
            directoryURL = selectedURL.deletingLastPathComponent()
        } else if let targetedURL = controller.targetedURL() {
            var isDirectory: ObjCBool = false
            if FileManager.default.fileExists(
                atPath: targetedURL.path,
                isDirectory: &isDirectory
            ), isDirectory.boolValue {
                directoryURL = targetedURL
            } else {
                directoryURL = targetedURL.deletingLastPathComponent()
            }
        } else {
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
}
