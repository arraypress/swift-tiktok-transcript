//
//  CaptionTrack.swift
//  TikTokTranscript
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Represents an available caption track for a TikTok video.
///
/// ```swift
/// let list = try await TikTokTranscript.list("https://www.tiktok.com/@user/video/123")
/// for track in list.tracks {
///     print("\(track.language) — \(track.url.prefix(50))...")
/// }
/// ```
public struct CaptionTrack: Equatable, Sendable {

    /// The language code (e.g., `"eng-US"`, `"spa-ES"`).
    public let language: String

    /// The URL of the WebVTT caption file.
    internal let url: String

    /// Internal memberwise initializer.
    internal init(language: String, url: String) {
        self.language = language
        self.url = url
    }
}

/// The result of listing available captions for a video.
///
/// ```swift
/// let list = try await TikTokTranscript.list("https://www.tiktok.com/@user/video/123")
/// print("Available: \(list.availableLanguages)")
/// ```
public struct CaptionList: Sendable {

    /// All available caption tracks.
    public let tracks: [CaptionTrack]

    /// Language codes for all available tracks.
    public var availableLanguages: [String] {
        tracks.map(\.language)
    }

    /// Finds the best matching track for the given language preferences.
    ///
    /// - Parameter languages: Language codes in descending priority (e.g., `["eng", "spa"]`).
    /// - Returns: The best matching track, or `nil` if no match is found.
    public func findTrack(languages: [String] = ["eng"]) -> CaptionTrack? {
        for lang in languages {
            if let track = tracks.first(where: { $0.language == lang }) {
                return track
            }
            // Prefix match (e.g., "eng" matches "eng-US")
            if let track = tracks.first(where: { $0.language.hasPrefix(lang) }) {
                return track
            }
        }
        return nil
    }
}
