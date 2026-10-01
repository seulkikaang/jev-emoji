import Foundation
import Security

enum JevProvider: String, CaseIterable, Identifiable {
    case vercel, typesafe
    var id: String { rawValue }
    static var selected: JevProvider {
        JevProvider(rawValue: UserDefaults.standard.string(forKey: "JevProvider") ?? "vercel") ?? .vercel
    }
    var name: String { self == .vercel ? "Vercel AI Gateway" : "TypeSafe" }
    var keychainAccount: String { self == .vercel ? "AI_GATEWAY_API_KEY" : "TYPESAFE_API_KEY" }
    var endpoint: URL { URL(string: self == .vercel ? "https://ai-gateway.vercel.sh/v1/evaluate" : "https://api.typesafe.ai/v1/systemone")! }
    var model: String { self == .vercel ? "typesafe-ai/jev" : "jev-latest" }
    var keyURL: URL { URL(string: self == .vercel ? "https://vercel.com/dashboard/~/ai-gateway/api-keys" : "https://console.typesafe.ai")! }
}

enum JevGatewayError: LocalizedError {
    case missingAPIKey(JevProvider)
    case invalidResponse
    case unauthorized(JevProvider)
    case paidCreditsRequired
    case accessDenied(JevProvider)
    case budgetExceeded(JevProvider)
    case rateLimited
    case server(Int, JevProvider)

    var errorDescription: String? {
        switch self {
        case .missingAPIKey(let provider): "\(provider.name) 키를 먼저 등록해 주세요."
        case .invalidResponse: "Jev 응답을 읽지 못했어요. 다시 시도해 주세요."
        case .unauthorized(let provider): "\(provider.name) 키가 올바르지 않아요. 설정에서 다시 등록해 주세요."
        case .paidCreditsRequired: "키는 유효하지만 Jev 사용에는 Vercel AI Gateway 크레딧이 필요해요."
        case .accessDenied(let provider): "\(provider.name) 계정의 Jev 접근 권한을 확인해 주세요."
        case .budgetExceeded(let provider): "\(provider.name) 사용 한도 또는 크레딧을 확인해 주세요."
        case .rateLimited: "요청이 잠시 많아요. 조금 뒤에 다시 시도해 주세요."
        case .server(let status, let provider): "\(provider.name)에 연결하지 못했어요. (\(status))"
        }
    }
}

struct JevGatewayClient {
    private static let keychainService = "com.jev.emoji"
    let provider: JevProvider

    init(provider: JevProvider = .selected) { self.provider = provider }

    static var hasAPIKey: Bool { loadAPIKey(for: .selected) != nil }

    static func saveAPIKey(_ value: String, for provider: JevProvider = .selected) throws {
        let key = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { throw JevGatewayError.missingAPIKey(provider) }

        let identity: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: provider.keychainAccount
        ]
        SecItemDelete(identity as CFDictionary)
        var item = identity
        item[kSecValueData as String] = Data(key.utf8)
        item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        let status = SecItemAdd(item as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw NSError(domain: NSOSStatusErrorDomain, code: Int(status))
        }
    }

    static func removeAPIKey(for provider: JevProvider = .selected) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: provider.keychainAccount
        ]
        SecItemDelete(query as CFDictionary)
    }

    static func loadAPIKey(for provider: JevProvider = .selected) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: provider.keychainAccount,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    func recommendations(for text: String) async throws -> [EmojiItem] {
        guard let apiKey = Self.loadAPIKey(for: provider) else { throw JevGatewayError.missingAPIKey(provider) }

        let options = Dictionary(uniqueKeysWithValues: EmojiCatalog.items.enumerated().map { index, item in
            let key = "emoji_\(index)"
            let description = "\(item.emoji) \(item.name). Category: \(item.category). Related ideas: \(item.keywords.joined(separator: ", "))."
            return (key, description)
        })

        let requestBody: [String: Any] = [
            "model": provider.model,
            "state": "Choose emojis that fit the meaning and tone of this text. Prefer a direct emotional or situational match over a literal word match. Text: \(String(text.suffix(140)))",
            "questions": [
                "emoji": [
                    "type": "choice",
                    "instructions": "Which one emoji best fits the user's text? Compare all options by meaning and tone.",
                    "criteria": options
                ]
            ]
        ]

        var request = URLRequest(url: provider.endpoint)
        request.httpMethod = "POST"
        request.timeoutInterval = 8
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else { throw JevGatewayError.invalidResponse }
        switch httpResponse.statusCode {
        case 200..<300: break
        case 401: throw JevGatewayError.unauthorized(provider)
        case 403:
            let errorBody = String(data: data, encoding: .utf8)?.lowercased() ?? ""
            if provider == .vercel, errorBody.contains("free tier users do not have access to this model") {
                throw JevGatewayError.paidCreditsRequired
            }
            throw JevGatewayError.accessDenied(provider)
        case 402: throw JevGatewayError.budgetExceeded(provider)
        case 429: throw JevGatewayError.rateLimited
        default: throw JevGatewayError.server(httpResponse.statusCode, provider)
        }

        return try Self.decodeRecommendations(from: data)
    }

    static func decodeRecommendations(from data: Data) throws -> [EmojiItem] {
        guard let result = try? JSONDecoder().decode(JevEvaluationResponse.self, from: data),
              let answer = result.answers["emoji"], answer.type == "choice",
              let choice = answer.choice,
              let probabilities = answer.probabilities, !probabilities.isEmpty else {
            throw JevGatewayError.invalidResponse
        }
        // The API contract returns every criteria option, including zero probabilities.
        let expectedKeys = Set(EmojiCatalog.items.indices.map { "emoji_\($0)" })
        guard Set(probabilities.keys) == expectedKeys,
              expectedKeys.contains(choice),
              probabilities.values.allSatisfy({ $0.isFinite && (0...1).contains($0) }),
              abs(probabilities.values.reduce(0, +) - 1) <= 0.01,
              let selectedProbability = probabilities[choice], selectedProbability > 0,
              selectedProbability >= (probabilities.values.max() ?? 0) else {
            throw JevGatewayError.invalidResponse
        }
        let ranked = EmojiCatalog.items.enumerated().sorted { left, right in
            let leftScore = probabilities["emoji_\(left.offset)"] ?? 0
            let rightScore = probabilities["emoji_\(right.offset)"] ?? 0
            if leftScore == rightScore { return left.element.popularity > right.element.popularity }
            return leftScore > rightScore
        }
        return ranked.prefix(10).map(\.element)
    }
}

private struct JevEvaluationResponse: Decodable {
    let answers: [String: JevChoiceAnswer]
}

private struct JevChoiceAnswer: Decodable {
    let type: String
    let choice: String?
    let probabilities: [String: Double]?
}
