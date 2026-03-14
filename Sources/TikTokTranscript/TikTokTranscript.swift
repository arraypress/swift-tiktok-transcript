//
//  TikTokTranscript.swift
//  TikTokTranscript
//
//  Created by David Sherlock on 2025.
//

import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Fetch transcripts and metadata from TikTok videos.
///
/// Extracts caption data from TikTok's `__UNIVERSAL_DATA_FOR_REHYDRATION__`
/// page JSON, then fetches and parses the WebVTT caption file. No API key,
/// browser, or authentication required.
///
/// ## Quick Start
///
/// ```swift
/// import TikTokTranscript
///
/// let result = try await TikTokTranscript.fetch("https://www.tiktok.com/@user/video/123")
/// print(result.plainText)
/// print(result.video?.author ?? "")
/// print(result.video?.formattedPlayCount ?? "")
///
/// // List available captions
/// let list = try await TikTokTranscript.list("https://www.tiktok.com/@user/video/123")
/// print(list.availableLanguages)
/// ```
///
/// ## How It Works
///
/// 1. Fetches the TikTok video page with a browser-like User-Agent
/// 2. Extracts the `__UNIVERSAL_DATA_FOR_REHYDRATION__` JSON from the page HTML
/// 3. Navigates to `webapp.video-detail` → `itemInfo` → `itemStruct`
/// 4. Extracts caption URLs from `video.claInfo.captionInfos` or `video.subtitleInfos`
/// 5. Fetches the WebVTT file and parses it into timed segments
/// 6. Extracts video metadata (author, stats, hashtags, etc.) from the same JSON
///
/// ## Note on App Sandbox
///
/// TikTok may serve a JavaScript challenge page instead of the actual video page
/// when requests come from sandboxed apps. If you encounter ``TikTokTranscriptError/noRehydrationData``
/// errors, try disabling App Sandbox in your Xcode target's Signing & Capabilities.
public enum TikTokTranscript {

    // MARK: - Configuration

    /// Browser-like user agent for fetching the TikTok page.
    private static let userAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36"

    // MARK: - Public API

    /// Fetches the transcript for a TikTok video.
    ///
    /// Automatically selects the best available caption track based on
    /// language preferences.
    ///
    /// ```swift
    /// let result = try await TikTokTranscript.fetch("https://www.tiktok.com/@brookemonk_/video/123")
    ///
    /// print(result.plainText)
    /// print(result.video?.author ?? "")
    /// print(result.timestampedText)
    /// ```
    ///
    /// - Parameters:
    ///   - url: A TikTok video URL.
    ///   - languages: Language code prefixes in descending priority. Defaults to `["eng"]`.
    /// - Throws: ``TikTokTranscriptError`` if the transcript cannot be retrieved.
    /// - Returns: A ``FetchedTranscript`` containing segments and video metadata.
    public static func fetch(_ url: String, languages: [String] = ["eng"]) async throws -> FetchedTranscript {
        let cleanUrl = cleanUrl(url)
        let html = try await fetchPage(url: cleanUrl)
        let rehydrationData = try extractRehydrationData(from: html)
        let itemStruct = try extractItemStruct(from: rehydrationData)

        let metadata = extractMetadata(from: itemStruct)
        let tracks = extractCaptionTracks(from: itemStruct)

        guard !tracks.isEmpty else {
            throw TikTokTranscriptError.noCaptions
        }

        let captionList = CaptionList(tracks: tracks)
        guard let track = captionList.findTrack(languages: languages) else {
            throw TikTokTranscriptError.noCaptionForLanguage(
                requested: languages,
                available: captionList.availableLanguages
            )
        }

        let vttContent = try await fetchCaption(url: track.url)
        let segments = VTTParser.parse(vttContent, language: track.language)

        if segments.isEmpty {
            throw TikTokTranscriptError.noCaptions
        }

        return FetchedTranscript(
            segments: segments,
            video: metadata,
            language: track.language
        )
    }

