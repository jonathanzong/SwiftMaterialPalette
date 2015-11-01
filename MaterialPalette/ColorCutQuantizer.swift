//
//  ColorCutQuantizer.swift
//  MaterialPalette
//
//  Created by Jonathan Zong on 10/30/15.
//  Copyright (c) 2015 Jonathan Zong. All rights reserved.
//

import Foundation

class ColorCutQuantizer {
    enum Dimension {
        case COMPONENT_RED
        case COMPONENT_GREEN
        case COMPONENT_BLUE
    }
    
    private static let QUANTIZE_WORD_WIDTH = 5
    private static let QUANTIZE_WORD_MASK = (1 << QUANTIZE_WORD_WIDTH) - 1
    
    var colors: [Int] = []
    var histogram = [Int: Int]()
    var quantizedColors: [Palette.Swatch] = []
    
//    let mFilters: [Palette.Filter]
    
    let tempHsl: [Float] = [0.0, 0.0, 0.0]
    
    /**
    * Constructor.
    *
    * @param pixels histogram representing an image's pixel data
    * @param maxColors The maximum number of colors that should be in the result palette.
    * @param filters Set of filters to use in the quantization stage
    */
    init(bitmap: UIImage, maxColors: Int) {
        bitmap.applyOnPixels({
            (point:CGPoint, redColor:UInt8, greenColor:UInt8, blueColor:UInt8, alphaValue:UInt8) -> (UInt8, UInt8, UInt8, UInt8) in
            let quantizedColor = ColorCutQuantizer.quantizeFromRgb888(redColor, green: greenColor, blue: blueColor)
            // And update the histogram
            self.histogram[quantizedColor] = (self.histogram[quantizedColor] ?? 0) + 1
            return (UInt8(ColorUtils.getRed(quantizedColor)), UInt8(ColorUtils.getGreen(quantizedColor)), UInt8(ColorUtils.getBlue(quantizedColor)), UInt8(ColorUtils.getAlphaComponent(quantizedColor)))
        })
        
        // Now let's count the number of distinct colors
        let distinctColorCount = histogram.count
        
        self.colors = Array(histogram.keys)
        
        if (distinctColorCount <= maxColors) {
            // The image has fewer colors than the maximum requested, so just return the colors
            for (color, count) in histogram {
                self.quantizedColors.append(Palette.Swatch(color: ColorCutQuantizer.approximateToRgb888(color), population: count));
            }
        } else {
            // We need use quantization to reduce the number of colors
            self.quantizedColors.extend(quantizePixels(maxColors))
        }
    }
    
    private func quantizePixels(maxColors: Int) -> [Palette.Swatch] {
        // Create the priority queue which is sorted by volume descending. This means we always
        // split the largest box in the queue
        var pq = PriorityQueue<Vbox>()
        
        // To start, offer a box which contains all of the colors
        pq.push(Vbox(lowerIndex: 0, upperIndex: colors.count - 1, colors: colors, histogram: histogram))
        
        // Now go through the boxes, splitting them until we have reached maxColors or there are no
        // more boxes to split
        pq = splitBoxes(pq, maxSize: maxColors)
        
        // Finally, return the average colors of the color boxes
        return generateAverageColors(pq)
    }
    
    /**
    * Iterate through the {@link java.util.Queue}, popping
    * {@link ColorCutQuantizer.Vbox} objects from the queue
    * and splitting them. Once split, the new box and the remaining box are offered back to the
    * queue.
    *
    * @param queue {@link java.util.PriorityQueue} to poll for boxes
    * @param maxSize Maximum amount of boxes to split
    */
    private func splitBoxes(var queue: PriorityQueue<Vbox>, maxSize: Int) -> PriorityQueue<Vbox> {
        while (queue.count < maxSize) {
            if let vbox = queue.pop() {
                if (vbox.canSplit()) {
                    // First split the box, and offer the result
                    queue.push(vbox.splitBox())
                    
                    // Then offer the box back
                    queue.push(vbox)
                } else {
                    return queue
                }
            } else {
                // If we get here then there are no more boxes to split, so return
                return queue
            }
        }
        return queue
    }
    
