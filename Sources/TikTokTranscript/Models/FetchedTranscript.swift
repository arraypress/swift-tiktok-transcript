//
//  FetchedTranscript.swift
//  TikTokTranscript
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// The result of fetching a TikTok transcript, containing segments and optional metadata.
///
/// ```swift
/// let result = try await TikTokTranscript.fetch("https://www.tiktok.com/@user/video/123")
///
/// print(result.plainText)
/// print(result.video?.author ?? "Unknown")
/// print(result.formattedDuration) // "1:19"
///
/// for segment in result.segments {
///     print("[\(segment.formattedStart)] \(segment.text)")
/// }
/// ```
public struct FetchedTranscript: Sendable {

    /// The transcript segments with timing information.
    public let segments: [TranscriptSegment]

    /// Video metadata (author, stats, description, video URLs, etc.).
    ///
    /// Extracted from the same page fetch as the transcript at no extra cost.
    /// May be `nil` if TikTok's response structure changes.
    public let video: VideoMetadata?

    /// The language code of the fetched transcript (e.g., `"eng-US"`).
    public let language: String

    /// All segment text joined into a single string, separated by spaces.
    public var plainText: String {
        segments.map(\.text).joined(separator: " ")
    }

    /// Total duration of the transcript in seconds.
    ///
    /// Calculated from the last segment's start time plus its duration.
    public var duration: Double {
        guard let last = segments.last else { return 0 }
        return last.start + last.duration
    }

    /// Number of segments in the transcript.
    public var count: Int {
        segments.count
    }

    /// The total duration formatted as `"M:SS"` or `"H:MM:SS"`.
    public var formattedDuration: String {
        TranscriptSegment.formatTimestamp(duration)
    }

    /// The full transcript with timestamps, one segment per line.
    ///
    /// ```
    /// [0:00] Baby,
    /// [0:02] baby,
    /// [0:04] baby,
    /// ```
    public var timestampedText: String {
        segments.map { "[\($0.formattedStart)] \($0.text)" }.joined(separator: "\n")
    }
}
