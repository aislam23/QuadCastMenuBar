import SwiftUI
import ServiceManagement

struct ContentView: View {
    @ObservedObject var appState: AppState
    @State private var customColor = Color.red
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    private let columns = Array(repeating: GridItem(.fixed(32), spacing: 8), count: 5)

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Status
            HStack(spacing: 6) {
                Circle()
                    .fill(appState.isConnected ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                Text(appState.isConnected ? "QuadCast S" : "Not Connected")
                    .font(.headline)
                Spacer()
            }

            if let error = appState.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .lineLimit(2)
            }

            Divider()

            // Color presets
            Text("Color")
                .font(.subheadline)
                .foregroundColor(.secondary)

            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(AppState.presets) { preset in
                    ColorButton(
                        preset: preset,
                        isSelected: appState.selectedColorHex == preset.hex
                    ) {
                        appState.selectedColorHex = preset.hex
                        appState.applyCurrentSettings()
                    }
                }
            }

            ColorPicker("Custom Color", selection: $customColor, supportsOpacity: false)
                .onChange(of: customColor) { _, newValue in
                    appState.selectedColorHex = newValue.hexString
                    appState.applyCurrentSettings()
                }

            Divider()

            // Mode
            Picker("Mode", selection: Binding(
                get: { appState.mode },
                set: {
                    appState.mode = $0
                    appState.applyCurrentSettings()
                }
            )) {
                ForEach(LightingMode.allCases) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.menu)

            // Brightness
            HStack {
                Text("Brightness")
                    .frame(width: 70, alignment: .leading)
                Slider(value: $appState.brightness, in: 0...100, step: 5) { editing in
                    if !editing { appState.applyCurrentSettings() }
                }
                Text("\(Int(appState.brightness))%")
                    .frame(width: 36, alignment: .trailing)
                    .monospacedDigit()
            }

            // Section
            Picker("Section", selection: Binding(
                get: { appState.section },
                set: {
                    appState.section = $0
                    appState.applyCurrentSettings()
                }
            )) {
                ForEach(MicSection.allCases) { s in
                    Text(s.rawValue.capitalized).tag(s)
                }
            }
            .pickerStyle(.segmented)

            Divider()

            Toggle("Launch at Login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, newValue in
                    do {
                        if newValue {
                            try SMAppService.mainApp.register()
                        } else {
                            try SMAppService.mainApp.unregister()
                        }
                    } catch {
                        launchAtLogin = !newValue
                    }
                }

            Button("Quit QuadCast RGB") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q")
        }
        .padding()
        .frame(width: 260)
    }
}

// MARK: - Color Button

struct ColorButton: View {
    let preset: ColorPreset
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(preset.color)
                    .frame(width: 28, height: 28)
                if preset.hex == "000000" {
                    Circle()
                        .stroke(Color.gray.opacity(0.5), lineWidth: 1)
                        .frame(width: 28, height: 28)
                }
                if isSelected {
                    Circle()
                        .stroke(Color.accentColor, lineWidth: 2.5)
                        .frame(width: 34, height: 34)
                }
            }
        }
        .buttonStyle(.plain)
        .help(preset.name)
    }
}
