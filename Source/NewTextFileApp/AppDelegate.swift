import Cocoa
import FinderSync

@main
final class AppDelegate: NSObject, NSApplicationDelegate {
    private static let sharedDelegate = AppDelegate()

    static func main() {
        let application = NSApplication.shared
        application.setActivationPolicy(.accessory)
        application.delegate = sharedDelegate
        application.run()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        FIFinderSyncController.showExtensionManagementInterface()

        // Give System Settings time to receive the request before this
        // launcher exits. The Finder extension continues independently.
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            NSApp.terminate(nil)
        }
    }

    func applicationSupportsSecureRestorableState(
        _ app: NSApplication
    ) -> Bool {
        true
    }
}
