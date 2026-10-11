import AppKit
import SwiftUI

enum Theme {
    static let paper = Color(nsColor: dynamic(
        light: NSColor(srgbRed: 0.965, green: 0.941, blue: 0.894, alpha: 1),
        dark: NSColor(srgbRed: 0.122, green: 0.110, blue: 0.098, alpha: 1)
    ))
    static let ink = Color(nsColor: dynamic(
        light: NSColor(srgbRed: 0.176, green: 0.145, blue: 0.110, alpha: 1),
        dark: NSColor(srgbRed: 0.949, green: 0.918, blue: 0.855, alpha: 1)
    ))
    static let muted = Color(nsColor: dynamic(
        light: NSColor(srgbRed: 0.420, green: 0.353, blue: 0.275, alpha: 1),
        dark: NSColor(srgbRed: 0.769, green: 0.706, blue: 0.612, alpha: 1)
    ))
    static let accent = Color(nsColor: dynamic(
        light: NSColor(srgbRed: 0.545, green: 0.302, blue: 0.165, alpha: 1),
        dark: NSColor(srgbRed: 0.855, green: 0.675, blue: 0.455, alpha: 1)
    ))
    static let card = Color(nsColor: dynamic(
        light: NSColor(srgbRed: 0.992, green: 0.976, blue: 0.949, alpha: 1),
        dark: NSColor(srgbRed: 0.176, green: 0.157, blue: 0.137, alpha: 1)
    ))
    static let line = Color(nsColor: dynamic(
        light: NSColor(srgbRed: 0.855, green: 0.800, blue: 0.710, alpha: 1),
        dark: NSColor(srgbRed: 0.333, green: 0.290, blue: 0.243, alpha: 1)
    ))

    static func serif(_ size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .custom("Songti SC", size: size).weight(weight)
    }

    private static func dynamic(light: NSColor, dark: NSColor) -> NSColor {
        NSColor(name: nil, dynamicProvider: { appearance in
            appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua ? dark : light
        })
    }
}
