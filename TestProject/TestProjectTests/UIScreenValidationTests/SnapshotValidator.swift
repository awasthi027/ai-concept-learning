//
//  SnapshotValidator.swift
//  TestProject
//
//  Reusable snapshot validation helper for SwiftUI screens.
//

import SwiftUI
import UIKit
import Testing

enum SnapshotError: Error, CustomStringConvertible {
    case referenceMissing(URL)
    case sizeMismatch(reference: CGSize, actual: CGSize)
    case mismatch(difference: Double, tolerance: Double, actual: URL)

    var description: String {
        switch self {
        case .referenceMissing(let url):
            return "Reference snapshot not found at \(url.path). Run once with SNAPSHOT_RECORD=1 to record it."
        case .sizeMismatch(let reference, let actual):
            return "Snapshot size mismatch. reference=\(reference) actual=\(actual)."
        case .mismatch(let difference, let tolerance, let actual):
            return String(format: "Snapshot differs by %.4f (tolerance %.4f). Failure image written to %@", difference, tolerance, actual.path)
        }
    }
}

enum SnapshotValidator {

    /// Renders `view` and compares it against a reference image stored in
    /// `Screenshots/<folder>/<name>_<device>.png` (relative to this source file).
    /// - If the reference is missing (or SNAPSHOT_RECORD=1), the current render is written and the test fails.
    /// - Otherwise the render is compared pixel-by-pixel against the reference within `tolerance`.
    @MainActor
    static func validate(
        _ view: some View,
        folder: String,
        name: String,
        size: CGSize? = nil,
        tolerance: Double = 0.02,
        sourceFile: String = #filePath
    ) throws {
        let renderSize = size ?? currentScreen()?.bounds.size ?? CGSize(width: 393, height: 852)
        let actualImage = render(view, size: renderSize)

        let referenceURL = referenceURL(folder: folder, name: name, sourceFile: sourceFile)
        let fileManager = FileManager.default

        let shouldRecord = ProcessInfo.processInfo.environment["SNAPSHOT_RECORD"] == "1"

        if shouldRecord || !fileManager.fileExists(atPath: referenceURL.path) {
            try write(actualImage, to: referenceURL)
            throw SnapshotError.referenceMissing(referenceURL)
        }

        guard
            let referenceData = try? Data(contentsOf: referenceURL),
            let referenceImage = UIImage(data: referenceData)
        else {
            throw SnapshotError.referenceMissing(referenceURL)
        }

        let difference = try pixelDifference(reference: referenceImage, actual: actualImage)

        if difference > tolerance {
            let failureURL = referenceURL
                .deletingLastPathComponent()
                .appendingPathComponent("\(name)_\(deviceName())_FAILED.png")
            _ = try? write(actualImage, to: failureURL)
            throw SnapshotError.mismatch(difference: difference, tolerance: tolerance, actual: failureURL)
        }
    }

    // MARK: - Rendering

    @MainActor
    static func render(_ view: some View, size: CGSize) -> UIImage {
        let controller = UIHostingController(rootView: view)

        let bounds = CGRect(origin: .zero, size: size)
        let window = makeWindow()
        window.frame = bounds

        controller.view.frame = bounds
        controller.view.backgroundColor = .systemBackground
        window.rootViewController = controller
        window.makeKeyAndVisible()

        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        RunLoop.main.run(until: Date().addingTimeInterval(0.1))

        let format = UIGraphicsImageRendererFormat(for: controller.traitCollection)
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { _ in
            controller.view.drawHierarchy(in: controller.view.bounds, afterScreenUpdates: true)
        }
    }

    @MainActor
    static func makeWindow() -> UIWindow {
        if let scene = activeWindowScene() {
            return UIWindow(windowScene: scene)
        }
        // No active scene should never happen in a hosted test run, but keep a
        // non-deprecated fallback by reusing an existing window's scene.
        if let existing = UIApplication.shared.connectedScenes
            .compactMap({ ($0 as? UIWindowScene)?.windows.first })
            .first {
            return existing
        }
        preconditionFailure("SnapshotValidator.render requires an active UIWindowScene (run inside a hosted test target).")
    }

