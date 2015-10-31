//
//  ColorUtils.swift
//  MaterialPalette
//
//  Created by Jonathan Zong on 10/30/15.
//  Copyright (c) 2015 Jonathan Zong. All rights reserved.
//

import Foundation

class ColorUtils {
    
    private static let MIN_ALPHA_SEARCH_MAX_ITERATIONS = 10;
    private static let MIN_ALPHA_SEARCH_PRECISION = 10;
    
    /**
    * Composite two potentially translucent colors over each other and returns the result.
    */
    static func compositeColors(foreground: Int, background: Int) -> Int {
        let bgAlpha = getAlphaComponent(background)
        let fgAlpha = getAlphaComponent(foreground)
        let a = compositeAlpha(fgAlpha, backgroundAlpha: bgAlpha)
        
        let r = compositeComponent(getRed(foreground), fgA: fgAlpha, bgC: getRed(background), bgA: bgAlpha, a: a)
        let g = compositeComponent(getGreen(foreground), fgA: fgAlpha, bgC: getGreen(background), bgA: bgAlpha, a: a)
        let b = compositeComponent(getBlue(foreground), fgA: fgAlpha, bgC: getBlue(background), bgA: bgAlpha, a: a)
        
        return getARGB(a, r: r, g: g, b: b)
    }
    
    private static func compositeAlpha(foregroundAlpha: Int, backgroundAlpha: Int) -> Int {
        return 0xFF - (((0xFF - backgroundAlpha) * (0xFF - foregroundAlpha)) / 0xFF);
    }
    
    private static func compositeComponent(fgC: Int, fgA: Int, bgC: Int, bgA: Int, a: Int) -> Int{
        if (a == 0) {
            return 0
        }
        return ((0xFF * fgC * fgA) + (bgC * bgA * (0xFF - fgA))) / (a * 0xFF)
    }
    
    /**
    * Returns the luminance of a color.
    *
    * Formula defined here: http://www.w3.org/TR/2008/REC-WCAG20-20081211/#relativeluminancedef
    */
    static func calculateLuminance(color: Int) -> Double {
        var red = Double(getRed(color)) / 255.0
        red = red < 0.03928 ? red / 12.92 : pow((red + 0.055) / 1.055, 2.4)
        
        var green = Double(getGreen(color)) / 255.0
        green = green < 0.03928 ? green / 12.92 : pow((green + 0.055) / 1.055, 2.4)
        
        var blue = Double(getBlue(color)) / 255.0
        blue = blue < 0.03928 ? blue / 12.92 : pow((blue + 0.055) / 1.055, 2.4)
        
        return (0.2126 * red) + (0.7152 * green) + (0.0722 * blue)
    }

    /**
    * Returns the contrast ratio between {@code foreground} and {@code background}.
    * {@code background} must be opaque.
    * <p>
    * Formula defined
    * <a href="http://www.w3.org/TR/2008/REC-WCAG20-20081211/#contrast-ratiodef">here</a>.
    */
    static func calculateContrast(var foreground: Int, background: Int) -> Double {
        let foregroundAlpha = getAlphaComponent(foreground)
        if (foregroundAlpha < 255) {
            // If the foreground is translucent, composite the foreground over the background
            foreground = compositeColors(foreground, background: background)
        }
        
        let luminance1 = calculateLuminance(foreground) + 0.05
        let luminance2 = calculateLuminance(background) + 0.05
        
        // Now return the lighter luminance divided by the darker luminance
        return max(luminance1, luminance2) / min(luminance1, luminance2)
    }
    
    /**
    * Calculates the minimum alpha value which can be applied to {@code foreground} so that would
    * have a contrast value of at least {@code minContrastRatio} when compared to
    * {@code background}.
    *
    * @param foreground       the foreground color.
    * @param background       the background color. Should be opaque.
    * @param minContrastRatio the minimum contrast ratio.
    * @return the alpha value in the range 0-255, or nil if no value could be calculated.
    */
    static func calculateMinimumAlpha(foreground: Int, background: Int, minContrastRatio: Float) -> Int? {
        if (getAlphaComponent(background) != 255) {
            // background can not be translucent
            return nil
        }

        // First check that a fully opaque foreground has sufficient contrast
        var testForeground: Int = setAlphaComponent(foreground, alpha: 255)
        var testRatio: Double = calculateContrast(testForeground, background: background)
        if (testRatio < Double(minContrastRatio)) {
            // Fully opaque foreground does not have sufficient contrast, return nil
            return nil
        }
        
        // Binary search to find a value with the minimum value which provides sufficient contrast
        var numIterations: Int = 0;
        var minAlpha: Int = 0;
        var maxAlpha: Int = 255;
        
        while (numIterations <= MIN_ALPHA_SEARCH_MAX_ITERATIONS &&
            (maxAlpha - minAlpha) > MIN_ALPHA_SEARCH_PRECISION) {
                let testAlpha = (minAlpha + maxAlpha) / 2
                
                testForeground = setAlphaComponent(foreground, alpha: testAlpha);
                testRatio = calculateContrast(testForeground, background: background);
                
                if (testRatio < Double(minContrastRatio)) {
                    minAlpha = testAlpha
                } else {
                    maxAlpha = testAlpha
                }
                
                numIterations++
        }
        
        // Conservatively return the max of the range of possible alphas, which is known to pass.
        return maxAlpha;
    }
    
    static func setAlphaComponent(color: Int, alpha: Int) -> Int {
        if (alpha < 0 || alpha > 255) {
            return color
        }
        return (color & 0x00ffffff) | (alpha << 24)
    }
    
    static func getAlphaComponent(color: Int) -> Int {
        return (color >> 24) & 0xff
    }
    
    static func getRed(color: Int) -> Int {
        return (color >> 16) & 0xff
    }
    
    static func getGreen(color: Int) -> Int {
        return (color >> 8) & 0xff
    }
    
    static func getBlue(color: Int) -> Int {
        return color & 0xff
    }

    static func getARGB(a: Int, r: Int, g: Int, b: Int) -> Int {
        return a << 24 + r << 16 + g << 8 + b
    }
}