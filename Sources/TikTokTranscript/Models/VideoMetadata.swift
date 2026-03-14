//
//  VideoMetadata.swift
//  TikTokTranscript
//
//  Created by David Sherlock on 2025.
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

    /// The full TikTok video URL.
    ///
    /// Requires the author handle to construct. Returns `nil` if the handle is empty.
    public var url: String? {
        guard !authorHandle.isEmpty else { return nil }
        return "https://www.tiktok.com/@\(authorHandle)/video/\(videoId)"
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
