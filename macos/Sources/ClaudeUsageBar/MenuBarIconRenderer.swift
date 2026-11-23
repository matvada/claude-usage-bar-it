import AppKit

private let labelWidth: CGFloat = 14
private let barWidth: CGFloat = 24
private let barHeight: CGFloat = 5
private let rowGap: CGFloat = 3
private let labelGap: CGFloat = 2
private let cornerRadius: CGFloat = 2
private let logoSize: CGFloat = 12
private let logoGap: CGFloat = 2
private let barsWidth: CGFloat = labelWidth + labelGap + barWidth + 2
private let iconWidth: CGFloat = logoSize + logoGap + barsWidth
private let iconHeight: CGFloat = 18
private let fontSize: CGFloat = 8

// Le etichette usano il colore del testo della barra dei menu (chiaro o scuro),
// quindi si costruiscono al momento del disegno e non vanno in cache.
private func drawRow(label: String, barX: CGFloat, barY: CGFloat, labelX: CGFloat, drawBarFill: (CGFloat, CGFloat) -> Void) {
    let font = NSFont.monospacedSystemFont(ofSize: fontSize, weight: .medium)
    let str = NSAttributedString(string: label, attributes: [.font: font, .foregroundColor: NSColor.labelColor])
    let size = str.size()
    let labelY = barY + (barHeight - size.height) / 2
    str.draw(at: NSPoint(x: labelX + labelWidth - size.width, y: labelY))
    drawBarFill(barX, barY)
}

func renderIcon(pct5h: Double?, pct7d: Double) -> NSImage {
    let image = NSImage(size: NSSize(width: iconWidth, height: iconHeight), flipped: true) { _ in
        let offset = logoSize + logoGap
        let barX = offset + labelWidth + labelGap
        let topY = (iconHeight - barHeight * 2 - rowGap) / 2
        let bottomY = pct5h == nil ? (iconHeight - barHeight) / 2 : topY + barHeight + rowGap

        drawClaudeLogo(x: 0, y: (iconHeight - logoSize) / 2, size: logoSize)

        if let pct5h {
            drawRow(label: "5h", barX: barX, barY: topY, labelX: offset) { x, y in
                drawBar(x: x, y: y, width: barWidth, height: barHeight, cornerRadius: cornerRadius, pct: pct5h)
            }
        }
        drawRow(label: "7g", barX: barX, barY: bottomY, labelX: offset) { x, y in
            drawBar(x: x, y: y, width: barWidth, height: barHeight, cornerRadius: cornerRadius, pct: pct7d)
        }
        return true
    }
    image.isTemplate = false
    return image
}

func renderUnauthenticatedIcon() -> NSImage {
    let image = NSImage(size: NSSize(width: iconWidth, height: iconHeight), flipped: true) { _ in
        let offset = logoSize + logoGap
        let barX = offset + labelWidth + labelGap
        let topY = (iconHeight - barHeight * 2 - rowGap) / 2
        let bottomY = topY + barHeight + rowGap

        drawClaudeLogo(x: 0, y: (iconHeight - logoSize) / 2, size: logoSize)

        drawRow(label: "5h", barX: barX, barY: topY, labelX: offset) { x, y in
            drawDashedBar(x: x, y: y, width: barWidth, height: barHeight, cornerRadius: cornerRadius)
        }
        drawRow(label: "7g", barX: barX, barY: bottomY, labelX: offset) { x, y in
            drawDashedBar(x: x, y: y, width: barWidth, height: barHeight, cornerRadius: cornerRadius)
        }
        return true
    }
    image.isTemplate = false
    return image
}

// MARK: - Bar drawing

private func drawBar(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, cornerRadius: CGFloat, pct: Double) {
    let bgRect = NSRect(x: x, y: y, width: width, height: height)
    let bgPath = NSBezierPath(roundedRect: bgRect, xRadius: cornerRadius, yRadius: cornerRadius)
    NSColor.labelColor.withAlphaComponent(0.22).setFill()
    bgPath.fill()

    let clampedPct = max(0, min(1, pct))
    if clampedPct > 0 {
        let fillWidth = width * clampedPct
        let fillRect = NSRect(x: x, y: y, width: fillWidth, height: height)
        let fillPath = NSBezierPath(roundedRect: fillRect, xRadius: cornerRadius, yRadius: cornerRadius)
        Theme.levelNS(clampedPct).setFill()
        fillPath.fill()
    }
}

private func drawDashedBar(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat, cornerRadius: CGFloat) {
    let rect = NSRect(x: x, y: y, width: width, height: height)
    let path = NSBezierPath(roundedRect: rect, xRadius: cornerRadius, yRadius: cornerRadius)
    NSColor.labelColor.withAlphaComponent(0.35).setStroke()
    path.lineWidth = 1
    let dashPattern: [CGFloat] = [2, 2]
    path.setLineDash(dashPattern, count: 2, phase: 0)
    path.stroke()
}

// MARK: - Claude logo (pre-rendered 512px template PNG)

let claudeLogoTemplate: NSImage? = {
    if let bundle = claudeUsageBarResourceBundle(),
       let png = bundle.url(forResource: "claude-logo", withExtension: "png"),
       let image = NSImage(contentsOf: png) {
        image.isTemplate = true
        return image
    }
    return nil
}()

/// Il logo in terracotta: si usa la forma del PNG come maschera e la si riempie di arancione.
private let claudeLogoOrange: NSImage? = {
    guard let logo = claudeLogoTemplate else { return nil }
    let size = logo.size
    let tinted = NSImage(size: size, flipped: false) { rect in
        logo.draw(in: rect)
        Theme.orangeNS.set()
        rect.fill(using: .sourceAtop)
        return true
    }
    tinted.isTemplate = false
    return tinted
}()

private func drawClaudeLogo(x: CGFloat, y: CGFloat, size: CGFloat) {
    guard let logo = claudeLogoOrange else { return }
    logo.draw(in: NSRect(x: x, y: y, width: size, height: size))
}
