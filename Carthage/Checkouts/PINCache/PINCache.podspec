Pod::Spec.new do |s|
  s.name          = 'PINCache'
  s.version       = '3.0.1-beta.5'
  s.homepage      = 'https://github.com/pinterest/PINCache'
  s.summary       = 'Fast, thread safe, parallel object cache for iOS and OS X.'
  s.authors       = { 'Garrett Moon' => 'garrett@pinterest.com', 'Justin Ouellette' => 'jstn@tumblr.com' }
  s.source        = { :git => 'https://github.com/pinterest/PINCache.git', :tag => "#{s.version}" }
  s.license       = { :type => 'Apache 2.0', :file => 'LICENSE.txt' }
  s.requires_arc  = true
  s.frameworks    = 'Foundation'
  s.ios.weak_frameworks   = 'UIKit'
  s.osx.weak_frameworks   = 'AppKit'
  s.ios.deployment_target = '5.0'
  s.osx.deployment_target = '10.7'
  s.tvos.deployment_target = '9.0'
  s.watchos.deployment_target = '2.0'
  pch_PIN = <<-EOS
#ifndef TARGET_OS_WATCH
  #define TARGET_OS_WATCH 0
#endif
EOS
  s.prefix_header_contents = pch_PIN
  s.subspec 'Core' do |sp|
      sp.source_files  = 'Source/*.{h,m}'
      sp.dependency 'PINOperation', '=1.0.3'
  end
  s.subspec 'Arc-exception-safe' do |sp|
      sp.dependency 'PINCache/Core'
      sp.source_files = 'Source/PINDiskCache.m'
      sp.compiler_flags = '-fobjc-arc-exceptions'
  end
end
