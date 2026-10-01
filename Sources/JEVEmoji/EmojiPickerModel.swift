import AppKit
import ApplicationServices
import Combine
import CoreGraphics
import Foundation
import os

@MainActor
final class EmojiPickerModel: ObservableObject {
    @Published private(set) var provider = JevProvider.selected
    @Published private(set) var query = ""
    @Published private(set) var context = ""
    @Published private(set) var canReadContext = AXIsProcessTrusted()
    @Published private(set) var isConfigured = JevGatewayClient.hasAPIKey
    @Published private(set) var recommendations = EmojiCatalog.popular
    @Published private(set) var isLoading = false
    @Published private(set) var errorMessage: String?

    @Published private(set) var contextMessage = "입력 중인 문장에서 단축키를 눌러 주세요."
    @Published private(set) var contextAppName = ""
    @Published private(set) var hasJevResults = false

    var resultsTitle: String {
        if isLoading { return "Jev가 이모지를 고르고 있어요" }
        if hasJevResults { return isSearching ? "검색 결과" : "지금 문장에 어울려요" }
        return "자주 쓰는 이모지"
    }

    var onInsert: (() -> Void)?
    private var requestTask: Task<Void, Never>?
    private var requestNumber = 0
    private var targetProcessID: pid_t = NSWorkspace.shared.frontmostApplication?.processIdentifier ?? 0
    private let logger = Logger(subsystem: "com.jev.emoji", category: "context")

    var isSearching: Bool { !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    func captureContext(from application: NSRunningApplication?) {
        defer {
            // Record only operational metadata; never log the document or API key.
            logger.notice("Context capture: permission=\(self.canReadContext), characters=\(self.context.count), targetPID=\(self.targetProcessID)")
        }
        cancelRecommendation()
        targetProcessID = application?.processIdentifier ?? 0
        contextAppName = application?.localizedName ?? "앱"
        context = ""
        errorMessage = nil
        query = ""
        recommendations = EmojiCatalog.popular
        hasJevResults = false
        canReadContext = AXIsProcessTrusted()
        guard canReadContext else {
            contextMessage = "손쉬운 사용 권한을 켜면 다른 앱의 문장을 읽어요."
            return
        }
        guard targetProcessID > 0, targetProcessID != ProcessInfo.processInfo.processIdentifier else {
            contextMessage = "입력 중인 앱으로 돌아가 단축키를 눌러 주세요."
            return
        }
        switch AccessibilityContextReader.read(processID: targetProcessID) {
        case .captured(let text):
            context = text
            contextMessage = text
        case .empty:
            contextMessage = "커서가 있는 입력란에 문장이 없어요. 문장을 입력하거나 검색해 주세요."
        case .unavailable:
            contextMessage = "\(contextAppName)에서 커서 문맥을 읽지 못했어요. 문장을 선택하고 다시 열거나 검색해 주세요."
        case .protectedInput:
            contextMessage = "보호된 입력란의 내용은 읽지 않아요. 검색으로 이모지를 찾아 주세요."
        }
    }

    func requestAccessibilityAccess() {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
        canReadContext = AXIsProcessTrustedWithOptions(options)
        if !canReadContext,
           let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    func selectProvider(_ value: JevProvider) {
        guard provider != value else { return }
        cancelRecommendation()
        provider = value
        UserDefaults.standard.set(value.rawValue, forKey: "JevProvider")
        isConfigured = JevGatewayClient.loadAPIKey(for: value) != nil
        hasJevResults = false
        recommendations = EmojiCatalog.popular
        errorMessage = nil
        if isSearching { updateQuery(query) }
        else if !context.isEmpty { recommendContext() }
    }

    func saveAPIKey(_ key: String) throws {
        try JevGatewayClient.saveAPIKey(key, for: provider)
        isConfigured = true
        errorMessage = nil
        if !query.isEmpty { updateQuery(query) }
        else if !context.isEmpty { recommendContext() }
    }

    func removeAPIKey() {
        JevGatewayClient.removeAPIKey(for: provider)
        isConfigured = false
        cancelRecommendation()
        hasJevResults = false
        recommendations = EmojiCatalog.popular
    }

    // Only user edits call this. Programmatic clearing must not cancel a context request.
    func updateQuery(_ value: String) {
        query = value
        let term = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if term.isEmpty {
            recommendContext()
        } else {
            scheduleRecommendation(for: term, debounce: true)
        }
    }

    func recommendContext() {
        query = ""
        let text = context.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else {
            cancelRecommendation()
            hasJevResults = false
            recommendations = EmojiCatalog.popular
            errorMessage = nil
            return
        }
        scheduleRecommendation(for: text, debounce: false)
    }

    private func cancelRecommendation() {
        requestTask?.cancel()
        requestTask = nil
        requestNumber += 1
        isLoading = false
    }

    private func scheduleRecommendation(for text: String, debounce: Bool) {
        cancelRecommendation()
        let currentRequest = requestNumber
        hasJevResults = false
        recommendations = EmojiCatalog.popular
        guard isConfigured else {
            errorMessage = "Jev를 쓰려면 \(provider.name) 키를 등록해 주세요."
            return
        }
        errorMessage = nil
        isLoading = true
        recommendations = []
        let client = JevGatewayClient(provider: provider)
        requestTask = Task {
            defer { if requestNumber == currentRequest { isLoading = false } }
            do {
                if debounce { try await Task.sleep(for: .milliseconds(380)) }
                try Task.checkCancellation()
                let result = try await client.recommendations(for: text)
                guard !Task.isCancelled, requestNumber == currentRequest else { return }
                recommendations = result
                hasJevResults = true
                errorMessage = nil
            } catch {
                guard !Task.isCancelled, requestNumber == currentRequest else { return }
                recommendations = EmojiCatalog.popular
                errorMessage = error.localizedDescription
            }
        }
    }

    func insert(_ emoji: String) {
        onInsert?()
        let targetApp = NSWorkspace.shared.runningApplications.first { $0.processIdentifier == targetProcessID }
        let pasteboard = NSPasteboard.general
        let previousItems = pasteboard.pasteboardItems?.map { item -> [NSPasteboard.PasteboardType: Data] in
            Dictionary(uniqueKeysWithValues: item.types.compactMap { type in
                item.data(forType: type).map { (type, $0) }
            })
        } ?? []

        pasteboard.clearContents()
        pasteboard.setString(emoji, forType: .string)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            targetApp?.activate(options: [.activateIgnoringOtherApps])
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                let source = CGEventSource(stateID: .hidSystemState)
                let down = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: true)
                down?.flags = .maskCommand
                down?.post(tap: .cghidEventTap)
                let up = CGEvent(keyboardEventSource: source, virtualKey: 0x09, keyDown: false)
                up?.flags = .maskCommand
                up?.post(tap: .cghidEventTap)

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    guard pasteboard.string(forType: .string) == emoji else { return }
                    pasteboard.clearContents()
                    if previousItems.isEmpty {
                        pasteboard.setString("", forType: .string)
                    } else {
                        let restored = previousItems.map { values -> NSPasteboardItem in
                            let item = NSPasteboardItem()
                            values.forEach { item.setData($0.value, forType: $0.key) }
                            return item
                        }
                        pasteboard.writeObjects(restored)
                    }
                }
            }
        }
    }
}
