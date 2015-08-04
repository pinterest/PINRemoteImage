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
  s.version          = "1.1.2"
  s.summary          = "A thread safe, performant, feature rich image fetcher"
  s.homepage         = "https://github.com/pinterest/PINRemoteImage"
  s.license          = 'Apache 2.0'
  s.author           = { "Garrett Moon" => "garrett@pinterest.com" }
  s.source           = { :git => "https://github.com/pinterest/PINRemoteImage.git", :tag => "1.1.2" }
  s.social_media_url = 'https://twitter.com/garrettmoon'

  s.platform     = :ios, '6.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes/**/*.{h,m}'

  s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'UIKit', 'ImageIO', 'CoreImage'
  s.dependency 'FLAnimatedImage', '>= 1.0'
  s.dependency 'PINCache', '>=2.0'

end