    /// Lists available caption tracks for a TikTok video without fetching content.
    ///
    /// Use this to discover which languages are available before deciding
    /// which transcript to fetch.
    ///
    /// ```swift
    /// let list = try await TikTokTranscript.list("https://www.tiktok.com/@user/video/123")
    /// print("Available: \(list.availableLanguages)")
    /// ```
    ///
    /// - Parameter url: A TikTok video URL.
    /// - Throws: ``TikTokTranscriptError`` if the video data cannot be accessed.
    /// - Returns: A ``CaptionList`` containing available tracks.
    public static func list(_ url: String) async throws -> CaptionList {
        let cleanUrl = cleanUrl(url)
        let html = try await fetchPage(url: cleanUrl)
        let rehydrationData = try extractRehydrationData(from: html)
        let itemStruct = try extractItemStruct(from: rehydrationData)
        let tracks = extractCaptionTracks(from: itemStruct)

        return CaptionList(tracks: tracks)
    }

    // MARK: - Page Fetching

    /// Fetches a TikTok video page.
    private static func fetchPage(url: String) async throws -> String {
        guard let pageUrl = URL(string: url) else {
            throw TikTokTranscriptError.invalidUrl
        }

        var request = URLRequest(url: pageUrl)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")
        request.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
        request.setValue("text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 429 {
                throw TikTokTranscriptError.blocked
            }
            if httpResponse.statusCode != 200 {
                throw TikTokTranscriptError.networkError("HTTP \(httpResponse.statusCode)")
            }
        }

        guard let html = String(data: data, encoding: .utf8) else {
            throw TikTokTranscriptError.parsingError("Failed to decode page HTML")
        }

