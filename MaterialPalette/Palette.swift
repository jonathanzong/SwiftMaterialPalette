//
//  Palette.swift
//  MaterialPalette
//
//  Created by Jonathan Zong on 10/30/15.
//  Copyright (c) 2015 Jonathan Zong. All rights reserved.
//

import Foundation

public class Palette {
    
    private let DEFAULT_RESIZE_BITMAP_MAX_DIMENSION = 192
    private let DEFAULT_CALCULATE_NUMBER_COLORS = 16
    
    public let swatches: [Swatch]
    let generator: DefaultGenerator
    
    public init(uiImage: UIImage) {
        
        // We have a Bitmap so we need to quantization to reduce the number of colors
        
        // First we'll scale down the bitmap so it's largest dimension is as specified
        let scaledBitmap: UIImage = Palette.scaleBitmapDown(uiImage, targetMaxDimension: DEFAULT_RESIZE_BITMAP_MAX_DIMENSION)
        
        let quantizer = ColorCutQuantizer(bitmap: scaledBitmap, maxColors: DEFAULT_CALCULATE_NUMBER_COLORS)
        
        swatches = quantizer.quantizedColors
        
        // If we haven't been provided with a generator, use the default
        // if (mGenerator == null) {
            generator = DefaultGenerator()
        // }
        
        // Now call let the Generator do it's thing
        generator.generate(swatches)
    }
    
    public func getVibrantSwatch() -> Swatch? {
        return generator.vibrantSwatch
    }
    
    public func getMutedSwatch() -> Swatch? {
        return generator.mutedSwatch
    }
    
    public func getLightVibrantSwatch() -> Swatch? {
        return generator.lightVibrantSwatch
    }
    
    public func getLightMutedSwatch() -> Swatch? {
        return generator.lightMutedSwatch
    }
    
    public func getDarkVibrantSwatch() -> Swatch? {
        return generator.darkVibrantSwatch
    }
    
    public func getDarkMutedSwatch() -> Swatch? {
        return generator.darkMutedSwatch
    }
    
    private static func scaleBitmapDown(bitmap: UIImage, targetMaxDimension: Int) -> UIImage {
        let width = Int(bitmap.size.width)
        let height = Int(bitmap.size.height)
        let maxDimension = max(width, height)
        
        if (maxDimension <= targetMaxDimension) {
            return bitmap
        }
        
        let scaleRatio = Float(targetMaxDimension) / Float(maxDimension)
        return scaleDownImage(bitmap, scale: scaleRatio)
    }
    
    // http://nshipster.com/image-resizing/
    private static func scaleDownImage(image: UIImage, scale: Float) -> UIImage {
        let size = CGSizeApplyAffineTransform(image.size, CGAffineTransformMakeScale(CGFloat(scale), CGFloat(scale)))
        let hasAlpha = false
        let scale: CGFloat = 0.0 // Automatically use scale factor of main screen
        
        UIGraphicsBeginImageContextWithOptions(size, !hasAlpha, scale)
        image.drawInRect(CGRect(origin: CGPointZero, size: size))
        
        let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return scaledImage
    }
    
    public struct Swatch: Equatable, Printable {
        
        private static let MIN_CONTRAST_TITLE_TEXT: Float = 3.0
        private static let MIN_CONTRAST_BODY_TEXT: Float = 4.5
        
        public let color: UIColor
        public let population: Int
        
        public let titleTextColor: UIColor?
        public let bodyTextColor: UIColor?
        
        init(color: UIColor, population: Int) {
            self.color = color
            self.population = population
            let rgb = color.rgb()
            let textColors = Swatch.generateTextColors(rgb)
            self.titleTextColor = textColors[0]
            self.bodyTextColor = textColors[1]
        }
        
        public var description: String {
            let hexcolor = String((color.rgb() ?? -1), radix: 16)
            return "Color: \(hexcolor) Population: \(population)"
        }
        
