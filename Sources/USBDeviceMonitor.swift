import Foundation
import IOKit

class USBDeviceMonitor {
    var onDeviceConnected: (() -> Void)?
    var onDeviceDisconnected: (() -> Void)?

    private var notifyPort: IONotificationPortRef?
    private var iterators: [io_iterator_t] = []

    private static let vendorID: Int = 0x0951  // Kingston / HyperX
    private static let productIDs: [Int] = [5919, 5917]  // QuadCast S variants

    func startMonitoring() {
        notifyPort = IONotificationPortCreate(kIOMainPortDefault)
        guard let port = notifyPort else { return }

        let source = IONotificationPortGetRunLoopSource(port).takeUnretainedValue()
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)

        let refcon = Unmanaged.passUnretained(self).toOpaque()

        for pid in Self.productIDs {
            // Device connected
            var addIter: io_iterator_t = 0
            if let dict = Self.createMatchingDict(productID: pid) {
                IOServiceAddMatchingNotification(
                    port, "IOServiceFirstMatch", dict,
                    { ctx, iter in
                        let mon = Unmanaged<USBDeviceMonitor>.fromOpaque(ctx!).takeUnretainedValue()
                        mon.onDeviceEvent(iter, connected: true)
                    },
                    refcon, &addIter
                )
                drainIterator(addIter)
                iterators.append(addIter)
            }

            // Device disconnected
            var rmIter: io_iterator_t = 0
            if let dict = Self.createMatchingDict(productID: pid) {
                IOServiceAddMatchingNotification(
                    port, "IOServiceTerminate", dict,
                    { ctx, iter in
                        let mon = Unmanaged<USBDeviceMonitor>.fromOpaque(ctx!).takeUnretainedValue()
                        mon.onDeviceEvent(iter, connected: false)
                    },
                    refcon, &rmIter
                )
                drainIterator(rmIter)
                iterators.append(rmIter)
            }
        }
    }

    func checkIfConnected() -> Bool {
        for pid in Self.productIDs {
            guard let dict = Self.createMatchingDict(productID: pid) else { continue }
            let service = IOServiceGetMatchingService(kIOMainPortDefault, dict)
            if service != IO_OBJECT_NULL {
                IOObjectRelease(service)
                return true
            }
        }
        return false
    }

    // MARK: - Private

    private func onDeviceEvent(_ iterator: io_iterator_t, connected: Bool) {
        drainIterator(iterator)
        DispatchQueue.main.async { [weak self] in
            if connected {
                self?.onDeviceConnected?()
            } else {
                self?.onDeviceDisconnected?()
            }
        }
    }

    private func drainIterator(_ iterator: io_iterator_t) {
        while case let device = IOIteratorNext(iterator), device != IO_OBJECT_NULL {
            IOObjectRelease(device)
        }
    }

    private static func createMatchingDict(productID: Int) -> CFMutableDictionary? {
        guard let dict = IOServiceMatching("IOUSBHostDevice") else { return nil }
        let nsDict = dict as NSMutableDictionary
        nsDict["idVendor"] = vendorID
        nsDict["idProduct"] = productID
        return dict
    }

    deinit {
        for iter in iterators { IOObjectRelease(iter) }
        if let port = notifyPort { IONotificationPortDestroy(port) }
    }
}