    private func generateAverageColors(vboxes: PriorityQueue<Vbox>) -> [Palette.Swatch] {
        var colors: [Palette.Swatch] = []
        for vbox in vboxes {
            let swatch = vbox.getAverageColor()
            colors.append(swatch)
        }
        return colors
    }
    
    /**
    * Represents a tightly fitting box around a color space.
    */
    class Vbox : Comparable {
        private var colors: [Int]
        private let histogram: [Int: Int]
        // lower and upper index are inclusive
        private var lowerIndex: Int
        private var upperIndex: Int
        // Population of colors within this box
        private var population: Int
        
        private var minRed: Int, maxRed: Int
        private var minGreen: Int, maxGreen: Int
        private var minBlue: Int, maxBlue: Int
        
        init(lowerIndex: Int, upperIndex: Int, colors: [Int], histogram: [Int: Int]) {
            self.lowerIndex = lowerIndex
            self.upperIndex = upperIndex
            self.colors = colors
            self.histogram = histogram

            population = 0
            minRed = Int.max
            minGreen = Int.max
            minBlue = Int.max
            maxRed = Int.min
            maxGreen = Int.min
            maxBlue = Int.min
            fitBox()
        }
        
        func getVolume() -> Int {
            return (maxRed - minRed + 1) * (maxGreen - minGreen + 1) * (maxBlue - minBlue + 1)
        }
        
        func canSplit() -> Bool {
            return getColorCount() > 1
        }
        
        func getColorCount() -> Int {
            return 1 + upperIndex - lowerIndex
        }
        
        /**
        * Recomputes the boundaries of this box to tightly fit the colors within the box.
        */
        func fitBox() {
            // Reset the min and max to opposite values
            var minRed = Int.max
            var minGreen = Int.max
            var minBlue = Int.max
            var maxRed = Int.min
            var maxGreen = Int.min
            var maxBlue = Int.min
            var count = 0
            
            for (var i = lowerIndex; i <= upperIndex; i++) {
                let color = self.colors[i]
                count += self.histogram[color]!
                
                let r = ColorCutQuantizer.quantizedRed(color)
                let g = ColorCutQuantizer.quantizedGreen(color)
                let b = ColorCutQuantizer.quantizedBlue(color)
                if (r > maxRed) {
                    maxRed = r
                }
                if (r < minRed) {
                    minRed = r
                }
                if (g > maxGreen) {
                    maxGreen = g
                }
                if (g < minGreen) {
                    minGreen = g
                }
                if (b > maxBlue) {
                    maxBlue = b
                }
                if (b < minBlue) {
                    minBlue = b
                }
            }
            
            self.minRed = minRed
            self.maxRed = maxRed
            self.minGreen = minGreen
            self.maxGreen = maxGreen
            self.minBlue = minBlue
            self.maxBlue = maxBlue
            self.population = count
        }
        
        /**
        * Split this color box at the mid-point along it's longest dimension
        *
        * @return the new ColorBox
        */
        func splitBox() -> Vbox {
            assert(canSplit())
        
            // find median along the longest dimension
            let splitPoint = findSplitPoint()
            let newBox = Vbox(lowerIndex: splitPoint + 1, upperIndex: self.upperIndex, colors: colors, histogram: histogram)
            
            // Now change this box's upperIndex and recompute the color boundaries
            self.upperIndex = splitPoint
            fitBox()
            
            return newBox
        }
        
        /**
        * @return the dimension which this box is largest in
        */
        func getLongestColorDimension() -> Dimension {
            let redLength = maxRed - minRed
            let greenLength = maxGreen - minGreen
            let blueLength = maxBlue - minBlue
            
            if (redLength >= greenLength && redLength >= blueLength) {
                return Dimension.COMPONENT_RED
            } else if (greenLength >= redLength && greenLength >= blueLength) {
                return Dimension.COMPONENT_GREEN
            } else {
                return Dimension.COMPONENT_BLUE
            }
        }
        
