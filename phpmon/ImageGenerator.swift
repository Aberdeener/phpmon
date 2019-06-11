//
//  ImageGenerator.swift
//  phpmon
//
//  Created by Nico Verbruggen on 11/06/2019.
//  Copyright © 2019 Nico Verbruggen. All rights reserved.
//

import Cocoa

class ImageGenerator {
    
    public static func generateImageForStatusBar(
        text: String
    ) -> NSImage {
        // Create an image with fixed dimensions
        let width: CGFloat = 30.0
        let height: CGFloat = 20.0
        let image = NSImage(size: NSMakeSize(width, height))
        
        // Use the system font
        let font = NSFont.systemFont(ofSize: 14)
        
        let imageRect = CGRect(x: 0, y: 0, width: image.size.width, height: image.size.height)
        let textRect = CGRect(x: 5, y: -1, width: image.size.width, height: image.size.height)
        
        let textStyle = NSMutableParagraphStyle.default.mutableCopy() as! NSMutableParagraphStyle
        let textFontAttributes = [
            NSAttributedString.Key.font: font,
            NSAttributedString.Key.foregroundColor: NSColor.black,
            NSAttributedString.Key.paragraphStyle: textStyle
        ]
        
        let targetImage: NSImage = NSImage(size: image.size)
        
        let rep: NSBitmapImageRep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: Int(image.size.width),
            pixelsHigh: Int(image.size.height),
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: NSColorSpaceName.calibratedRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        )!
        
        targetImage.addRepresentation(rep)
        targetImage.lockFocus()
        
        image.draw(in: imageRect)
        text.draw(in: textRect, withAttributes: textFontAttributes)
        
        targetImage.unlockFocus()
        return targetImage
    }
    
}
