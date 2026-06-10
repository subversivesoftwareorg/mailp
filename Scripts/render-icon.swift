#!/usr/bin/env swift

import AppKit
import CoreGraphics
import Foundation

// Render the Mail+ app icon: a white envelope with a green "+" badge
// on a deep-blue gradient background.
//
// Usage:
//   swift Scripts/render-icon.swift              # render + install into asset catalog
//   swift Scripts/render-icon.swift preview      # render 1024px PNG only

// ── Background ──────────────────────────────────────────────────

func drawBackground(_ ctx: CGContext, size: CGFloat) {
    let inset = size * 0.02
    let rect = CGRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
    let cr = size * 0.225
    let bgPath = CGPath(roundedRect: rect, cornerWidth: cr, cornerHeight: cr, transform: nil)

    ctx.saveGState()
    ctx.addPath(bgPath)
    ctx.clip()

    let cs = CGColorSpaceCreateDeviceRGB()
    let colors = [
        CGColor(red: 0.06, green: 0.10, blue: 0.26, alpha: 1.0),
        CGColor(red: 0.13, green: 0.28, blue: 0.58, alpha: 1.0),
        CGColor(red: 0.22, green: 0.50, blue: 0.85, alpha: 1.0),
    ] as CFArray
    if let g = CGGradient(colorsSpace: cs, colors: colors, locations: [0.0, 0.5, 1.0]) {
        ctx.drawLinearGradient(g,
                               start: CGPoint(x: size * 0.3, y: size),
                               end: CGPoint(x: size * 0.7, y: 0),
                               options: [])
    }

    // Subtle upper glow
    let glowColors = [
        CGColor(red: 1, green: 1, blue: 1, alpha: 0.08),
        CGColor(red: 1, green: 1, blue: 1, alpha: 0.0),
    ] as CFArray
    if let glow = CGGradient(colorsSpace: cs, colors: glowColors, locations: [0.0, 1.0]) {
        ctx.drawRadialGradient(glow,
                               startCenter: CGPoint(x: size * 0.45, y: size * 0.72),
                               startRadius: 0,
                               endCenter: CGPoint(x: size * 0.45, y: size * 0.72),
                               endRadius: size * 0.45,
                               options: [])
    }

    ctx.restoreGState()
}

// ── Envelope ────────────────────────────────────────────────────

func drawEnvelope(_ ctx: CGContext, size: CGFloat) {
    let left = size * 0.17
    let right = size * 0.83
    let bottom = size * 0.28
    let top = size * 0.62
    let w = right - left
    let h = top - bottom
    let cx = (left + right) / 2
    let cr = size * 0.015

    // Shadow
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -size * 0.018),
                  blur: size * 0.05,
                  color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.40))

    // Body
    let bodyRect = CGRect(x: left, y: bottom, width: w, height: h)
    let bodyPath = CGPath(roundedRect: bodyRect, cornerWidth: cr, cornerHeight: cr, transform: nil)
    ctx.addPath(bodyPath)
    ctx.setFillColor(CGColor(red: 0.97, green: 0.97, blue: 1.0, alpha: 1.0))
    ctx.fillPath()
    ctx.restoreGState()

    // Paper gradient overlay
    ctx.saveGState()
    ctx.addPath(bodyPath)
    ctx.clip()
    let cs = CGColorSpaceCreateDeviceRGB()
    let paperColors = [
        CGColor(red: 1, green: 1, blue: 1, alpha: 0.06),
        CGColor(red: 0, green: 0, blue: 0, alpha: 0.03),
    ] as CFArray
    if let pg = CGGradient(colorsSpace: cs, colors: paperColors, locations: [0.0, 1.0]) {
        ctx.drawLinearGradient(pg,
                               start: CGPoint(x: cx, y: top),
                               end: CGPoint(x: cx, y: bottom),
                               options: [])
    }
    ctx.restoreGState()

    // V-fold lines
    let foldY = top - h * 0.55
    ctx.saveGState()
    ctx.setStrokeColor(CGColor(red: 0.72, green: 0.78, blue: 0.88, alpha: 1.0))
    ctx.setLineWidth(size * 0.009)
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)
    ctx.move(to: CGPoint(x: left + cr, y: top - cr))
    ctx.addLine(to: CGPoint(x: cx, y: foldY))
    ctx.addLine(to: CGPoint(x: right - cr, y: top - cr))
    ctx.strokePath()
    ctx.restoreGState()
}

// ── "+" Badge ───────────────────────────────────────────────────

