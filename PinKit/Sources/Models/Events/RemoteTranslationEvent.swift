import Foundation

public struct RemoteTranslationEvent: Codable {
    public let targetLanguage: String
    public let originLanguage: String
}
