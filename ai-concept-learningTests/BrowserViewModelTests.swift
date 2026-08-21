//
//  BrowserViewModelTests.swift
//  ai-concept-learningTests
//
//  Unit tests for the Browser tab: URL composition and open behavior.
//

import Testing
@testable import ai_concept_learning
import Foundation

struct BrowserViewModelTests {

    @Test("Swaps embedded https target inside the scheme template")
    func composesFirefoxURL() {
        let url = Self.firefox.composedURLString(for: "https://apple.com/")

        #expect(url == "firefox://open-url?url=https://apple.com/")
    }

    @Test("Replaces a bare https template entirely")
    func composesSafariURL() {
        let safari = Browser(
            id: "safari",
            name: "Safari",
            scheme: "https",
            iconSystemName: "safari.fill",
            colorHex: "#1B82F6",
            urlTemplate: "https://www.google.com/"
        )

        #expect(safari.composedURLString(for: "https://apple.com/")
            == "https://apple.com/")
    }

    @Test("Keeps the hardcoded template when target is empty")
    func emptyTargetKeepsTemplate() {
        #expect(Self.firefox.composedURLString(for: "   ")
            == "firefox://open-url?url=https://www.google.com/")
    }

    @Test("Builds an openable URL from the composed string")
    func buildsURL() {
        let url = Self.firefox.composedURL(for: "https://apple.com/")

        #expect(url?.scheme == "firefox")
    }

    @Test("Opens the browser URL when installed")
    @MainActor
    func opensWhenInstalled() async {
        let opener = MockURLOpener(canOpen: true, openResult: true)
        let viewModel = BrowserViewModel(
            service: MockBrowserService(browsers: [Self.firefox]),
            opener: opener
        )
        viewModel.loadBrowsers()

        await viewModel.open(Self.firefox)

        #expect(opener.openedURLs.count == 1)
        #expect(viewModel.errorMessage == nil)
    }

    @Test("Reports error when browser is not installed")
    @MainActor
    func errorsWhenNotInstalled() async {
        let opener = MockURLOpener(canOpen: false, openResult: false)
        let viewModel = BrowserViewModel(
            service: MockBrowserService(browsers: [Self.firefox]),
            opener: opener
        )

        await viewModel.open(Self.firefox)

        #expect(opener.openedURLs.isEmpty)
        #expect(viewModel.errorMessage != nil)
    }

    private static let firefox = Browser(
        id: "firefox",
        name: "Firefox",
        scheme: "firefox",
        iconSystemName: "flame.fill",
        colorHex: "#FF6611",
        urlTemplate: "firefox://open-url?url=https://www.google.com/"
    )
}

private struct MockBrowserService: BrowserServiceProtocol {
    let browsers: [Browser]

    func fetchBrowsers() throws -> [Browser] {
        browsers
    }
}

@MainActor
private final class MockURLOpener: URLOpening {

    private let canOpenResult: Bool
    private let openResult: Bool
    private(set) var openedURLs: [URL] = []

    init(canOpen: Bool, openResult: Bool) {
        self.canOpenResult = canOpen
        self.openResult = openResult
    }

    func canOpen(_ url: URL) -> Bool {
        canOpenResult
    }

    func open(_ url: URL) async -> Bool {
        openedURLs.append(url)
        return openResult
    }
}
