#
# Be sure to run `pod lib lint LKPayment.podspec' to ensure this is a
# valid spec and remove all comments before submitting the spec.
#
# Any lines starting with a # are optional, but encouraged
#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = "LKPayment"
  s.version          = "0.9.2"
  s.summary          = "In-app purchase utility"
  s.description      = <<-DESC
  In-app purchase utility.
                       DESC
  s.homepage         = "https://github.com/lakesoft/LKPayment"
  s.license          = 'MIT'
  s.author           = { "Hiroshi Hashiguchi" => "xcatsan@mac.com" }
  s.source           = { :git => "https://github.com/lakesoft/LKPayment.git", :tag => s.version.to_s }

  s.platform     = :ios, '7.0'
  s.requires_arc = true

  s.source_files = 'Pod/Classes'
  s.resources = 'Pod/Assets/LKPayment-Resources.bundle'

  # s.public_header_files = 'Pod/Classes/**/*.h'
  s.frameworks = 'StoreKit'
  # s.dependency 'AFNetworking', '~> 2.3'
end
