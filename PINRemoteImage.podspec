#
# Be sure to run `pod lib lint PINRemoteImage.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "PINRemoteImage"
  s.version          = "2.1.4"
  s.summary          = "A thread safe, performant, feature rich image fetcher"
  s.homepage         = "https://github.com/pinterest/PINRemoteImage"
  s.license          = 'Apache 2.0'
  s.author           = { "Garrett Moon" => "garrett@pinterest.com" }
  s.source           = { :git => "https://github.com/pinterest/PINRemoteImage.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/garrettmoon'

  s.ios.deployment_target = "6.0"
  s.osx.deployment_target = "10.8"
  s.tvos.deployment_target = "9.0"
  s.requires_arc = true
  
  # Include optional FLAnimatedImage module
  s.default_subspecs = 'FLAnimatedImage'
  
  ### Subspecs
  s.subspec 'Core' do |cs|
    cs.source_files = 'Pod/Classes/**/*.{h,m}'
    cs.exclude_files = 'Pod/Classes/Image Categories/FLAnimatedImageView+PINRemoteImage.h', 'Pod/Classes/Image Categories/FLAnimatedImageView+PINRemoteImage.m'
    cs.public_header_files = 'Pod/Classes/**/*.h'
    cs.frameworks = 'ImageIO', 'Accelerate'
    cs.dependency 'PINCache', '>=2.1'
  end
  
  s.subspec 'iOS' do |ios|
    ios.platforms = "ios"
    ios.dependency 'PINRemoteImage/Core'
    ios.frameworks = 'UIKit'
  end

  s.subspec 'OSX' do |cs|
    cs.platforms = "osx"
    cs.dependency 'PINRemoteImage/Core'
    cs.frameworks = 'Cocoa'
  end

  s.subspec 'tvOS' do |tvos|
    tvos.platforms = "tvos"
    tvos.dependency 'PINRemoteImage/Core'
    tvos.frameworks = 'UIKit'
  end

  s.subspec "FLAnimatedImage" do |fs|
    fs.platforms = "ios"
    fs.dependency 'PINRemoteImage/Core'
    fs.source_files = 'Pod/Classes/Image Categories/FLAnimatedImageView+PINRemoteImage.h', 'Pod/Classes/Image Categories/FLAnimatedImageView+PINRemoteImage.m'
    fs.dependency 'FLAnimatedImage', '>= 1.0'
  end

  s.subspec 'WebP' do |webp|
    webp.xcconfig = { 'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) PIN_WEBP=1' }
    webp.dependency 'PINRemoteImage/Core'
    webp.dependency 'libwebp'
  end
end
