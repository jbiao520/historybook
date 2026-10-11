import Foundation

enum ContentLocation {
    /// Finds the bundled content directory copied from `Sources/Historybook/Content`.
    static func resolve() -> URL? {
        let fileManager = FileManager.default
        var candidates: [URL] = []

        if let resourceURL = Bundle.main.resourceURL {
            candidates.append(resourceURL.appendingPathComponent("Content"))
            candidates.append(
                resourceURL
                    .appendingPathComponent("Historybook_Historybook.bundle/Contents/Resources/Content")
            )
            candidates.append(
                resourceURL.appendingPathComponent("Historybook_Historybook.bundle/Content")
            )
        }

        if let executableURL = Bundle.main.executableURL {
            let folder = executableURL.deletingLastPathComponent()
            candidates.append(
                folder
                    .appendingPathComponent("Historybook_Historybook.bundle/Contents/Resources/Content")
            )
            candidates.append(folder.appendingPathComponent("Historybook_Historybook.bundle/Content"))
            candidates.append(folder.appendingPathComponent("Content"))

            var walk = folder
            for _ in 0..<8 {
                candidates.append(walk.appendingPathComponent("Sources/Historybook/Content"))
                walk.deleteLastPathComponent()
            }
        }

        let workingDirectory = URL(fileURLWithPath: fileManager.currentDirectoryPath)
        candidates.append(workingDirectory.appendingPathComponent("Sources/Historybook/Content"))

        return candidates.first { candidate in
            fileManager.fileExists(atPath: candidate.appendingPathComponent("metadata").path)
        }
    }
}
