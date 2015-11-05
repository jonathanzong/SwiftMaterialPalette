# SwiftMaterialPalette
Generates a palette by extracting color swatches from an image.

SwiftMaterialPalette is a Swift port of Android's [Palette](https://developer.android.com/reference/android/support/v7/graphics/Palette.html) class.

Inspired by [Vibrant.js](http://jariz.github.io/vibrant.js/).

##Demo 
<img src="https://cloud.githubusercontent.com/assets/4650077/10956276/594bae6a-8328-11e5-9622-e8d6363cc181.png" width="250" height="220"/>
<img src="https://cloud.githubusercontent.com/assets/4650077/10956277/594c7fc0-8328-11e5-8152-348e19c6f52d.png" width="250" height="220"/>

##Installation

[CocoaPods](http://cocoapods.org) is a dependency manager for Cocoa projects. You can install it by running:

```bash
$ gem install cocoapods
```

Specify MaterialPalette as a dependency in your `Podfile`:

```ruby
platform :ios, "8.0"
use_frameworks!

pod 'MaterialPalette', '0.0.1'
```

Then, run the following command:

```bash
$ pod install
```

##Usage

```swift
let palette = Palette(uiImage: image)
            
let maybeSwatches = [
    palette.getVibrantSwatch(),
    palette.getMutedSwatch(),
    palette.getLightVibrantSwatch(),
    palette.getLightMutedSwatch(),
    palette.getDarkVibrantSwatch(),
    palette.getDarkMutedSwatch()]

var swatches: [Palette.Swatch] = []

for swatch in maybeSwatches {
    if let swatch = swatch {
        swatches.append(swatch)
    }
}
```

##License
MIT
