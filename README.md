# Swift TikTok Transcript

A Swift library for fetching TikTok video transcripts, metadata, and direct video URLs. No API key required, no browser needed — extracts captions and media URLs directly from TikTok's public page data.

## Features

- 🎯 **Simple API** — fetch transcripts with a single async call
- 📝 **Full transcripts** with timestamps, durations, and language info
- 📊 **Video metadata** — author, play/like/share counts, hashtags, music, description
- 🎬 **Direct video URLs** — play, download, and multiple quality variants with codec/bitrate info
- 🌍 **Multi-language support** — request specific languages with automatic fallback
- 📋 **List available captions** — check what's available before fetching
- 🔒 **No API key required** — parses TikTok's public page data
- 🍎 **Cross-platform** — macOS, iOS, tvOS, watchOS
- ⚡ **Async/await** native — built for modern Swift concurrency
- 🛡️ **Typed error handling** — specific errors for every failure case

## Requirements

- macOS 13.0+ / iOS 16.0+ / tvOS 16.0+ / watchOS 9.0+
- Swift 6.0+
- Xcode 16.0+

## Installation

### Swift Package Manager

Add the following to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/arraypress/swift-tiktok-transcript.git", from: "1.0.0")
]
```

Or in Xcode:
1. File → Add Package Dependencies
2. Enter the repository URL
3. Choose version requirements

## Usage

### Fetch a Transcript

```swift
import TikTokTranscript

let result = try await TikTokTranscript.fetch("https://www.tiktok.com/@brookemonk_/video/7616832546759920926")
print(result.plainText)
```

### Access Video Metadata

Metadata is extracted from the same page fetch — no additional requests.

```swift
let result = try await TikTokTranscript.fetch("https://www.tiktok.com/@user/video/123")

if let video = result.video {
    print("\(video.author) (@\(video.authorHandle))")
    print("Plays: \(video.formattedPlayCount)")
    print("Likes: \(video.formattedLikeCount)")
    print("Duration: \(video.formattedDuration)")
    print("Music: \(video.musicTitle) — \(video.musicAuthor)")
    print("Hashtags: \(video.formattedHashtags)")
    print("Description: \(video.description)")
}
```

### Video Download URLs

Direct CDN links to the video file are extracted from the same page fetch. No signature solving or additional requests needed.

```swift
let result = try await TikTokTranscript.fetch("https://www.tiktok.com/@user/video/123")

if let video = result.video {
    // Best quality URL (highest resolution variant → play URL → download URL)
    if let bestUrl = video.bestUrl {
        print("Download: \(bestUrl)")
    }

    // Direct play URL (no watermark)
    if let playUrl = video.playUrl {
        print("Play: \(playUrl)")
    }

    // Download URL (may include watermark)
    if let downloadUrl = video.downloadUrl {
        print("Download (watermarked): \(downloadUrl)")
    }

    // All available quality variants
    for variant in video.variants {
        print("\(variant.quality ?? "unknown") — \(variant.width)x\(variant.height)")
        if let codec = variant.codec {
            print("  Codec: \(codec)")
        }
        if let bitrate = variant.bitrateKbps {
            print("  Bitrate: \(bitrate) kbps")
        }
        print("  URL: \(variant.url)")
    }
}
```

> **Note:** TikTok CDN URLs expire after a few hours. Use them promptly after fetching.

### Timestamped Segments

```swift
let result = try await TikTokTranscript.fetch("https://www.tiktok.com/@user/video/123")

// Quick dump of entire transcript with timestamps
print(result.timestampedText)

// Or iterate segments individually
for segment in result.segments {
    print("[\(segment.formattedStart)] \(segment.text)")
}
```

### Specify Language Preferences

```swift
// Prefer Spanish, fall back to English
let result = try await TikTokTranscript.fetch(url, languages: ["spa", "eng"])
print("Language: \(result.language)")
```

### List Available Captions

```swift
let list = try await TikTokTranscript.list("https://www.tiktok.com/@user/video/123")

for track in list.tracks {
    print(track.language)
}

