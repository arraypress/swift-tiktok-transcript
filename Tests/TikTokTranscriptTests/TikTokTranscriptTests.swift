//
//  TikTokTranscriptTests.swift
//  TikTokTranscript
//
//  Created by David Sherlock on 2025.
//

import XCTest
@testable import TikTokTranscript

final class TikTokTranscriptTests: XCTestCase {

    // MARK: - VTT Parser

    func testParseSimpleVTT() {
        let vtt = """
        WEBVTT

        00:00:00.060 --> 00:00:01.040
        Baby,

        00:00:02.100 --> 00:00:03.160
        baby,
        """

        let segments = VTTParser.parse(vtt, language: "eng-US")
        XCTAssertEqual(segments.count, 2)
        XCTAssertEqual(segments[0].text, "Baby,")
        XCTAssertEqual(segments[0].start, 0.06)
        XCTAssertEqual(segments[0].language, "eng-US")
        XCTAssertEqual(segments[1].text, "baby,")
    }

    func testParseVTTWithMultilineText() {
        let vtt = """
        WEBVTT

        00:00:01.000 --> 00:00:03.000
        Hello everyone
        welcome to my video
        """

        let segments = VTTParser.parse(vtt, language: "eng")
        XCTAssertEqual(segments.count, 1)
        XCTAssertEqual(segments[0].text, "Hello everyone welcome to my video")
    }

    func testParseVTTWithTags() {
        let vtt = """
        WEBVTT

        00:00:00.000 --> 00:00:02.000
        <c>styled text</c>
        """

        let segments = VTTParser.parse(vtt, language: "eng")
        XCTAssertEqual(segments.count, 1)
        XCTAssertEqual(segments[0].text, "styled text")
    }

    func testParseVTTWithCueNumbers() {
        let vtt = """
        WEBVTT

        1
        00:00:00.000 --> 00:00:01.000
        First

        2
        00:00:01.000 --> 00:00:02.000
        Second
        """

        let segments = VTTParser.parse(vtt, language: "eng")
        XCTAssertEqual(segments.count, 2)
        XCTAssertEqual(segments[0].text, "First")
        XCTAssertEqual(segments[1].text, "Second")
    }

    func testParseEmptyVTT() {
        let segments = VTTParser.parse("", language: "eng")
        XCTAssertTrue(segments.isEmpty)
    }

    func testParseVTTTimestampFormats() {
        let vtt = """
        WEBVTT

        01:30:05.500 --> 01:30:08.000
        Long video
        """

        let segments = VTTParser.parse(vtt, language: "eng")
        XCTAssertEqual(segments.count, 1)
        XCTAssertEqual(segments[0].start, 5405.5, accuracy: 0.01) // 1h 30m 5.5s
        XCTAssertEqual(segments[0].duration, 2.5, accuracy: 0.01)
    }

    // MARK: - TranscriptSegment Convenience

    func testFormattedStart() {
        let segment = TranscriptSegment(text: "test", start: 65.5, duration: 1, language: "eng")
        XCTAssertEqual(segment.formattedStart, "1:05")
    }

    func testFormattedStartHours() {
        let segment = TranscriptSegment(text: "test", start: 3661, duration: 1, language: "eng")
        XCTAssertEqual(segment.formattedStart, "1:01:01")
    }

    func testFormattedStartZero() {
        let segment = TranscriptSegment(text: "test", start: 0, duration: 1, language: "eng")
        XCTAssertEqual(segment.formattedStart, "0:00")
    }

    func testSegmentEnd() {
        let segment = TranscriptSegment(text: "test", start: 10, duration: 2.5, language: "eng")
        XCTAssertEqual(segment.end, 12.5)
    }

    // MARK: - CaptionList

    func testFindTrackExactMatch() {
        let tracks = [
            CaptionTrack(language: "eng-US", url: "url1"),
            CaptionTrack(language: "spa-ES", url: "url2"),
        ]
        let list = CaptionList(tracks: tracks)
        XCTAssertEqual(list.findTrack(languages: ["spa-ES"])?.language, "spa-ES")
    }

    func testFindTrackPrefixMatch() {
        let tracks = [
            CaptionTrack(language: "eng-US", url: "url1"),
            CaptionTrack(language: "spa-ES", url: "url2"),
        ]
        let list = CaptionList(tracks: tracks)
        XCTAssertEqual(list.findTrack(languages: ["eng"])?.language, "eng-US")
    }

