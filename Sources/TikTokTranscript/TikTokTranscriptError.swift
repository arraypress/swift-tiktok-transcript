//
//  TikTokTranscriptError.swift
//  TikTokTranscript
//
//  Created by David Sherlock on 2025.
//

import Foundation

/// Errors that can occur when fetching TikTok transcripts.
///
/// ```swift
/// do {
///     let result = try await TikTokTranscript.fetch(url)
/// } catch TikTokTranscriptError.noCaptions {
///     print("This video has no captions")
/// } catch TikTokTranscriptError.blocked {
///     print("TikTok is blocking the request")
/// } catch {
///     print(error.localizedDescription)
/// }
/// ```
public enum TikTokTranscriptError: Error, LocalizedError, Equatable, Sendable {

    /// The provided URL is not a valid TikTok video URL.
    case invalidUrl

    /// A network request failed.
    case networkError(String)

    /// TikTok is blocking the request (HTTP 429 or JS challenge).
    ///
    /// This can happen when the App Sandbox is enabled or when TikTok
    /// serves a JavaScript challenge instead of the page content.
    /// Try disabling App Sandbox or retrying from a different network.
    case blocked

    /// The video was not found in TikTok's page data.
    ///
    /// The video may have been deleted, set to private, or the URL may be malformed.
    case videoNotFound

    /// The `__UNIVERSAL_DATA_FOR_REHYDRATION__` script tag was not found in the page.
    ///
    /// TikTok may have served a JavaScript challenge page instead of the
    /// actual video page. This often happens with App Sandbox enabled.
    case noRehydrationData

    /// No captions are available for this video.
    ///
    /// Not all TikTok videos have captions. The creator must have captions
    /// enabled, or TikTok must have auto-generated them.
    case noCaptions

    /// No caption was found matching the requested languages.
    case noCaptionForLanguage(requested: [String], available: [String])

    /// Failed to fetch the WebVTT caption file from TikTok's CDN.
    case captionFetchFailed

    /// Failed to parse response data.
    case parsingError(String)

    public var errorDescription: String? {
        switch self {
        case .invalidUrl:
            return "Invalid TikTok URL. Provide a URL like https://www.tiktok.com/@user/video/1234567890"
        case .networkError(let message):
            return "Network error: \(message)"
        case .blocked:
            return "TikTok is blocking this request. Try disabling App Sandbox or use a different network."
        case .videoNotFound:
            return "Video not found in TikTok's page data. It may have been deleted or set to private."
        case .noRehydrationData:
            return "Could not find video data in page. TikTok may have served a JavaScript challenge."
        case .noCaptions:
            return "No captions available for this video."
        case .noCaptionForLanguage(let requested, let available):
            return "No caption found for \(requested.joined(separator: ", ")). Available: \(available.joined(separator: ", "))"
        case .captionFetchFailed:
            return "Failed to fetch the caption file from TikTok's CDN."
        case .parsingError(let message):
            return "Parsing error: \(message)"
        }
    }
}
