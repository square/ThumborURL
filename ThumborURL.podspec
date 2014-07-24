Pod::Spec.new do |s|
  s.name         = "ThumborURL"
  s.version      = "0.0.1"
  s.summary      = "Thumbor URLs generator"

  s.description  = <<-DESC
                   A library to generate encrypted URLs for Thumbor in your iOS app.
                   DESC

  s.homepage     = "https://github.com/square/ThumborURL"
  s.license      = { :type => "Apache License, Version 2.0", :file => "LICENSE.md" }
  s.author       = { "Square" => "http://square.github.io" }
  s.platform     = :ios
  s.source       = { :git => "https://github.com/square/ThumborURL.git", :commit => "c3a0bbd9fe2aa157a435e531dc1c8f845d4332df"}
  s.source_files = 'thumborurl/ThumborURL.{h,m}'
  s.requires_arc = true
end