#
#  Be sure to run `pod spec lint BluetoothWrapper.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  spec.name         = "BluetoothWrapper"
  spec.version      = "0.2.0"
  spec.summary      = "Wrapper for CoreBluetooth framework."

  spec.description  = <<-DESC
This CocoaPods library helps you easy work with CoreBluetooth.
                   DESC

  spec.homepage     = "https://github.com/cvladislav/BluetoothWrapper.git"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "cvladislav" => "cvl@ciklum.com" }

  spec.ios.deployment_target = "14.1"
  spec.swift_version = "5.0"

  spec.source        = { :git => "https://github.com/cvladislav/BluetoothWrapper.git", :tag => "#{spec.version}" }
  spec.source_files  = "Sources/BluetoothWrapper/**/*.{h,m,swift}"

  spec.dependency "AsyncOperation", "~> 1.1.0"

end
