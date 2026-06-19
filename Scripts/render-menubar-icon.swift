#!/usr/bin/env swift

import AppKit
import CoreGraphics
import Foundation

// Renders the Triage menu bar template icon: simplified envelope with three
// triage arrows. Output is black-on-transparent so macOS can tint it for
// light/dark mode (template image).
//
// Menu bar icons are 18pt tall (@1x). We render @1x (18px) and @2x (36px).

func renderMenuBarIcon(px: Int) -> NSImage {
    let s = CGFloat(px)
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil, pixelsWide: px, pixelsHigh: px,
        bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0)!
    rep.size = NSSize(width: s, height: s)

    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)
    guard let ctx = NSGraphicsContext.current?.cgContext else { fatalError() }

    let black = CGColor(red: 0, green: 0, blue: 0, alpha: 0.85)
    let lineW = s * 0.065
    ctx.setLineCap(.round)
    ctx.setLineJoin(.round)

    // ── Envelope body ──────────────────────────────────────────
    let envLeft = s * 0.05
    let envRight = s * 0.95
    let envBottom = s * 0.10
    let envTop = s * 0.52
    let envW = envRight - envLeft
    let envH = envTop - envBottom
    let cx = s * 0.50
    let cr = s * 0.04

    let envRect = CGRect(x: envLeft, y: envBottom, width: envW, height: envH)
    let envPath = CGPath(roundedRect: envRect, cornerWidth: cr, cornerHeight: cr, transform: nil)

    ctx.setStrokeColor(black)
    ctx.setLineWidth(lineW)
    ctx.addPath(envPath)
    ctx.strokePath()

    // V-fold
    let foldY = envTop - envH * 0.50
    ctx.setLineWidth(lineW * 0.8)
    ctx.move(to: CGPoint(x: envLeft + cr + lineW * 0.3, y: envTop - cr))
    ctx.addLine(to: CGPoint(x: cx, y: foldY))
    ctx.addLine(to: CGPoint(x: envRight - cr - lineW * 0.3, y: envTop - cr))
    ctx.strokePath()

    // ── Three arrows emerging from envelope top ────────────────
    let arrowLineW = lineW * 1.0
    let headLen = s * 0.08
    let headAngle: CGFloat = .pi / 5
    ctx.setLineWidth(arrowLineW)
    ctx.setStrokeColor(black)

    struct Arrow {
        let startX: CGFloat
        let startY: CGFloat
        let endX: CGFloat
        let endY: CGFloat
    }

    let arrows = [
        Arrow(startX: cx - s * 0.12, startY: envTop - s * 0.02,
              endX: cx - s * 0.30, endY: s * 0.82),
        Arrow(startX: cx, startY: envTop,
              endX: cx, endY: s * 0.90),
        Arrow(startX: cx + s * 0.12, startY: envTop - s * 0.02,
              endX: cx + s * 0.30, endY: s * 0.82),
    ]

    for a in arrows {
        // Shaft
        ctx.move(to: CGPoint(x: a.startX, y: a.startY))
        ctx.addLine(to: CGPoint(x: a.endX, y: a.endY))
        ctx.strokePath()

        // Arrowhead
        let dx = a.endX - a.startX
        let dy = a.endY - a.startY
        let angle = atan2(dy, dx)

        let p1 = CGPoint(x: a.endX - headLen * cos(angle - headAngle),
                         y: a.endY - headLen * sin(angle - headAngle))
        let p2 = CGPoint(x: a.endX - headLen * cos(angle + headAngle),
                         y: a.endY - headLen * sin(angle + headAngle))

        ctx.move(to: p1)
        ctx.addLine(to: CGPoint(x: a.endX, y: a.endY))
        ctx.addLine(to: p2)
        ctx.strokePath()
    }

    NSGraphicsContext.current = nil

    let image = NSImage(size: NSSize(width: s, height: s))
    image.addRepresentation(rep)
    return image
}

func savePNG(_ image: NSImage, to path: String) {
    guard let tiff = image.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff),
          let png = bitmap.representation(using: .png, properties: [:]) else { return }
    try! png.write(to: URL(fileURLWithPath: path))
    print("  \(path)")
}

// ── Main ───────────────────────────────────────────────────────

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

let assetDir = projectDir + "/Triage/Resources/Assets.xcassets/MenuBarIcon.imageset"
try? FileManager.default.createDirectory(atPath: assetDir, withIntermediateDirectories: true)

print("Rendering Triage menu bar icon...")
savePNG(renderMenuBarIcon(px: 18), to: assetDir + "/menubar_icon.png")
savePNG(renderMenuBarIcon(px: 36), to: assetDir + "/menubar_icon@2x.png")

// Preview at larger size
let buildDir = projectDir + "/.build"
try? FileManager.default.createDirectory(atPath: buildDir, withIntermediateDirectories: true)
savePNG(renderMenuBarIcon(px: 256), to: buildDir + "/menubar-icon-preview.png")

// Write Contents.json
let contentsJson = """
{
  "images": [
    {
      "idiom": "universal",
      "filename": "menubar_icon.png",
      "scale": "1x"
    },
    {
      "idiom": "universal",
      "filename": "menubar_icon@2x.png",
      "scale": "2x"
    }
  ],
  "info": {
    "version": 1,
    "author": "xcode"
  },
  "properties": {
    "template-rendering-intent": "template"
  }
}
"""
try! contentsJson.write(toFile: assetDir + "/Contents.json", atomically: true, encoding: .utf8)

print("\nDone! Assets in: Triage/Resources/Assets.xcassets/MenuBarIcon.imageset/")
print("Preview: open .build/menubar-icon-preview.png")
