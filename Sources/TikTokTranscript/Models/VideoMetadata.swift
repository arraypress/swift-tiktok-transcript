//
//  VideoMetadata.swift
//  TikTokTranscript
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Metadata about a TikTok video extracted alongside the transcript.
///
/// This data is retrieved from the same page fetch as the transcript
/// and requires no additional network requests.
///
/// ```swift
/// if let video = result.video {
///     print("\(video.author) (@\(video.authorHandle))")
///     print("\(video.formattedPlayCount) plays · \(video.formattedDuration)")
///
///     // Direct video download (best quality)
///     if let url = video.bestUrl {
///         print("Download: \(url)")
///     }
///
///     // All available variants
///     for variant in video.variants {
///         print("\(variant.quality ?? "?") — \(variant.width)x\(variant.height)")
///     }
/// }
/// ```
public struct VideoMetadata: Codable, Equatable, Sendable {

    /// The TikTok video ID.
    public let videoId: String

    /// The video description/caption.
    public let description: String

    /// The creator's display name.
    public let author: String

    /// The creator's TikTok handle (without @).
    public let authorHandle: String

    /// Whether the creator has a verified badge.
    public let authorVerified: Bool

    /// Video duration in seconds.
    public let duration: Int

    /// Total play count.
    public let playCount: Int

    /// Total like (heart) count.
    public let likeCount: Int

    /// Total comment count.
    public let commentCount: Int

    /// Total share count.
    public let shareCount: Int

    /// Total save/bookmark count.
    public let collectCount: Int

    /// The title of the sound/music used.
    public let musicTitle: String

    /// The author of the sound/music used.
    public let musicAuthor: String

    /// When the video was posted.
    public let createdTime: Date?

    /// Hashtags used in the video caption.
    public let hashtags: [String]

    /// URL of the video cover image, if available.
    public let coverUrl: String?

    // MARK: - Video URLs

    /// The direct play URL (highest quality, no watermark).
    ///
    /// Extracted from TikTok's `video.playAddr` field. This is a direct
    /// CDN link to the MP4 file. Note that TikTok CDN URLs expire after
    /// a few hours — use them promptly after fetching.
    public let playUrl: String?

    /// The download URL (may include watermark).
    ///
    /// Extracted from TikTok's `video.downloadAddr` field. This variant
    /// may include TikTok's watermark overlay.
    public let downloadUrl: String?

    /// Available video format variants at different qualities.
    ///
    /// Extracted from TikTok's `video.bitrateInfo` array. Each variant
    /// has different resolution and bitrate. Use ``bestUrl`` for the
    /// highest quality, or iterate for a specific quality level.
    public let variants: [VideoVariant]

    // MARK: - Computed Properties

    /// The full TikTok video URL.
    ///
    /// Requires the author handle to construct. Returns `nil` if the handle is empty.
    public var url: String? {
        guard !authorHandle.isEmpty else { return nil }
        return "https://www.tiktok.com/@\(authorHandle)/video/\(videoId)"
    }

    /// The highest-quality direct MP4 download URL.
    ///
    /// Priority: largest variant by pixel count → ``playUrl`` → ``downloadUrl``.
    /// Returns `nil` if no video URL is available.
    ///
    /// Note: TikTok CDN URLs expire after a few hours. Use promptly after fetching.
    public var bestUrl: URL? {
        // Prefer the largest variant by resolution
        if let best = variants
            .sorted(by: { ($0.width * $0.height) > ($1.width * $1.height) })
            .first {
            if let url = URL(string: best.url) { return url }
        }

        // Fall back to playUrl, then downloadUrl
        if let play = playUrl, let url = URL(string: play) { return url }
        if let download = downloadUrl, let url = URL(string: download) { return url }

        return nil
    }

    /// The duration formatted as `"M:SS"`.
    ///
    /// ```swift
    /// // "1:19"
    /// print(video.formattedDuration)
    /// ```
    public var formattedDuration: String {
        TranscriptSegment.formatTimestamp(Double(duration))
    }

    /// The play count formatted with locale-appropriate grouping separators.
    ///
    /// ```swift
    /// // "19,700,000"
    /// print(video.formattedPlayCount)
    /// ```
    public var formattedPlayCount: String {
        Self.formatNumber(playCount)
    }

    /// The like count formatted with grouping separators.
    public var formattedLikeCount: String {
        Self.formatNumber(likeCount)
    }

    /// The comment count formatted with grouping separators.
    public var formattedCommentCount: String {
        Self.formatNumber(commentCount)
    }

    /// The share count formatted with grouping separators.
    public var formattedShareCount: String {
        Self.formatNumber(shareCount)
    }

    /// The save/bookmark count formatted with grouping separators.
    public var formattedCollectCount: String {
        Self.formatNumber(collectCount)
    }

    /// The hashtags formatted with `#` prefixes, joined by spaces.
    ///
    /// ```swift
    /// // "#fyp #couple #funny"
    /// print(video.formattedHashtags)
    /// ```
    public var formattedHashtags: String {
        hashtags.map { "#\($0)" }.joined(separator: " ")
    }

    /// Formats a number with locale-appropriate grouping separators.
    private static func formatNumber(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: value)) ?? "\(value)"
    }
    
}
