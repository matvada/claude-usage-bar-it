import AppKit

/// The page the browser shows once the sign-in redirect is handled: a plain page
/// with the app's wordmark and a centered title and message, like Codex CLI's.
@MainActor
enum SignInPage {
    static func html(title: String, message: String) -> String {
        let favicon = iconDataURI.map { #"<link rel="icon" href="\#($0)">"# } ?? ""
        let icon = iconDataURI.map { #"<img src="\#($0)" alt="">"# } ?? ""
        return """
        <!doctype html>
        <html lang="it">
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <meta name="color-scheme" content="light dark">
        <title>Consumi Claude</title>
        \(favicon)
        <style>
        :root {
          --secondary: #87867f; color: #141413; background: #faf9f5;
          font-family: -apple-system, BlinkMacSystemFont, system-ui, sans-serif; -webkit-font-smoothing: antialiased;
        }
        @media (prefers-color-scheme: dark) { :root { --secondary: #b0aea5; color: #faf9f5; background: #262624; } }
        body { margin: 0; }
        header { position: fixed; top: 18px; left: 20px; display: flex; align-items: center; gap: 8px; font-size: 15px; font-weight: 600; }
        header img { width: 20px; height: 20px; }
        main { min-height: 100vh; display: grid; place-content: center; padding: 0 24px; text-align: center; }
        h1 { margin: 0 0 8px; font-family: ui-serif, Georgia, serif; font-size: 26px; font-weight: 500; }
        p { max-width: 30em; margin: 0 auto; font-size: 14px; color: var(--secondary); }
        </style>
        <header>\(icon)Consumi Claude</header>
        <main>
          <h1>\(escaped(title))</h1>
          <p>\(escaped(message))</p>
        </main>
        </html>
        """
    }

    private static let iconDataURI: String? = {
        let size = 64
        guard let icon = NSApplication.shared.applicationIconImage,
              let bitmap = NSBitmapImageRep(
                  bitmapDataPlanes: nil, pixelsWide: size, pixelsHigh: size, bitsPerSample: 8, samplesPerPixel: 4,
                  hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0
              ) else { return nil }
        let rect = NSRect(x: 0, y: 0, width: size, height: size)
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: bitmap)
        // The icon is drawn edge to edge for macOS to round; a browser won't round it.
        NSBezierPath(roundedRect: rect, xRadius: rect.width * 0.225, yRadius: rect.height * 0.225).addClip()
        icon.draw(in: rect)
        NSGraphicsContext.restoreGraphicsState()
        guard let png = bitmap.representation(using: .png, properties: [:]) else { return nil }
        return "data:image/png;base64,\(png.base64EncodedString())"
    }()

    private static func escaped(_ text: String) -> String {
        text.replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
    }
}
