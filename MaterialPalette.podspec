Pod::Spec.new do |s|
  s.name         = "MaterialPalette"
  s.version      = "0.0.1"
  s.summary      = "Swift port of the Palette class from the Android Support Libraries. Inspired by Vibrant.js."
  s.description  = <<-DESC
                   Swift port of the Palette class from the Android Support Libraries. Inspired by Vibrant.js.

                   Extracts prominent colors of an image into the following profiles:

 *     Vibrant
 *     Vibrant Dark
 *     Vibrant Light
 *     Muted
 *     Muted Dark
 *     Muted Light
                   DESC
  s.license      = "MIT"
  s.author             = { "Jonathan Zong" => "jonathan@jonathanzong.com" }
  s.social_media_url   = "http://twitter.com/ohnobackspace"
  s.platform     = :ios
  s.ios.deployment_target = '8.0'
  s.homepage = "https://github.com/jonathanzong/SwiftMaterialPalette"
  s.source       = { :git => "https://github.com/jonathanzong/SwiftMaterialPalette.git", :tag => "0.0.1" }
  s.source_files  = "MaterialPalette", "MaterialPalette/**/*.{h,m}"
end