        /**
        * Finds the point within this box's lowerIndex and upperIndex index of where to split.
        *
        * This is calculated by finding the longest color dimension, and then sorting the
        * sub-array based on that dimension value in each color. The colors are then iterated over
        * until a color is found with at least the midpoint of the whole box's dimension midpoint.
        *
        * @return the index of the colors array to split from
        */
        func findSplitPoint() -> Int {
            let longestDimension = getLongestColorDimension()
            
            // We need to sort the colors in this box based on the longest color dimension.
            // As we can't use a Comparator to define the sort logic, we modify each color so that
            // its most significant is the desired dimension
            ColorCutQuantizer.modifySignificantOctet(colors, dimension: longestDimension, lower: lowerIndex, upper: upperIndex)
            
            colors = colors[0..<lowerIndex] +
                sorted(colors[lowerIndex...upperIndex], { (left: Int, right: Int) -> Bool in left < right }) +
                colors[(upperIndex+1)..<colors.count]
            
            // Now revert all of the colors so that they are packed as RGB again
            ColorCutQuantizer.modifySignificantOctet(colors, dimension: longestDimension, lower: lowerIndex, upper: upperIndex)
            
            let midPoint: Int = population / 2
            for (var i = lowerIndex, count = 0; i <= upperIndex; i++)  {
                count += histogram[colors[i]]!
                if (count >= midPoint) {
                    return i
                }
            }
        
            return lowerIndex;
        }
        
        /**
        * @return the average color of this box.
        */
        func getAverageColor() -> Palette.Swatch {
            var redSum = 0;
            var greenSum = 0;
            var blueSum = 0;
            var totalPopulation = 0;
            
            for (var i = lowerIndex; i <= upperIndex; i++) {
                let color = colors[i]
                let colorPopulation = histogram[color]!
                
                totalPopulation += colorPopulation
                redSum += colorPopulation * ColorCutQuantizer.quantizedRed(color)
                greenSum += colorPopulation * ColorCutQuantizer.quantizedGreen(color)
                blueSum += colorPopulation * ColorCutQuantizer.quantizedBlue(color)
            }
            
            let redMean: Int = Int(round(Float(redSum) / Float(totalPopulation)))
            let greenMean: Int = Int(round(Float(greenSum) / Float(totalPopulation)))
            let blueMean: Int = Int(round(Float(blueSum) / Float(totalPopulation)))
            
            return Palette.Swatch(color: ColorCutQuantizer.approximateToRgb888(redMean, g: greenMean, b: blueMean), population: totalPopulation)
        }
    }

    
    /**
    * Quantized a RGB888 value to have a word width of {@value #QUANTIZE_WORD_WIDTH}.
    */
    private static func quantizeFromRgb888(red: UInt8, green: UInt8, blue: UInt8) -> Int {
        let r = modifyWordWidth(Int(red), currentWidth: 8, targetWidth: QUANTIZE_WORD_WIDTH)
        let g = modifyWordWidth(Int(green), currentWidth: 8, targetWidth: QUANTIZE_WORD_WIDTH)
        let b = modifyWordWidth(Int(blue), currentWidth: 8, targetWidth: QUANTIZE_WORD_WIDTH)
        return r << (QUANTIZE_WORD_WIDTH + QUANTIZE_WORD_WIDTH) | g << QUANTIZE_WORD_WIDTH | b
    }
    
    /**
    * Quantized RGB888 values to have a word width of {@value #QUANTIZE_WORD_WIDTH}.
    */
    private static func approximateToRgb888(r: Int, g: Int, b: Int) -> UIColor {
        return UIColor(red: CGFloat(modifyWordWidth(r, currentWidth: QUANTIZE_WORD_WIDTH, targetWidth: 8))/255.0,
            green: CGFloat(modifyWordWidth(g, currentWidth: QUANTIZE_WORD_WIDTH, targetWidth: 8))/255.0, blue: CGFloat(modifyWordWidth(b, currentWidth: QUANTIZE_WORD_WIDTH, targetWidth: 8))/255.0, alpha: 1.0)
    }
    