func drawBadge(_ ctx: CGContext, size: CGFloat) {
    let r = size * 0.105
    let cx = size * 0.76
    let cy = size * 0.64

    // Shadow
    ctx.saveGState()
    ctx.setShadow(offset: CGSize(width: 0, height: -size * 0.01),
                  blur: size * 0.025,
                  color: CGColor(red: 0, green: 0, blue: 0, alpha: 0.30))

    // Green circle
    let rect = CGRect(x: cx - r, y: cy - r, width: r * 2, height: r * 2)
    ctx.addEllipse(in: rect)
    ctx.setFillColor(CGColor(red: 0.20, green: 0.78, blue: 0.35, alpha: 1.0))
    ctx.fillPath()
    ctx.restoreGState()

    // Rim
    ctx.saveGState()
    ctx.addEllipse(in: rect.insetBy(dx: size * 0.003, dy: size * 0.003))
    ctx.setStrokeColor(CGColor(red: 0.15, green: 0.65, blue: 0.28, alpha: 0.4))
    ctx.setLineWidth(size * 0.004)
    ctx.strokePath()
    ctx.restoreGState()

    // White "+"
    let barHalf = r * 0.48
    let barWidth = size * 0.030
    ctx.saveGState()
    ctx.setStrokeColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
    ctx.setLineWidth(barWidth)
    ctx.setLineCap(.round)

    ctx.move(to: CGPoint(x: cx - barHalf, y: cy))
    ctx.addLine(to: CGPoint(x: cx + barHalf, y: cy))
    ctx.strokePath()

    ctx.move(to: CGPoint(x: cx, y: cy - barHalf))
    ctx.addLine(to: CGPoint(x: cx, y: cy + barHalf))
    ctx.strokePath()
    ctx.restoreGState()
}

// ── Compose ─────────────────────────────────────────────────────

func renderIcon(size: CGFloat) -> NSImage {
    let px = Int(size)
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: size, height: size)

    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    guard let ctx = NSGraphicsContext.current?.cgContext else {
        let img = NSImage(size: NSSize(width: size, height: size))
        img.addRepresentation(rep)
        return img
    }

    drawBackground(ctx, size: size)

    let inset = size * 0.02
    let rect = CGRect(x: inset, y: inset, width: size - inset * 2, height: size - inset * 2)
    let cr = size * 0.225
    ctx.saveGState()
    ctx.addPath(CGPath(roundedRect: rect, cornerWidth: cr, cornerHeight: cr, transform: nil))
    ctx.clip()

    drawEnvelope(ctx, size: size)
    drawBadge(ctx, size: size)

    ctx.restoreGState()
    NSGraphicsContext.current = nil

    let image = NSImage(size: NSSize(width: size, height: size))
    image.addRepresentation(rep)
    return image
}

// ── Image I/O ───────────────────────────────────────────────────

func savePNG(_ image: NSImage, to path: String) {
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else {
        print("Failed to render PNG: \(path)")
        return
    }
    try! png.write(to: URL(fileURLWithPath: path))
    print("  \(path)")
}

// ── Main ────────────────────────────────────────────────────────

let scriptPath = CommandLine.arguments[0]
let projectDir: String
if scriptPath.contains("/Scripts/") {
    projectDir = URL(fileURLWithPath: scriptPath)
        .deletingLastPathComponent()
        .deletingLastPathComponent()
        .path
} else {
    projectDir = FileManager.default.currentDirectoryPath
}

let assetDir = projectDir + "/MailPlus/Resources/Assets.xcassets/AppIcon.appiconset"

if CommandLine.arguments.count > 1 && CommandLine.arguments[1] == "preview" {
    let buildDir = projectDir + "/.build"
    try? FileManager.default.createDirectory(atPath: buildDir, withIntermediateDirectories: true)
    savePNG(renderIcon(size: 1024), to: buildDir + "/icon-1024.png")
    print("Preview: open .build/icon-1024.png")
    exit(0)
}

// Render all sizes into the asset catalog
try? FileManager.default.createDirectory(atPath: assetDir, withIntermediateDirectories: true)

let sizes: [(CGFloat, String)] = [
    (16,   "icon_16x16.png"),
    (32,   "icon_16x16@2x.png"),
    (32,   "icon_32x32.png"),
    (64,   "icon_32x32@2x.png"),
    (128,  "icon_128x128.png"),
    (256,  "icon_128x128@2x.png"),
    (256,  "icon_256x256.png"),
    (512,  "icon_256x256@2x.png"),
    (512,  "icon_512x512.png"),
    (1024, "icon_512x512@2x.png"),
]

print("Rendering Mail+ icon...")
for (px, filename) in sizes {
    savePNG(renderIcon(size: px), to: assetDir + "/" + filename)
}

// Also save a preview
let buildDir = projectDir + "/.build"
try? FileManager.default.createDirectory(atPath: buildDir, withIntermediateDirectories: true)
savePNG(renderIcon(size: 1024), to: buildDir + "/icon-1024.png")

print("\nDone! Icon installed to MailPlus/Resources/Assets.xcassets/AppIcon.appiconset/")
print("Preview: open .build/icon-1024.png")
