Pod::Spec.new do |s|
  s.name          = 'PINOperation'
  s.version       = '1.2.3'
  s.homepage      = 'https://github.com/pinterest/PINOperation'
  s.summary       = 'Fast, concurrency-limited task queue for iOS and OS X.'
  s.authors       = { 'Garrett Moon' => 'garrett@pinterest.com' }
  s.source        = { :git => 'https://github.com/pinterest/PINOperation.git', :tag => "#{s.version}" }
  s.license       = { :type => 'Apache 2.0', :file => 'LICENSE.txt' }
  s.requires_arc  = true
  s.frameworks    = 'Foundation'
  s.cocoapods_version = '>= 1.13.0'
  s.ios.deployment_target = '12.0'
  s.osx.deployment_target = '10.13'
  s.tvos.deployment_target = '12.0'
  s.visionos.deployment_target = '1.0'
  s.watchos.deployment_target = '4.0'
  pch_PIN = <<-EOS
#ifndef TARGET_OS_WATCH
  #define TARGET_OS_WATCH 0
#endif
EOS
  s.prefix_header_contents = pch_PIN
  s.source_files = 'Source/*.{h,m}'
  s.resource_bundles = { 'PINOperation' => ['Source/PrivacyInfo.xcprivacy'] }
end