    @MainActor
    static func activeWindowScene() -> UIWindowScene? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first
    }

    /// Returns the screen backing the current active window scene, avoiding the
    /// deprecated `UIScreen.main`.
    @MainActor
    static func currentScreen() -> UIScreen? {
        activeWindowScene()?.screen
    }

    // MARK: - Comparison

    /// Returns the fraction of pixels (0...1) that differ beyond a small per-channel threshold.
    static func pixelDifference(reference: UIImage, actual: UIImage) throws -> Double {
        guard let refCG = reference.cgImage, let actCG = actual.cgImage else {
            throw SnapshotError.sizeMismatch(reference: reference.size, actual: actual.size)
        }

        guard refCG.width == actCG.width, refCG.height == actCG.height else {
            throw SnapshotError.sizeMismatch(
                reference: CGSize(width: refCG.width, height: refCG.height),
                actual: CGSize(width: actCG.width, height: actCG.height)
            )
        }

        let width = refCG.width
        let height = refCG.height
        let bytesPerPixel = 4
        let bytesPerRow = width * bytesPerPixel
        let count = height * bytesPerRow

        var refBytes = [UInt8](repeating: 0, count: count)
        var actBytes = [UInt8](repeating: 0, count: count)

        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue

        guard
            let refContext = CGContext(data: &refBytes, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo),
            let actContext = CGContext(data: &actBytes, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo)
        else {
            throw SnapshotError.sizeMismatch(reference: reference.size, actual: actual.size)
        }

        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        refContext.draw(refCG, in: rect)
        actContext.draw(actCG, in: rect)

        let perChannelThreshold: Int = 16 // tolerate minor anti-aliasing / compression noise
        var differingPixels = 0
        let totalPixels = width * height

        var index = 0
        while index < count {
            let dr = abs(Int(refBytes[index]) - Int(actBytes[index]))
            let dg = abs(Int(refBytes[index + 1]) - Int(actBytes[index + 1]))
            let db = abs(Int(refBytes[index + 2]) - Int(actBytes[index + 2]))
            if dr > perChannelThreshold || dg > perChannelThreshold || db > perChannelThreshold {
                differingPixels += 1
            }
            index += bytesPerPixel
        }

        return Double(differingPixels) / Double(totalPixels)
    }

    // MARK: - Paths

    static func deviceName() -> String {
        UIDevice.current.name.replacingOccurrences(of: " ", with: "_")
    }

    static func referenceURL(folder: String, name: String, sourceFile: String) -> URL {
        let baseDir = screenshotsRoot(from: sourceFile)
        return baseDir
            .appendingPathComponent(folder, isDirectory: true)
            .appendingPathComponent("\(name)")
    }

    /// Walks up from the source file to find the repository root (the directory
    /// containing a `Screenshots` folder or `TestProject.xcodeproj`) and returns
    /// its `Screenshots` directory.
    static func screenshotsRoot(from sourceFile: String) -> URL {
        let fileManager = FileManager.default
        var dir = URL(fileURLWithPath: sourceFile).deletingLastPathComponent()

        for _ in 0..<10 {
            let screenshots = dir.appendingPathComponent("Screenshots", isDirectory: true)
            let projectFile = dir.appendingPathComponent("TestProject.xcodeproj")
            if fileManager.fileExists(atPath: screenshots.path)
                || fileManager.fileExists(atPath: projectFile.path) {
                return screenshots
            }
            let parent = dir.deletingLastPathComponent()
            if parent.path == dir.path { break }
            dir = parent
        }

        // Fallback: alongside the source file.
        return URL(fileURLWithPath: sourceFile)
            .deletingLastPathComponent()
            .appendingPathComponent("Screenshots", isDirectory: true)
    }

    @discardableResult
    static func write(_ image: UIImage, to url: URL) throws -> URL {
        let directory = url.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        guard let data = image.pngData() else {
            throw SnapshotError.referenceMissing(url)
        }
        try data.write(to: url)
        return url
    }
}
