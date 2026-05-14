import Foundation
import IOKit

class USBDeviceMonitor {
    var onDeviceConnected: (() -> Void)?
    var onDeviceDisconnected: (() -> Void)?

    private var notifyPort: IONotificationPortRef?
    private var iterators: [io_iterator_t] = []

    // (vendorID, productID) pairs — sourced from Ors1mer/QuadcastRGB devio.c
    private static let devices: [(vendor: Int, product: Int)] = [
        (0x0951, 0x171f), // QuadCast S (Kingston)
        (0x03f0, 0x0f8b), // QuadCast S (HP)
        (0x03f0, 0x028c), // QuadCast S (HP variant)
        (0x03f0, 0x048c), // QuadCast S (HP variant)
        (0x03f0, 0x068c), // QuadCast S (HP variant)
        (0x03f0, 0x098c), // DuoCast
        (0x03f0, 0x09af), // QuadCast 2
        (0x03f0, 0x02b5), // QuadCast 2S
    ]

    func startMonitoring() {
        notifyPort = IONotificationPortCreate(kIOMainPortDefault)
        guard let port = notifyPort else { return }

        let source = IONotificationPortGetRunLoopSource(port).takeUnretainedValue()
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .defaultMode)

        let refcon = Unmanaged.passUnretained(self).toOpaque()

        for dev in Self.devices {
            var addIter: io_iterator_t = 0
            if let dict = Self.createMatchingDict(vendorID: dev.vendor, productID: dev.product) {
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

            var rmIter: io_iterator_t = 0
            if let dict = Self.createMatchingDict(vendorID: dev.vendor, productID: dev.product) {
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
        for dev in Self.devices {
            guard let dict = Self.createMatchingDict(vendorID: dev.vendor, productID: dev.product) else { continue }
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

    private static func createMatchingDict(vendorID: Int, productID: Int) -> CFMutableDictionary? {
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
