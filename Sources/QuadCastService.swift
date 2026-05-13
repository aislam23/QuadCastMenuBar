import Foundation

enum QuadCastError: LocalizedError {
    case commandFailed(String)
    case notInstalled

    var errorDescription: String? {
        switch self {
        case .commandFailed(let msg): return msg
        case .notInstalled: return "quadcastrgb not found"
        }
    }
}

class QuadCastService {
    static let binaryPath = "/usr/local/bin/quadcastrgb"
    private let queue = DispatchQueue(label: "com.quadcastrgb.serial")
    private var currentProcess: Process?

    static var isAvailable: Bool {
        FileManager.default.isExecutableFile(atPath: binaryPath)
    }

    func applyColor(hex: String, mode: LightingMode, brightness: Int, section: MicSection, completion: @escaping (Result<Void, Error>) -> Void) {
        guard Self.isAvailable else {
            completion(.failure(QuadCastError.notInstalled))
            return
        }

        queue.async { [self] in
            // Kill previous process to release USB
            killCurrent()

            let args = [section.flag, "-b", String(brightness), mode.rawValue, hex]


            let process = Process()
            process.executableURL = URL(fileURLWithPath: Self.binaryPath)
            process.arguments = args
            let pipe = Pipe()
            process.standardOutput = pipe
            process.standardError = pipe
            currentProcess = process

            do {
                try process.run()
            } catch {
                currentProcess = nil

                DispatchQueue.main.async { completion(.failure(error)) }
                return
            }

            // Wait up to 2 seconds to see if it exits with an error
            // If still running after 2s, it's maintaining the color — that's OK
            let deadline = Date().addingTimeInterval(2)
            while process.isRunning && Date() < deadline {
                Thread.sleep(forTimeInterval: 0.05)
            }

            if process.isRunning {
                // Process is still running = it's actively maintaining the color

                DispatchQueue.main.async { completion(.success(())) }
            } else if process.terminationStatus == 0 {
                // Exited cleanly (e.g. solid mode)
                currentProcess = nil

                DispatchQueue.main.async { completion(.success(())) }
            } else {
                // Exited with error
                currentProcess = nil
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

                DispatchQueue.main.async { completion(.failure(QuadCastError.commandFailed(output.isEmpty ? "Exit code \(process.terminationStatus)" : output))) }
            }
        }
    }

    private func killCurrent() {
        guard let proc = currentProcess, proc.isRunning else {
            currentProcess = nil
            return
        }

        proc.terminate()
        // Wait for it to release USB
        let deadline = Date().addingTimeInterval(1)
        while proc.isRunning && Date() < deadline {
            Thread.sleep(forTimeInterval: 0.05)
        }
        if proc.isRunning {
            kill(proc.processIdentifier, SIGKILL)
            Thread.sleep(forTimeInterval: 0.1)
        }
        currentProcess = nil
        // Extra pause for USB device to become available
        Thread.sleep(forTimeInterval: 0.3)
    }
}
