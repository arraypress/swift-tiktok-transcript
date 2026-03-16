//
//  VideoVariant.swift
//  TikTokTranscript
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// A single video format variant at a specific resolution and bitrate.
///
/// TikTok serves videos at multiple quality levels. Each variant includes
/// the direct URL, dimensions, and bitrate information.
///
/// ```swift
/// if let video = result.video {
///     for variant in video.variants {
///         print("\(variant.quality ?? "unknown") — \(variant.width)x\(variant.height) @ \(variant.bitrateKbps ?? 0)kbps")
///         print("  URL: \(variant.url)")
///     }
/// }
/// ```
public struct VideoVariant: Codable, Equatable, Sendable {

    /// The direct URL to this variant's video file.
    public let url: String

    /// Video width in pixels for this variant.
    public let width: Int

    /// Video height in pixels for this variant.
    public let height: Int

    /// The quality label (e.g., `"540p"`, `"720p"`, `"1080p"`).
    public let quality: String?

    /// The video codec (e.g., `"h264"`, `"h265"`).
    public let codec: String?

    /// The bitrate in kilobits per second.
    public let bitrateKbps: Int?

    /// The MIME type. TikTok videos are always `"video/mp4"`.
    public var contentType: String { "video/mp4" }
}
