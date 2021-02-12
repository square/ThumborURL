Pod::Spec.new do |s|
  s.name         = 'ThumborURL'
  s.version      = '0.0.6'
  s.summary      = 'A library to generate encrypted URLs for Thumbor in your iOS app.'
  s.homepage     = 'https://github.com/square/ThumborURL'
  s.license      = 'Apache License, Version 2.0'
  s.author       = 'Square'
  s.source       = { :git => 'https://github.com/square/ThumborURL.git', :tag => 'v0.0.5' }

  s.source_files = 'thumborurl/*.{h,m}'

  s.frameworks   = 'Foundation', 'CoreGraphics'

  s.ios.deployment_target = '9.0'
end