        private static func generateTextColors(maybeRgb: Int?) -> [UIColor?] {
            if let rgb = maybeRgb {
                let maybeLightTitleAlpha = ColorUtils.calculateMinimumAlpha(0xffffffff, background: rgb, minContrastRatio: MIN_CONTRAST_TITLE_TEXT)
                let maybeLightBodyAlpha = ColorUtils.calculateMinimumAlpha(0xffffffff, background: rgb, minContrastRatio: MIN_CONTRAST_BODY_TEXT)
                if let lightTitleAlpha = maybeLightTitleAlpha,
                       lightBodyAlpha = maybeLightBodyAlpha {
                    return [UIColor.whiteColor().colorWithAlphaComponent(CGFloat(lightTitleAlpha)/255.0),
                        UIColor.whiteColor().colorWithAlphaComponent(CGFloat(lightBodyAlpha)/255.0)]
                }
                let maybeDarkTitleAlpha = ColorUtils.calculateMinimumAlpha(0x00000000, background: rgb, minContrastRatio: MIN_CONTRAST_TITLE_TEXT)
                let maybeDarkBodyAlpha = ColorUtils.calculateMinimumAlpha(0x00000000, background: rgb, minContrastRatio: MIN_CONTRAST_BODY_TEXT)
                if let darkTitleAlpha = maybeDarkTitleAlpha,
                       darkBodyAlpha = maybeDarkBodyAlpha {
                    return [UIColor.blackColor().colorWithAlphaComponent(CGFloat(darkTitleAlpha)/255.0),
                        UIColor.blackColor().colorWithAlphaComponent(CGFloat(darkBodyAlpha)/255.0)]
                }
                let ret = []
                // if we reach here, we need to use mismatched light/dark
                if let darkTitleAlpha = maybeDarkTitleAlpha,
                       lightBodyAlpha = maybeLightBodyAlpha {
                    return [UIColor.blackColor().colorWithAlphaComponent(CGFloat(darkTitleAlpha)/255.0),
                        UIColor.whiteColor().colorWithAlphaComponent(CGFloat(lightBodyAlpha)/255.0)]
                }
                else if let lightTitleAlpha = maybeLightTitleAlpha,
                            darkBodyAlpha = maybeDarkBodyAlpha {
                    return [UIColor.whiteColor().colorWithAlphaComponent(CGFloat(lightTitleAlpha)/255.0),
                                UIColor.blackColor().colorWithAlphaComponent(CGFloat(darkBodyAlpha)/255.0)]
                }
            }
            return [nil, nil]
        }
        
    }
}

public func == (lhs: Palette.Swatch, rhs: Palette.Swatch) -> Bool {
    return lhs.color == rhs.color && lhs.population == rhs.population
}

extension UIColor {
    
    func rgb() -> Int? {
        var fRed : CGFloat = 0
        var fGreen : CGFloat = 0
        var fBlue : CGFloat = 0
        var fAlpha: CGFloat = 0
        if self.getRed(&fRed, green: &fGreen, blue: &fBlue, alpha: &fAlpha) {
            let iRed = Int(fRed * 255.0)
            let iGreen = Int(fGreen * 255.0)
            let iBlue = Int(fBlue * 255.0)
            let iAlpha = Int(fAlpha * 255.0)
            
            //  (Bits 24-31 are alpha, 16-23 are red, 8-15 are green, 0-7 are blue).
            let rgb = (iAlpha << 24) + (iRed << 16) + (iGreen << 8) + iBlue
            return rgb
        } else {
            // Could not extract RGBA components:
            return nil
        }
    }
    
    func hsb() -> [CGFloat]? {
        var fHue : CGFloat = 0
        var fSat : CGFloat = 0
        var fBri : CGFloat = 0
        var fAlpha: CGFloat = 0
        if self.getHue(&fHue, saturation: &fSat, brightness: &fBri, alpha: &fAlpha) {
            return [fHue, fSat, fBri, fAlpha]
        } else {
            // Could not extract HSBA components:
            return nil
        }
    }
}