    func testFindTrackFallback() {
        let tracks = [
            CaptionTrack(language: "eng-US", url: "url1"),
        ]
        let list = CaptionList(tracks: tracks)
        XCTAssertEqual(list.findTrack(languages: ["fra", "eng"])?.language, "eng-US")
    }

    func testFindTrackReturnsNil() {
        let tracks = [
            CaptionTrack(language: "eng-US", url: "url1"),
        ]
        let list = CaptionList(tracks: tracks)
        XCTAssertNil(list.findTrack(languages: ["fra", "deu"]))
    }

    func testAvailableLanguages() {
        let tracks = [
            CaptionTrack(language: "eng-US", url: "url1"),
            CaptionTrack(language: "spa-ES", url: "url2"),
        ]
        let list = CaptionList(tracks: tracks)
        XCTAssertEqual(list.availableLanguages, ["eng-US", "spa-ES"])
    }

    // MARK: - FetchedTranscript

    func testPlainText() {
        let segments = [
            TranscriptSegment(text: "Hello", start: 0, duration: 1, language: "eng"),
            TranscriptSegment(text: "World", start: 1, duration: 1, language: "eng"),
        ]
        let result = FetchedTranscript(segments: segments, video: nil, language: "eng")
        XCTAssertEqual(result.plainText, "Hello World")
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result.duration, 2.0)
    }

    func testTimestampedText() {
        let segments = [
            TranscriptSegment(text: "Hello", start: 0, duration: 1, language: "eng"),
            TranscriptSegment(text: "World", start: 65, duration: 1, language: "eng"),
        ]
        let result = FetchedTranscript(segments: segments, video: nil, language: "eng")
        XCTAssertEqual(result.timestampedText, "[0:00] Hello\n[1:05] World")
    }

    func testEmptyTranscript() {
        let result = FetchedTranscript(segments: [], video: nil, language: "eng")
        XCTAssertEqual(result.plainText, "")
        XCTAssertEqual(result.count, 0)
        XCTAssertEqual(result.duration, 0)
        XCTAssertEqual(result.formattedDuration, "0:00")
    }

    // MARK: - Error Descriptions

    func testAllErrorsHaveDescriptions() {
        let errors: [TikTokTranscriptError] = [
            .invalidUrl,
            .networkError("timeout"),
            .blocked,
            .videoNotFound,
            .noRehydrationData,
            .noCaptions,
            .noCaptionForLanguage(requested: ["eng"], available: ["spa"]),
            .captionFetchFailed,
            .parsingError("bad json"),
        ]

        for error in errors {
            XCTAssertNotNil(error.errorDescription)
            XCTAssertFalse(error.errorDescription!.isEmpty)
        }
    }

    func testErrorEquatable() {
        XCTAssertEqual(TikTokTranscriptError.blocked, .blocked)
        XCTAssertEqual(TikTokTranscriptError.noCaptions, .noCaptions)
        XCTAssertNotEqual(TikTokTranscriptError.blocked, .noCaptions)
    }

    // MARK: - Integration Tests (require network + sandbox disabled)

    func testFetchBrookeMonk() async throws {
        let result = try await TikTokTranscript.fetch("https://www.tiktok.com/@brookemonk_/video/7616832546759920926")

        XCTAssertFalse(result.segments.isEmpty)
        XCTAssertFalse(result.plainText.isEmpty)

        // Metadata should be present
        XCTAssertNotNil(result.video)
        XCTAssertFalse(result.video?.author.isEmpty ?? true)
        XCTAssertFalse(result.video?.authorHandle.isEmpty ?? true)
        XCTAssertGreaterThan(result.video?.duration ?? 0, 0)
    }

    func testFetchMetadataFields() async throws {
        let result = try await TikTokTranscript.fetch("https://www.tiktok.com/@brookemonk_/video/7616832546759920926")
        let video = try XCTUnwrap(result.video)

        XCTAssertFalse(video.videoId.isEmpty)
        XCTAssertFalse(video.author.isEmpty)
        XCTAssertFalse(video.authorHandle.isEmpty)
        XCTAssertGreaterThan(video.duration, 0)
        XCTAssertGreaterThan(video.playCount, 0)
        XCTAssertGreaterThan(video.likeCount, 0)
    }

    func testListCaptions() async throws {
        let list = try await TikTokTranscript.list("https://www.tiktok.com/@brookemonk_/video/7616832546759920926")

        XCTAssertFalse(list.tracks.isEmpty)
        XCTAssertFalse(list.availableLanguages.isEmpty)
        XCTAssertTrue(list.availableLanguages.contains(where: { $0.hasPrefix("eng") }))
    }
}
