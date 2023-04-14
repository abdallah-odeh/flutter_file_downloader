#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint flutter_file_downloader.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'flutter_file_downloader'
  s.version          = '1.2.0'
  s.summary          = 'A simple flutter plugin that downloads any file type to downloads directory.'
  s.description      = <<-DESC
A simple flutter plugin that downloads any file type to downloads directory.
                       DESC
  s.homepage         = 'https://github.com/abdallah-odeh/flutter_files_downloader'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Odeh-Bros' => 'abdallah@odeh-bros.com' }
  s.source           = { :path => '.' }
  s.source_files = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '9.0'

  # Flutter.framework does not contain a i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
