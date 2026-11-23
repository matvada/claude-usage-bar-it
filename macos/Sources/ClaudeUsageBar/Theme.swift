import AppKit
import SwiftUI

/// Palette ispirata all'interfaccia di Claude: terracotta, crema, oliva.
enum Theme {
    static let orangeNS = NSColor(srgbRed: 0xD9/255, green: 0x77/255, blue: 0x57/255, alpha: 1) // #D97757
    static let redNS = NSColor(srgbRed: 0xBF/255, green: 0x4D/255, blue: 0x43/255, alpha: 1)    // #BF4D43
    static let oliveNS = NSColor(srgbRed: 0x78/255, green: 0x8C/255, blue: 0x5D/255, alpha: 1)  // #788C5D

    static let orange = Color(nsColor: orangeNS)
    static let red = Color(nsColor: redNS)
    static let olive = Color(nsColor: oliveNS)
    static let blue = Color(red: 0x6A/255, green: 0x9B/255, blue: 0xCC/255)       // #6A9BCC
    static let accent = orange

    /// Fondo crema in chiaro, grigio caldo in scuro (come claude.ai).
    static let paper = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(srgbRed: 0x26/255, green: 0x26/255, blue: 0x24/255, alpha: 1)  // #262624
            : NSColor(srgbRed: 0xFA/255, green: 0xF9/255, blue: 0xF5/255, alpha: 1)  // #FAF9F5
    })

    /// Binario delle barre.
    static let track = Color(nsColor: NSColor(name: nil) { appearance in
        appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
            ? NSColor(white: 1, alpha: 0.10)
            : NSColor(srgbRed: 0xE8/255, green: 0xE6/255, blue: 0xDC/255, alpha: 1)  // #E8E6DC
    })

    static func serif(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .serif).weight(weight)
    }

    /// Verde oliva sotto il 60%, terracotta fino all'85%, rosso mattone oltre.
    static func level(_ fraction: Double) -> Color {
        switch fraction {
        case ..<0.60: return olive
        case 0.60..<0.85: return orange
        default: return red
        }
    }

    static func levelNS(_ fraction: Double) -> NSColor {
        switch fraction {
        case ..<0.60: return oliveNS
        case 0.60..<0.85: return orangeNS
        default: return redNS
        }
    }
}

/// Barra di avanzamento arrotondata in stile Claude.
struct ClaudeBar: View {
    let fraction: Double
    var color: Color? = nil
    var height: CGFloat = 6

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(Theme.track)
                Capsule()
                    .fill(color ?? Theme.level(fraction))
                    .frame(width: max(0, min(1, fraction)) * geo.size.width)
            }
        }
        .frame(height: height)
        .animation(.easeOut(duration: 0.4), value: fraction)
    }
}
