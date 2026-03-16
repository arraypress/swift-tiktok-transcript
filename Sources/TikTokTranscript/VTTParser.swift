//
//  VTTParser.swift
//  TikTokTranscript
//
//  Created by David Sherlock on 2026.
//

import Foundation

/// Parses WebVTT caption files into ``TranscriptSegment`` arrays.
///
/// TikTok returns captions as WebVTT files with timestamp cues:
/// ```
/// 00:00:00.060 --> 00:00:01.040
/// Baby,
///
/// 00:00:02.100 --> 00:00:03.160
/// baby,
/// ```
enum VTTParser {
    
    /// Parses WebVTT content into an array of segments.
    ///
    /// - Parameters:
    ///   - vtt: The raw WebVTT string.
    ///   - language: The language code to attach to each segment.
    /// - Returns: An array of ``TranscriptSegment`` values.
    static func parse(_ vtt: String, language: String) -> [TranscriptSegment] {
        var segments: [TranscriptSegment] = []
        let lines = vtt.components(separatedBy: .newlines)
        var i = 0
        
        while i < lines.count {
            let line = lines[i].trimmingCharacters(in: .whitespaces)
            
            // Look for timestamp lines: "00:00:01.234 --> 00:00:03.456"
            if line.contains("-->") {
                let parts = line.components(separatedBy: "-->")
                guard parts.count == 2 else {
                    i += 1
                    continue
                }
                
                let startTime = parseTimestamp(parts[0].trimmingCharacters(in: .whitespaces))
                let endTime = parseTimestamp(parts[1].trimmingCharacters(in: .whitespaces))
                
                // Collect text lines until empty line or next timestamp
                var textLines: [String] = []
                i += 1
                while i < lines.count {
                    let textLine = lines[i].trimmingCharacters(in: .whitespaces)
                    if textLine.isEmpty || textLine.contains("-->") { break }
                    // Skip VTT cue identifiers (pure numbers)
                    if Int(textLine) == nil {
                        let cleaned = stripTags(textLine)
                        if !cleaned.isEmpty { textLines.append(cleaned) }
                    }
                    i += 1
                }
                
                let text = textLines.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
                if !text.isEmpty {
                    segments.append(TranscriptSegment(
                        text: text,
                        start: startTime,
                        duration: max(endTime - startTime, 0),
                        language: language
                    ))
                }
            } else {
                i += 1
            }
        }
        
        return segments
    }
    
    /// Parses a WebVTT timestamp string to seconds.
    ///
    /// Handles formats: `"00:00:01.234"` (H:MM:SS.mmm) and `"00:01.234"` (MM:SS.mmm).
    private static func parseTimestamp(_ timestamp: String) -> Double {
        let clean = timestamp.components(separatedBy: " ").first ?? timestamp
        let parts = clean.components(separatedBy: ":")
        var seconds: Double = 0
        
        if parts.count == 3 {
            seconds += (Double(parts[0]) ?? 0) * 3600
            seconds += (Double(parts[1]) ?? 0) * 60
            seconds += Double(parts[2]) ?? 0
        } else if parts.count == 2 {
            seconds += (Double(parts[0]) ?? 0) * 60
            seconds += Double(parts[1]) ?? 0
        }
        
        return seconds
    }
    
    /// Strips VTT formatting tags (e.g., `<c>`, `</c>`, `<00:00:01.234>`).
    private static func stripTags(_ text: String) -> String {
        text.replacingOccurrences(of: "<[^>]*>", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
}
