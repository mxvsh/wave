import Foundation
import AppKit

#if canImport(Sparkle) && !APP_STORE
import Sparkle
#endif

@MainActor
final class UpdaterService: NSObject {
    static let shared = UpdaterService()

#if canImport(Sparkle) && !APP_STORE
    private lazy var updaterController = SPUStandardUpdaterController(
        startingUpdater: true,
        updaterDelegate: nil,
        userDriverDelegate: nil
    )
#endif

    private override init() {
        super.init()
    }

    var isAvailable: Bool {
#if canImport(Sparkle) && !APP_STORE
        return true
#else
        return false
#endif
    }

    func start() {
#if canImport(Sparkle) && !APP_STORE
        _ = updaterController
#endif
    }

    func checkForUpdates() {
#if canImport(Sparkle) && !APP_STORE
        updaterController.checkForUpdates(nil)
#else
        NSSound.beep()
        NSLog("[wave] Sparkle is not linked. Add Sparkle package to enable in-app updates.")
#endif
    }
}
