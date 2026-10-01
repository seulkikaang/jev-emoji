import AppKit
import ApplicationServices

enum ContextReadResult {
    case captured(String)
    case empty
    case unavailable
    case protectedInput
}

@MainActor
enum AccessibilityContextReader {
    private static var readDeadline = Date.distantFuture

    static func prepare(processID: pid_t) {
        guard processID > 0, AXIsProcessTrusted() else { return }
        let app = AXUIElementCreateApplication(processID)
        AXUIElementSetMessagingTimeout(app, 0.2)
        // Chrome enables its accessibility tree when an AX client asks for its role.
        _ = attribute(app, kAXRoleAttribute)
        // Electron (including Notion) opts in through this application attribute.
        if attribute(app, "AXManualAccessibility") as? Bool != true {
            AXUIElementSetAttributeValue(app, "AXManualAccessibility" as CFString, kCFBooleanTrue)
        }
    }

    static func read(processID: pid_t) -> ContextReadResult {
        readDeadline = Date().addingTimeInterval(0.6)
        defer { readDeadline = .distantFuture }
        prepare(processID: processID)
        let app = AXUIElementCreateApplication(processID)
        AXUIElementSetMessagingTimeout(app, 0.2)
        guard let focused = element(attribute(app, kAXFocusedUIElementAttribute)) else { return .unavailable }
        let ancestors = lineage(focused)
        guard !ancestors.contains(where: isProtected) else { return .protectedInput }

        // Standard AppKit fields and Chromium editable nodes. Never guess that the caret
        // is at the end of AXValue: it may be in the middle of a long document.
        for candidate in ancestors.prefix(4) {
            if role(candidate) == "AXWebArea" { break }
            guard isEditable(candidate) else { continue }
            if let selected = attribute(candidate, kAXSelectedTextAttribute) as? String,
               !selected.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return result(selected)
            }
            if let range = selectedRange(candidate), range.location >= 0, range.length >= 0 {
                if let value = attribute(candidate, kAXValueAttribute) as? String {
                    let text = value as NSString
                    if range.location <= text.length, range.length <= text.length - range.location {
                        let before = text.substring(to: range.location)
                        if range.length > 0 {
                            return result(text.substring(with: NSRange(location: range.location, length: range.length)))
                        }
                        // At the beginning of a paragraph, use the sentence after the caret.
                        let line = before.components(separatedBy: .newlines).last ?? ""
                        if !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return result(line) }
                        let after = text.substring(from: range.location).components(separatedBy: .newlines).first ?? ""
                        return result(String(after.prefix(140)))
                    }
                }
                var slice = CFRange(location: max(0, range.location - 280), length: min(280, range.location))
                if slice.length > 0, let axRange = AXValueCreate(.cfRange, &slice),
                   let text = parameter(candidate, kAXStringForRangeParameterizedAttribute, axRange) as? String {
                    return result(text.components(separatedBy: .newlines).last ?? text)
                }
            }
        }
        return readMarkers(focused: focused, ancestors: ancestors)
    }

    private static func readMarkers(focused: AXUIElement, ancestors: [AXUIElement]) -> ContextReadResult {
        let deadline = Date().addingTimeInterval(0.45)
        for owner in ancestors {
            guard let value = attribute(owner, "AXSelectedTextMarkerRange"),
                  CFGetTypeID(value) == AXTextMarkerRangeGetTypeID() else { continue }
            let range = value as! AXTextMarkerRange
            let caret = AXTextMarkerRangeCopyStartMarker(range)
            let end = AXTextMarkerRangeCopyEndMarker(range)
            guard let caretElement = element(parameter(owner, "AXUIElementForTextMarker", caret)),
                  let editable = lineage(caretElement).first(where: isEditable) else { continue }
            guard !lineage(caretElement).contains(where: isProtected) else { return .protectedInput }
            // A web area can own the focused selection, but an unrelated focused control cannot.
            guard CFEqual(focused, editable) || role(focused) == "AXWebArea" ||
                    lineage(caretElement).contains(where: { CFEqual($0, focused) }) else { continue }

            if !CFEqual(caret, end) {
                guard let endElement = element(parameter(owner, "AXUIElementForTextMarker", end)),
                      lineage(endElement).contains(where: { CFEqual($0, editable) }) else { return .unavailable }
                let ordered = parameter(owner, "AXTextMarkerRangeForUnorderedTextMarkers", [caret, end] as CFArray) ?? range
                if let text = parameter(owner, "AXStringForTextMarkerRange", ordered) as? String {
                    return result(text)
                }
            }

            var start = caret
            let backwardDeadline = min(deadline, Date().addingTimeInterval(0.22))
            for _ in 0..<140 {
                guard Date() < backwardDeadline,
                      let value = parameter(owner, "AXPreviousTextMarkerForTextMarker", start),
                      CFGetTypeID(value) == AXTextMarkerGetTypeID(), !CFEqual(value, start),
                      let node = element(parameter(owner, "AXUIElementForTextMarker", value)),
                      lineage(node).contains(where: { CFEqual($0, editable) }) else { break }
                let previous = value as! AXTextMarker
                let step = AXTextMarkerRangeCreate(nil, previous, start)
                if let text = parameter(owner, "AXStringForTextMarkerRange", step) as? String,
                   text.rangeOfCharacter(from: .newlines) != nil { break }
                start = previous
            }
            let preceding = AXTextMarkerRangeCreate(nil, start, caret)
            if let text = parameter(owner, "AXStringForTextMarkerRange", preceding) as? String {
                let line = text.components(separatedBy: .newlines).last ?? ""
                if !line.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return result(line) }
            }

            // The caret can be at the start of the editable paragraph (a common emoji position).
            var following = caret
            for _ in 0..<140 {
                guard Date() < deadline,
                      let value = parameter(owner, "AXNextTextMarkerForTextMarker", following),
                      CFGetTypeID(value) == AXTextMarkerGetTypeID(), !CFEqual(value, following),
                      let node = element(parameter(owner, "AXUIElementForTextMarker", value)),
                      lineage(node).contains(where: { CFEqual($0, editable) }) else { break }
                following = value as! AXTextMarker
                let step = AXTextMarkerRangeCreate(nil, caret, following)
                if let text = parameter(owner, "AXStringForTextMarkerRange", step) as? String,
                   text.rangeOfCharacter(from: .newlines) != nil { break }
            }
            let trailing = AXTextMarkerRangeCreate(nil, caret, following)
            if let text = parameter(owner, "AXStringForTextMarkerRange", trailing) as? String {
                return result(String((text.components(separatedBy: .newlines).first ?? "").prefix(140)))
            }
        }
        return .unavailable
    }

    private static func result(_ text: String) -> ContextReadResult {
        let trimmed = String(text.suffix(140)).trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? .empty : .captured(trimmed)
    }

    private static func selectedRange(_ element: AXUIElement) -> CFRange? {
        guard let value = attribute(element, kAXSelectedTextRangeAttribute),
              CFGetTypeID(value) == AXValueGetTypeID() else { return nil }
        var range = CFRange()
        guard AXValueGetValue(value as! AXValue, .cfRange, &range) else { return nil }
        return range
    }

    private static func isEditable(_ element: AXUIElement) -> Bool {
        let role = role(element)
        return role == kAXTextAreaRole || role == kAXTextFieldRole ||
            attribute(element, "AXEditable") as? Bool == true
    }

    private static func isProtected(_ element: AXUIElement) -> Bool {
        attribute(element, kAXSubroleAttribute) as? String == kAXSecureTextFieldSubrole ||
            attribute(element, "AXProtectedContent") as? Bool == true
    }

    private static func role(_ element: AXUIElement) -> String {
        attribute(element, kAXRoleAttribute) as? String ?? ""
    }

    private static func lineage(_ start: AXUIElement) -> [AXUIElement] {
        var elements = [start]
        while elements.count < 12,
              let parent = element(attribute(elements.last!, kAXParentAttribute)),
              !elements.contains(where: { CFEqual($0, parent) }) {
            elements.append(parent)
            if role(parent) == "AXWebArea" { break }
        }
        return elements
    }

    private static func element(_ value: CFTypeRef?) -> AXUIElement? {
        guard let value, CFGetTypeID(value) == AXUIElementGetTypeID() else { return nil }
        return (value as! AXUIElement)
    }

    private static func attribute(_ element: AXUIElement, _ name: String) -> CFTypeRef? {
        guard Date() < readDeadline else { return nil }
        AXUIElementSetMessagingTimeout(element, 0.05)
        var value: CFTypeRef?
        guard AXUIElementCopyAttributeValue(element, name as CFString, &value) == .success else { return nil }
        return value
    }

    private static func parameter(_ element: AXUIElement, _ name: String, _ argument: CFTypeRef) -> CFTypeRef? {
        guard Date() < readDeadline else { return nil }
        AXUIElementSetMessagingTimeout(element, 0.05)
        var value: CFTypeRef?
        guard AXUIElementCopyParameterizedAttributeValue(element, name as CFString, argument, &value) == .success else { return nil }
        return value
    }
}
