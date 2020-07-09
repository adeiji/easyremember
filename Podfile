# Uncomment the next line to define a global platform for your project
# platform :ios, '9.0'

source 'https://github.com/CocoaPods/Specs.git'
source 'https://github.com/adeiji/dephyned-specs.git'

target 'EZRemember' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!

  pod 'SwiftyBootstrap', path: '/Users/adeiji/Documents/Dephyned/libraries/swifty-bootstrap/SwiftyBootstrap'
  pod 'DephynedFire', path: '/Users/adeiji/Documents/Dephyned/libraries/DephynedFire'
  pod 'FolioReaderKit', path: '/Users/adeiji/Documents/Dephyned/open_source/FolioReaderKit'
  pod 'DephynedPurchasing', path: '/Users/adeiji/Documents/Dephyned/libraries/DephynedPurchasing'
  pod 'UITextView+Placeholder'
  pod 'FirebaseMessaging'
  pod 'Firebase/Crashlytics'
  pod 'Firebase/RemoteConfig'
  pod 'Firebase/Analytics'
  pod 'RxSwift'
  pod 'RxCocoa'
  pod 'PodAsset'
  pod 'paper-onboarding'

  # Pods for EZRemember

  target 'EZRememberNotifications' do
    inherit! :search_paths
    pod 'SnapKit'
  end

  target 'EZRememberTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'EZRememberUITests' do
    inherit! :search_paths
    # Pods for testing
  end

end
