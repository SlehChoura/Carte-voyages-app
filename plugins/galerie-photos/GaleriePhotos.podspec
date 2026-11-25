require 'json'
package = JSON.parse(File.read(File.join(__dir__, 'package.json')))
Pod::Spec.new do |s|
  s.name = 'GaleriePhotos'
  s.version = package['version']
  s.summary = package['description']
  s.license = package['license']
  s.homepage = 'https://capacitorjs.com'
  s.author = package['author']
  s.source = { :git => 'local', :tag => package['version'] }
  s.source_files = 'ios/Sources/**/*.swift'
  s.ios.deployment_target = '15.0'
  s.dependency 'Capacitor'
  s.swift_version = '5.1'
end
