//
//  DefaultGenerator.swift
//  MaterialPalette
//
//  Created by Jonathan Zong on 10/31/15.
//  Copyright (c) 2015 Jonathan Zong. All rights reserved.
//

import Foundation

class DefaultGenerator {
    
    private let TARGET_DARK_LUMA: CGFloat = 0.26
    private let MAX_DARK_LUMA: CGFloat = 0.45
    
    private let MIN_LIGHT_LUMA: CGFloat = 0.55
    private let TARGET_LIGHT_LUMA: CGFloat = 0.74
    
    private let MIN_NORMAL_LUMA: CGFloat = 0.3
    private let TARGET_NORMAL_LUMA: CGFloat = 0.5
    private let MAX_NORMAL_LUMA: CGFloat = 0.7
    
    private let TARGET_MUTED_SATURATION: CGFloat = 0.3
    private let MAX_MUTED_SATURATION: CGFloat = 0.4
    
    private let TARGET_VIBRANT_SATURATION: CGFloat = 1
    private let MIN_VIBRANT_SATURATION: CGFloat = 0.35
    
    private let WEIGHT_SATURATION: CGFloat = 3
    private let WEIGHT_LUMA: CGFloat = 6
    private let WEIGHT_POPULATION: CGFloat = 1
    
    private var swatches: [Palette.Swatch]?
    
    private var highestPopulation: Int?
    
    var vibrantSwatch: Palette.Swatch?
    var mutedSwatch: Palette.Swatch?
    var darkVibrantSwatch: Palette.Swatch?
    var darkMutedSwatch: Palette.Swatch?
    var lightVibrantSwatch: Palette.Swatch?
    var lightMutedSwatch: Palette.Swatch?
    
    func generate(swatches: [Palette.Swatch]) {
        self.swatches = swatches
        
        self.highestPopulation = findMaxPopulation()
        
        generateVariationColors()
        
        // Now try and generate any missing colors
        generateEmptySwatches()
    }
    
    func generateVariationColors() {
        vibrantSwatch = findColorVariation(TARGET_NORMAL_LUMA, minLuma: MIN_NORMAL_LUMA, maxLuma: MAX_NORMAL_LUMA,
            targetSaturation: TARGET_VIBRANT_SATURATION, minSaturation: MIN_VIBRANT_SATURATION, maxSaturation: 1.0)
        
        lightVibrantSwatch = findColorVariation(TARGET_LIGHT_LUMA, minLuma: MIN_LIGHT_LUMA, maxLuma: 1.0,
            targetSaturation: TARGET_VIBRANT_SATURATION, minSaturation: MIN_VIBRANT_SATURATION, maxSaturation: 1.0)
        
        darkVibrantSwatch = findColorVariation(TARGET_DARK_LUMA, minLuma: 0.0, maxLuma: MAX_DARK_LUMA,
            targetSaturation: TARGET_VIBRANT_SATURATION, minSaturation: MIN_VIBRANT_SATURATION, maxSaturation: 1.0)
        
        mutedSwatch = findColorVariation(TARGET_NORMAL_LUMA, minLuma: MIN_NORMAL_LUMA, maxLuma: MAX_NORMAL_LUMA,
            targetSaturation: TARGET_MUTED_SATURATION, minSaturation: 0.0, maxSaturation: MAX_MUTED_SATURATION)
        
        lightMutedSwatch = findColorVariation(TARGET_LIGHT_LUMA, minLuma: MIN_LIGHT_LUMA, maxLuma: 1.0,
            targetSaturation: TARGET_MUTED_SATURATION, minSaturation: 0.0, maxSaturation: MAX_MUTED_SATURATION)
        
        darkMutedSwatch = findColorVariation(TARGET_DARK_LUMA, minLuma: 0.0, maxLuma: MAX_DARK_LUMA,
            targetSaturation: TARGET_MUTED_SATURATION, minSaturation: 0.0, maxSaturation: MAX_MUTED_SATURATION)
    }
    
