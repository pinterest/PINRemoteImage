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
  s.version          = "3.0.0"
  s.summary          = "A thread safe, performant, feature rich image fetcher"
  s.homepage         = "https://github.com/pinterest/PINRemoteImage"
  s.license          = 'Apache 2.0'
  s.author           = { "Garrett Moon" => "garrett@pinterest.com" }
  s.source           = { :git => "https://github.com/pinterest/PINRemoteImage.git", :tag => s.version.to_s }
  # s.social_media_url = 'https://twitter.com/garrettmoon'

  ios_deployment = "8.0"
  tvos_deployment = "9.0"
  osx_deployment = "10.11"
  s.ios.deployment_target = ios_deployment
  s.tvos.deployment_target = tvos_deployment
  s.requires_arc = true
  
  s.default_subspecs = 'PINCache'
  
  ### Subspecs
  s.subspec 'Core' do |cs|
    cs.dependency 'PINOperation'
    cs.ios.deployment_target = ios_deployment
    cs.tvos.deployment_target = tvos_deployment
    cs.osx.deployment_target = osx_deployment
    cs.source_files = 'Source/Classes/**/*.{h,m}'
    cs.public_header_files = 'Source/Classes/**/*.h'
    cs.exclude_files = 'Source/Classes/PINCache/*.{h,m}'
    cs.frameworks = 'ImageIO', 'Accelerate'
  end
  
  s.subspec 'iOS' do |ios|
    ios.ios.deployment_target = ios_deployment
    ios.tvos.deployment_target = tvos_deployment
    ios.dependency 'PINRemoteImage/Core'
    ios.frameworks = 'UIKit'
  end

  s.subspec 'OSX' do |cs|
    cs.osx.deployment_target = osx_deployment
    cs.dependency 'PINRemoteImage/Core'
    cs.frameworks = 'Cocoa', 'CoreServices'
  end

  # The tvOS spec is no longer necessary, iOS should be used instead.
  s.subspec 'tvOS' do |tvos|
    tvos.dependency 'PINRemoteImage/iOS'
  end

  s.subspec 'WebP' do |webp|
    webp.ios.deployment_target = ios_deployment
    webp.tvos.deployment_target = tvos_deployment
    webp.osx.deployment_target = osx_deployment
    webp.xcconfig = {
        'GCC_PREPROCESSOR_DEFINITIONS' => '$(inherited) PIN_WEBP=1', 
        'USER_HEADER_SEARCH_PATHS' => '$(inherited) $(SRCROOT)/libwebp/src'
    }
    webp.dependency 'PINRemoteImage/Core'
    webp.dependency 'libwebp'
  end
  
  s.subspec "PINCache" do |pc|
    pc.dependency 'PINRemoteImage/Core'
    pc.dependency 'PINCache', '=3.0.1-beta.8'
    pc.ios.deployment_target = ios_deployment
    pc.tvos.deployment_target = tvos_deployment
    pc.osx.deployment_target = osx_deployment
    pc.source_files = 'Source/Classes/PINCache/*.{h,m}'
  end
  
end