    private static func approximateToRgb888(color: Int) -> UIColor {
        return approximateToRgb888(quantizedRed(color), g: quantizedGreen(color), b: quantizedBlue(color))
    }
    
    /**
    * @return red component of the quantized color
    */
    private static func quantizedRed(color: Int) -> Int {
        return (color >> (QUANTIZE_WORD_WIDTH + QUANTIZE_WORD_WIDTH)) & QUANTIZE_WORD_MASK
    }
    
    /**
    * @return green component of a quantized color
    */
    private static func quantizedGreen(color: Int) -> Int {
        return (color >> QUANTIZE_WORD_WIDTH) & QUANTIZE_WORD_MASK
    }
    
    /**
    * @return blue component of a quantized color
    */
    private static func quantizedBlue(color: Int) -> Int {
        return color & QUANTIZE_WORD_MASK
    }
    
    /**
    * Modify the significant octet in a packed color int. Allows sorting based on the value of a
    * single color component. This relies on all components being the same word size.
    *
    * @see Vbox#findSplitPoint()
    */
    private static func modifySignificantOctet(var a: [Int], dimension: Dimension, lower: Int, upper: Int) {
        switch (dimension) {
            case Dimension.COMPONENT_RED:
            // Already in RGB, no need to do anything
            break;
            case Dimension.COMPONENT_GREEN:
            // We need to do a RGB to GRB swap, or vice-versa
            for (var i = lower; i <= upper; i++) {
                let color = a[i]
                a[i] = quantizedGreen(color) << (QUANTIZE_WORD_WIDTH + QUANTIZE_WORD_WIDTH)
                | quantizedRed(color) << QUANTIZE_WORD_WIDTH
                    | quantizedBlue(color)
            }
            break;
            case Dimension.COMPONENT_BLUE:
            // We need to do a RGB to BGR swap, or vice-versa
            for (var i = lower; i <= upper; i++) {
                let color = a[i]
                a[i] = quantizedBlue(color) << (QUANTIZE_WORD_WIDTH + QUANTIZE_WORD_WIDTH)
                | quantizedGreen(color) << QUANTIZE_WORD_WIDTH
                | quantizedRed(color);
            }
            break;
        }
    }
    
    private static func modifyWordWidth(value: Int, currentWidth: Int, targetWidth: Int) -> Int {
        let newValue = targetWidth > currentWidth ?
            // If we're approximating up in word width, we'll shift up
            value << (targetWidth - currentWidth) :
            // Else, we will just shift and keep the MSB
            value >> (currentWidth - targetWidth)
        return newValue & ((1 << targetWidth) - 1)
    }
}

/**
* Comparator which sorts {@link Vbox} instances based on their volume, in descending order (largest first)
*/
func < (lhs: ColorCutQuantizer.Vbox, rhs: ColorCutQuantizer.Vbox) -> Bool {
    return rhs.getVolume() - lhs.getVolume() > 0
}

func == (lhs: ColorCutQuantizer.Vbox, rhs: ColorCutQuantizer.Vbox) -> Bool {
    return rhs.getVolume() - lhs.getVolume() == 0
}

extension CGImage {
    func getPixelColor(pos: CGPoint) -> UIColor {
        
        var pixelData = CGDataProviderCopyData(CGImageGetDataProvider(self))
        var data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
        
        var pixelInfo: Int = ((CGImageGetWidth(self) * Int(pos.y)) + Int(pos.x)) * 4
        
        var r = CGFloat(data[pixelInfo]) / CGFloat(255.0)
        var g = CGFloat(data[pixelInfo+1]) / CGFloat(255.0)
        var b = CGFloat(data[pixelInfo+2]) / CGFloat(255.0)
        var a = CGFloat(data[pixelInfo+3]) / CGFloat(255.0)
        
        return UIColor(red: r, green: g, blue: b, alpha: a)
    }
}