    /**
    * Try and generate any missing swatches from the swatches we did find.
    */
    private func generateEmptySwatches() {
        if (vibrantSwatch == nil) {
            // If we do not have a vibrant color...
            if let darkVibrantSwatch = darkVibrantSwatch {
                // ...but we do have a dark vibrant, generate the value by modifying the luma
                if let hsl = darkVibrantSwatch.color.hsb() {
                    vibrantSwatch = Palette.Swatch(color: UIColor(hue: hsl[0], saturation: hsl[1], brightness: TARGET_NORMAL_LUMA, alpha: hsl[3]), population: 0)
                }
            }
        }
            
        if (darkVibrantSwatch == nil) {
            // If we do not have a dark vibrant color...
            if let vibrantSwatch = vibrantSwatch {
                // ...but we do have a vibrant, generate the value by modifying the luma
                if let hsl = vibrantSwatch.color.hsb() {
                    darkVibrantSwatch = Palette.Swatch(color: UIColor(hue: hsl[0], saturation: hsl[1], brightness: TARGET_DARK_LUMA, alpha: hsl[3]), population: 0)
                }
            }
        }
    }
    
    
    /**
    * Find the {@link Palette.Swatch} with the highest population value and return the population.
    */
    private func findMaxPopulation() -> Int {
        var population = 0;
        if let swatches = self.swatches {
            for swatch in swatches {
                population = max(population, swatch.population)
            }
        }
        return population
    }
    
    private func findColorVariation(targetLuma: CGFloat, minLuma: CGFloat, maxLuma: CGFloat,
            targetSaturation: CGFloat, minSaturation: CGFloat, maxSaturation: CGFloat) -> Palette.Swatch? {
        var max: Palette.Swatch? = nil
        var maxValue: CGFloat = 0.0
        
        if let swatches = self.swatches {
            for swatch in swatches {
                if let hsb = swatch.color.hsb() {
                    let sat: CGFloat = hsb[1]
                    let luma: CGFloat = hsb[2]
                    
                    if (sat >= minSaturation && sat <= maxSaturation &&
                        luma >= minLuma && luma <= maxLuma &&
                        !isAlreadySelected(swatch)) {
                            let value = createComparisonValue(sat, targetSaturation: targetSaturation, luma: luma, targetLuma: targetLuma,
                                population: swatch.population, maxPopulation: highestPopulation!)
                            if (max == nil || value > maxValue) {
                                max = swatch
                                maxValue = value
                            }
                    }
                }
                
            }
            
        }
        
        return max
    }
    
    /**
    * @return true if we have already selected {@code swatch}
    */
    private func isAlreadySelected(swatch: Palette.Swatch) -> Bool {
        return vibrantSwatch == swatch || darkVibrantSwatch == swatch ||
        lightVibrantSwatch == swatch || mutedSwatch == swatch ||
        darkMutedSwatch == swatch || lightMutedSwatch == swatch
    }
    
    private func createComparisonValue(saturation: CGFloat, targetSaturation: CGFloat,
        luma: CGFloat, targetLuma: CGFloat,
        population: Int, maxPopulation: Int) -> CGFloat {
            return createComparisonValue(saturation, targetSaturation: targetSaturation, saturationWeight: WEIGHT_SATURATION,
                luma: luma, targetLuma: targetLuma, lumaWeight: WEIGHT_LUMA,
                population: population, maxPopulation: maxPopulation, populationWeight: WEIGHT_POPULATION)
    }
    
    private func createComparisonValue(
        saturation: CGFloat, targetSaturation: CGFloat, saturationWeight: CGFloat,
        luma: CGFloat, targetLuma: CGFloat, lumaWeight: CGFloat,
        population: Int, maxPopulation: Int, populationWeight: CGFloat) -> CGFloat {
            return weightedMean(
                invertDiff(saturation, targetValue: targetSaturation), saturationWeight,
                invertDiff(luma, targetValue: targetLuma), lumaWeight,
                CGFloat(population) / CGFloat(maxPopulation), populationWeight
            )
    }
    
    /**
    * Returns a value in the range 0-1. 1 is returned when {@code value} equals the
    * {@code targetValue} and then decreases as the absolute difference between {@code value} and
    * {@code targetValue} increases.
    *
    * @param value the item's value
    * @param targetValue the value which we desire
    */
    private func invertDiff(value: CGFloat, targetValue: CGFloat) -> CGFloat {
        return 1.0 - abs(value - targetValue)
    }

    private func weightedMean(values: CGFloat...) -> CGFloat {
        var sum: CGFloat = 0
        var sumWeight: CGFloat = 0
        
        for (var i = 0; i < values.count; i += 2) {
            let value = values[i]
            let weight = values[i + 1]
            
            sum += (value * weight)
            sumWeight += weight
        }
        
        return sum / sumWeight
    }

}