print("Languages: \(list.availableLanguages)")
```

### Error Handling

```swift
do {
    let result = try await TikTokTranscript.fetch(url)
    print(result.plainText)
} catch TikTokTranscriptError.noCaptions {
    print("No captions available for this video")
} catch TikTokTranscriptError.blocked {
    print("TikTok is blocking the request — try disabling App Sandbox")
} catch TikTokTranscriptError.noRehydrationData {
    print("TikTok served a JS challenge — disable App Sandbox")
} catch TikTokTranscriptError.videoNotFound {
    print("Video doesn't exist or is private")
} catch {
    print("Error: \(error.localizedDescription)")
}
```

## Models

### `FetchedTranscript`

The result of fetching a transcript.

| Property | Type | Description |
|----------|------|-------------|
| `segments` | `[TranscriptSegment]` | Timestamped transcript segments |
| `video` | `VideoMetadata?` | Video metadata (author, stats, URLs, etc.) |
| `language` | `String` | Language code of the fetched transcript |
| `plainText` | `String` | All segment text joined together |
| `timestampedText` | `String` | Full transcript with `[M:SS]` timestamps |
| `duration` | `Double` | Total transcript duration in seconds |
| `formattedDuration` | `String` | Duration as `"M:SS"` or `"H:MM:SS"` |
| `count` | `Int` | Number of segments |

### `TranscriptSegment`

A single timed segment.

| Property | Type | Description |
|----------|------|-------------|
| `text` | `String` | The text content |
| `start` | `Double` | Start time in seconds |
| `duration` | `Double` | Display duration in seconds |
| `end` | `Double` | End time (`start + duration`) |
| `language` | `String` | Language code |
| `formattedStart` | `String` | Start time as `"M:SS"` or `"H:MM:SS"` |

### `VideoMetadata`

Metadata about the video.

| Property | Type | Description |
|----------|------|-------------|
| `videoId` | `String` | TikTok video ID |
| `description` | `String` | Video caption/description |
| `author` | `String` | Creator's display name |
| `authorHandle` | `String` | Creator's handle (without @) |
| `authorVerified` | `Bool` | Whether creator is verified |
| `duration` | `Int` | Duration in seconds |
| `formattedDuration` | `String` | Duration as `"M:SS"` |
| `playCount` | `Int` | Total plays |
| `formattedPlayCount` | `String` | Plays with grouping separators |
| `likeCount` | `Int` | Total likes |
| `formattedLikeCount` | `String` | Likes with grouping separators |
| `commentCount` | `Int` | Total comments |
| `shareCount` | `Int` | Total shares |
| `collectCount` | `Int` | Total saves/bookmarks |
| `musicTitle` | `String` | Sound/music title |
| `musicAuthor` | `String` | Sound/music author |
| `createdTime` | `Date?` | When the video was posted |
| `hashtags` | `[String]` | Hashtags from the caption |
| `formattedHashtags` | `String` | Hashtags with # prefixes |
| `coverUrl` | `String?` | Cover image URL |
| `url` | `String?` | Full TikTok video URL |
| `playUrl` | `String?` | Direct play URL (no watermark) |
| `downloadUrl` | `String?` | Download URL (may have watermark) |
| `variants` | `[VideoVariant]` | Available quality variants |
| `bestUrl` | `URL?` | Highest-quality direct download URL |

### `VideoVariant`

A single video quality variant.

| Property | Type | Description |
|----------|------|-------------|
| `url` | `String` | Direct URL to this variant |
| `width` | `Int` | Width in pixels |
| `height` | `Int` | Height in pixels |
| `quality` | `String?` | Quality label (e.g., `"720p"`, `"1080p"`) |
| `codec` | `String?` | Video codec (e.g., `"h264"`, `"h265"`) |
| `bitrateKbps` | `Int?` | Bitrate in kilobits per second |
| `contentType` | `String` | Always `"video/mp4"` |

### `CaptionTrack`

An available caption track.

| Property | Type | Description |
|----------|------|-------------|
| `language` | `String` | Language code (e.g., "eng-US") |

### `CaptionList`

Result of listing available captions.

| Property | Type | Description |
|----------|------|-------------|
| `tracks` | `[CaptionTrack]` | All available tracks |
| `availableLanguages` | `[String]` | All language codes |

## How It Works

This library extracts data from TikTok's public page HTML:

1. **Fetch the video page** — with a browser-like User-Agent
2. **Extract rehydration JSON** — from the `__UNIVERSAL_DATA_FOR_REHYDRATION__` script tag
3. **Navigate to video data** — `__DEFAULT_SCOPE__` → `webapp.video-detail` → `itemInfo` → `itemStruct`
4. **Extract caption URLs** — from `video.claInfo.captionInfos` or `video.subtitleInfos`
5. **Extract video URLs** — from `video.playAddr`, `video.downloadAddr`, and `video.bitrateInfo`
6. **Fetch the WebVTT file** — from TikTok's CDN
7. **Parse into segments** — with timestamps and duration

Video URLs are direct CDN links — no signature solving or cipher decryption needed (unlike YouTube). The URLs do expire after a few hours, so they should be used promptly after fetching.

## App Sandbox Note

TikTok may serve a JavaScript challenge page instead of the actual video page when requests come from sandboxed macOS apps. If you encounter `noRehydrationData` errors during development, disable App Sandbox in your Xcode target's Signing & Capabilities. This is not an issue on iOS.

## Limitations

- **CDN URL expiry** — Video download URLs expire after a few hours. Fetch and use them in the same session.
- **App Sandbox** — macOS sandboxed apps may receive JS challenge pages instead of video data. See note above.
- **Captions required** — Not all TikTok videos have captions. The `noCaptions` error indicates this. Video URLs are still available via `VideoMetadata` even when captions are absent.
- **Page structure changes** — TikTok may change their page structure at any time. Updates will be provided as needed.
- **Rate limiting** — Making too many requests may result in `blocked` errors.

## Testing

```bash
swift test
```

The test suite includes unit tests for VTT parsing, timestamp formatting, caption track selection, video URL extraction, and variant selection, plus integration tests that fetch from TikTok's live servers (require network access and sandbox disabled).

## Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Add tests for new functionality
4. Ensure all tests pass
5. Submit a pull request

## License

MIT License — see LICENSE file for details.

## Author

Created by David Sherlock ([ArrayPress](https://github.com/arraypress)) in 2026.
