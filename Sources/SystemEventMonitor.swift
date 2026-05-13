import Foundation
import AppKit

class SystemEventMonitor {
    var onWake: (() -> Void)?

    func startMonitoring() {
        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didWakeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            // Delay to let USB re-enumerate after wake
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self?.onWake?()
            }
        }
    }
}
