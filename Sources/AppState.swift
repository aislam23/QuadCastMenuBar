import SwiftUI

// MARK: - Models

enum LightingMode: String, CaseIterable, Identifiable {
    case solid, blink, cycle, wave, lightning
    var id: String { rawValue }
    var displayName: String { rawValue.capitalized }
}

enum MicSection: String, CaseIterable, Identifiable {
    case all, upper, lower
    var id: String { rawValue }
    var flag: String {
        switch self {
        case .all: return "-a"
        case .upper: return "-u"
        case .lower: return "-l"
        }
    }
}

struct ColorPreset: Identifiable {
    let id = UUID()
    let name: String
    let hex: String
    var color: Color { Color(hex: hex) }
}

// MARK: - App State

class AppState: ObservableObject {
    @AppStorage("selectedColorHex") var selectedColorHex = "ff0000"
    @AppStorage("lightingMode") var lightingMode = "solid"
    @AppStorage("brightness") var brightness = 100.0
    @AppStorage("micSection") var micSectionRaw = "all"

    @Published var isConnected = false
    @Published var lastError: String?

    private var usbMonitor = USBDeviceMonitor()
    private var systemMonitor = SystemEventMonitor()
    private let service = QuadCastService()
    private var connectivityTimer: Timer?

    var mode: LightingMode {
        get { LightingMode(rawValue: lightingMode) ?? .solid }
        set { lightingMode = newValue.rawValue }
    }

    var section: MicSection {
        get { MicSection(rawValue: micSectionRaw) ?? .all }
        set { micSectionRaw = newValue.rawValue }
    }

    static let presets: [ColorPreset] = [
        .init(name: "Red", hex: "ff0000"),
        .init(name: "Orange", hex: "ff6000"),
        .init(name: "Yellow", hex: "ffff00"),
        .init(name: "Green", hex: "00ff00"),
        .init(name: "Cyan", hex: "00ffff"),
        .init(name: "Blue", hex: "0000ff"),
        .init(name: "Purple", hex: "8b00ff"),
        .init(name: "Pink", hex: "ff00ff"),
        .init(name: "White", hex: "ffffff"),
        .init(name: "Off", hex: "000000"),
    ]

    init() {
        usbMonitor.onDeviceConnected = { [weak self] in
            guard let self else { return }
            self.isConnected = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                guard let self, self.isConnected else { return }
                self.applyCurrentSettings()
            }
        }
        usbMonitor.onDeviceDisconnected = { [weak self] in
            self?.isConnected = false
        }
        usbMonitor.startMonitoring()
        isConnected = usbMonitor.checkIfConnected()

        systemMonitor.onWake = { [weak self] in
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { [weak self] in
                guard let self, self.isConnected else { return }
                self.applyCurrentSettings()
            }
        }
        systemMonitor.startMonitoring()

        if isConnected {
            applyCurrentSettings()
        }

        // Fallback: poll every 5s in case IOKit notifications miss a connect/disconnect event
        connectivityTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { [weak self] _ in
            self?.pollConnectivity()
        }
    }

    private func pollConnectivity() {
        let nowConnected = usbMonitor.checkIfConnected()
        guard nowConnected != isConnected else { return }
        isConnected = nowConnected
        if nowConnected {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
                self?.applyCurrentSettings()
            }
        }
    }

    func applyCurrentSettings() {
        lastError = nil

        let hex = selectedColorHex
        let m = mode
        let b = Int(brightness)
        let s = section

        service.applyColor(hex: hex, mode: m, brightness: b, section: s) { [weak self] result in
            switch result {
            case .success:
                self?.isConnected = true
                self?.lastError = nil
            case .failure(let error):
                let msg = error.localizedDescription.lowercased()
                if msg.contains("isn't connected") || msg.contains("not found") || msg.contains("no such device") {
                    self?.isConnected = false
                }
                self?.lastError = error.localizedDescription
            }
        }
    }
}

// MARK: - Color Hex Extension

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }

    var hexString: String {
        guard let c = NSColor(self).usingColorSpace(.sRGB) else { return "ff0000" }
        let r = Int((c.redComponent * 255).rounded())
        let g = Int((c.greenComponent * 255).rounded())
        let b = Int((c.blueComponent * 255).rounded())
        return String(format: "%02x%02x%02x", r, g, b)
    }
}
