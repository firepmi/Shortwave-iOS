# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

target 'Shortwave' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for Shortwave
#pod 'Firebase'
#pod 'Firebase/Auth'
#pod 'Firebase/Database'
#pod 'Firebase/Core'
#pod 'Firebase/Storage'
#pod 'Firebase/RemoteConfig'
pod 'MarqueeLabel/Swift'
pod 'DeviceKit'
pod 'SwiftReorder'
pod 'IDZSwiftCommonCrypto'
pod 'DirectoryWatcher'
pod 'Alamofire'
pod 'AlamofireImage'
pod 'SwiftyJSON'
pod 'JGProgressHUD'
pod 'SearchTextField'
pod 'AMProgressBar'
pod 'Toast-Swift'
pod 'SDWebImage'
pod "SwiftyXMLParser", :git => 'https://github.com/yahoojapan/SwiftyXMLParser.git'
  target 'ShortwaveTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'ShortwaveUITests' do
    inherit! :search_paths
    # Pods for testing
  end

end

DEFAULT_SWIFT_VERSION = '5.0'

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = DEFAULT_SWIFT_VERSION
    end
  end
end
