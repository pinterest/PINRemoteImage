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
  s.version          = "3.0.0-beta.3"
  s.summary          = "A thread safe, performant, feature rich image fetcher"
  s.homepage         = "https://github.com/pinterest/PINRemoteImage"
  s.license          = 'Apache 2.0'
  s.author           = { "Garrett Moon" => "garrett@pinterest.com" }
  s.source           = { :git => "https://github.com/pinterest/PINRemoteImage.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/garrettmoon'

  s.ios.deployment_target = "7.0"
  s.tvos.deployment_target = "9.0"
  s.requires_arc = true
  
  # Include optional FLAnimatedImage module
  s.default_subspecs = 'FLAnimatedImage','PINCache'
  
  ### Subspecs
  s.subspec 'Core' do |cs|
    cs.ios.deployment_target = "7.0"
    cs.tvos.deployment_target = "9.0"
    cs.osx.deployment_target = "10.9"
    cs.source_files = 'Pod/Classes/**/*.{h,m}'
    cs.exclude_files = 'Pod/Classes/Image Categories/FLAnimatedImageView+PINRemoteImage.h', 'Pod/Classes/Image Categories/FLAnimatedImageView+PINRemoteImage.m','Pod/Classes/PINCache/**/*.{h,m}'
    cs.public_header_files = 'Pod/Classes/**/*.h'
    cs.frameworks = 'ImageIO', 'Accelerate'
  end
  
  s.subspec 'iOS' do |ios|
    ios.ios.deployment_target = "7.0"
    ios.tvos.deployment_target = "9.0"
    ios.dependency 'PINRemoteImage/Core'
    ios.frameworks = 'UIKit'
  end

  s.subspec 'OSX' do |cs|
    cs.osx.deployment_target = "10.9"
    cs.dependency 'PINRemoteImage/Core'
    cs.frameworks = 'Cocoa', 'CoreServices'
  end

  # The tvOS spec is no longer necessary, iOS should be used instead.
  s.subspec 'tvOS' do |tvos|
    tvos.dependency 'PINRemoteImage/iOS'
  end

  s.subspec "FLAnimatedImage" do |fs|
    fs.platforms = "ios"
    fs.dependency 'PINRemoteImage/Core'
    fs.source_files = 'Pod/Classes/Image Categories/FLAnimatedImageView+PINRemoteImage.h', 'Pod/Classes/Image Categories/FLAnimatedImageView+PINRemoteImage.m'
    fs.dependency 'FLAnimatedImage', '>= 1.0'
  end

  s.subspec 'WebP' do |webp|
    webp.xcconfig = {
        'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) PIN_WEBP=1', 
        'USER_HEADER_SEARCH_PATHS' => '$(inherited) $(SRCROOT)/libwebp/src'
    }
    webp.dependency 'PINRemoteImage/Core'
    webp.dependency 'libwebp'
  end
  
  s.subspec "PINCache" do |pc|
    pc.dependency 'PINRemoteImage/Core'    
	pc.dependency 'PINCache', '>=3.0.1-beta'
	pc.source_files = 'Pod/Classes/PINCache/**/*.{h,m}'
  end
  
end