        return html
    }

    // MARK: - Rehydration Data Extraction

    /// Extracts the `__UNIVERSAL_DATA_FOR_REHYDRATION__` JSON from the page HTML.
    private static func extractRehydrationData(from html: String) throws -> [String: Any] {
        let markers = [
            "<script id=\"__UNIVERSAL_DATA_FOR_REHYDRATION__\" type=\"application/json\">",
            "id=\"__UNIVERSAL_DATA_FOR_REHYDRATION__\">"
        ]

        for marker in markers {
            guard let startRange = html.range(of: marker) else { continue }
            let remaining = html[startRange.upperBound...]
            guard let endRange = remaining.range(of: "</script>") else { continue }
            let jsonString = String(remaining[..<endRange.lowerBound])

            guard let data = jsonString.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { continue }

            return json
        }

        throw TikTokTranscriptError.noRehydrationData
    }

    /// Navigates the rehydration JSON to the video's `itemStruct`.
    private static func extractItemStruct(from rehydrationData: [String: Any]) throws -> [String: Any] {
        guard let defaultScope = rehydrationData["__DEFAULT_SCOPE__"] as? [String: Any],
              let videoDetail = defaultScope["webapp.video-detail"] as? [String: Any],
              let itemInfo = videoDetail["itemInfo"] as? [String: Any],
              let itemStruct = itemInfo["itemStruct"] as? [String: Any] else {
            throw TikTokTranscriptError.videoNotFound
        }
        return itemStruct
    }

    // MARK: - Caption Extraction

    /// Extracts all available caption tracks from the itemStruct.
    private static func extractCaptionTracks(from itemStruct: [String: Any]) -> [CaptionTrack] {
        guard let video = itemStruct["video"] as? [String: Any] else { return [] }
        var tracks: [CaptionTrack] = []

        // Try claInfo.captionInfos first (more structured)
        if let claInfo = video["claInfo"] as? [String: Any],
           let captionInfos = claInfo["captionInfos"] as? [[String: Any]] {
            for caption in captionInfos {
                let lang = caption["language"] as? String ?? "unknown"
                if let url = caption["url"] as? String, !url.isEmpty {
                    tracks.append(CaptionTrack(language: lang, url: url))
                } else if let urlList = caption["urlList"] as? [String], let url = urlList.first, !url.isEmpty {
                    tracks.append(CaptionTrack(language: lang, url: url))
                }
            }
        }

        // Try subtitleInfos as fallback
        if tracks.isEmpty,
           let subtitleInfos = video["subtitleInfos"] as? [[String: Any]] {
            for subtitle in subtitleInfos {
                let lang = subtitle["LanguageCodeName"] as? String ?? "unknown"
                if let url = subtitle["Url"] as? String, !url.isEmpty {
                    tracks.append(CaptionTrack(language: lang, url: url))
                }
            }
        }

        return tracks
    }

    // MARK: - Caption Fetching

    /// Fetches the WebVTT caption file from TikTok's CDN.
    private static func fetchCaption(url: String) async throws -> String {
        guard let captionUrl = URL(string: url) else {
            throw TikTokTranscriptError.captionFetchFailed
        }

        var request = URLRequest(url: captionUrl)
        request.setValue(userAgent, forHTTPHeaderField: "User-Agent")

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            throw TikTokTranscriptError.captionFetchFailed
        }

        guard let content = String(data: data, encoding: .utf8), !content.isEmpty else {
            throw TikTokTranscriptError.captionFetchFailed
        }

        return content
    }

    // MARK: - Metadata Extraction

    /// Extracts video metadata from the itemStruct.
    private static func extractMetadata(from itemStruct: [String: Any]) -> VideoMetadata? {
        let author = itemStruct["author"] as? [String: Any]
        let stats = itemStruct["stats"] as? [String: Any]
        let statsV2 = itemStruct["statsV2"] as? [String: Any]
        let music = itemStruct["music"] as? [String: Any]
        let video = itemStruct["video"] as? [String: Any]

        // Extract hashtags
        var hashtags: [String] = []
        if let textExtras = itemStruct["textExtra"] as? [[String: Any]] {
            let tags = textExtras.compactMap { $0["hashtagName"] as? String }.filter { !$0.isEmpty }
            if !tags.isEmpty { hashtags = tags }
        }
        if hashtags.isEmpty, let challenges = itemStruct["challenges"] as? [[String: Any]] {
            hashtags = challenges.compactMap { $0["title"] as? String }
        }

        // Parse counts — statsV2 uses strings, stats uses ints
        let playCount = Int(statsV2?["playCount"] as? String ?? "") ?? (stats?["playCount"] as? Int ?? 0)
        let likeCount = Int(statsV2?["diggCount"] as? String ?? "") ?? (stats?["diggCount"] as? Int ?? 0)
        let commentCount = Int(statsV2?["commentCount"] as? String ?? "") ?? (stats?["commentCount"] as? Int ?? 0)
        let shareCount = Int(statsV2?["shareCount"] as? String ?? "") ?? (stats?["shareCount"] as? Int ?? 0)
        let collectCount = Int(statsV2?["collectCount"] as? String ?? "") ?? (stats?["collectCount"] as? Int ?? 0)

        // Parse createTime (unix timestamp as string or number)
        var createdDate: Date? = nil
        if let str = itemStruct["createTime"] as? String, let ts = Double(str) {
            createdDate = Date(timeIntervalSince1970: ts)
        } else if let num = itemStruct["createTime"] as? Double {
            createdDate = Date(timeIntervalSince1970: num)
        }

        let coverUrl = video?["cover"] as? String ?? video?["originCover"] as? String

        return VideoMetadata(
            videoId: itemStruct["id"] as? String ?? "",
            description: itemStruct["desc"] as? String ?? "",
            author: author?["nickname"] as? String ?? "",
            authorHandle: author?["uniqueId"] as? String ?? "",
            authorVerified: author?["verified"] as? Bool ?? false,
            duration: video?["duration"] as? Int ?? 0,
            playCount: playCount,
            likeCount: likeCount,
            commentCount: commentCount,
            shareCount: shareCount,
            collectCount: collectCount,
            musicTitle: music?["title"] as? String ?? "",
            musicAuthor: music?["authorName"] as? String ?? "",
            createdTime: createdDate,
            hashtags: hashtags,
            coverUrl: coverUrl
        )
    }

    // MARK: - URL Cleaning

    /// Strips tracking parameters from a TikTok URL.
    private static func cleanUrl(_ url: String) -> String {
        var cleaned = url.trimmingCharacters(in: .whitespacesAndNewlines)
        if let questionMark = cleaned.range(of: "?") {
            cleaned = String(cleaned[..<questionMark.lowerBound])
        }
        return cleaned
    }
}
