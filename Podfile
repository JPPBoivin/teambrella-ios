# Uncomment the next line to define a global platform for your project
platform :ios, '10.3'

def bitcoin_pods
  pod 'CoreBitcoin', :podspec => 'https://raw.github.com/oleganza/CoreBitcoin/master/CoreBitcoin.podspec'
end

def ethereum_pods
#  pod 'Geth', '~> 1.7'
end

def social_pods
 # pod 'FBSDKCoreKit'
 # pod 'FBSDKLoginKit'
 # pod 'FBSDKShareKit'
end

def firebase_pods
  pod 'Firebase/Core'
  pod 'Firebase/Messaging'
end

def swift_frameworks_pods
  pod 'SwiftSoup'
  #pod 'XLPagerTabStrip'
  pod 'ImageSlideshow'
  pod 'KeychainAccess'
  pod 'Kingfisher'
  pod 'PKHUD'
  pod 'ReachabilitySwift'
  pod 'QRCode'
  pod 'Starscream'
  pod 'SwiftDate'
  pod 'SwiftMessages'
end

def pods_bundle
  bitcoin_pods
  ethereum_pods
  social_pods
  firebase_pods
  swift_frameworks_pods
end

target 'Teambrella' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  #use_frameworks!
  inhibit_all_warnings!

  pods_bundle

  target 'TeambrellaTests' do
    inherit! :search_paths
    # Pods for testing
  end

  #target 'TeambrellaUITests' do
  #  inherit! :search_paths
    # Pods for testing
  #end

end

target 'Surilla' do
  inhibit_all_warnings!

  pods_bundle

end

target 'notification' do
  inhibit_all_warnings!

  bitcoin_pods

end

target 'NotificationTeambrella' do
  inhibit_all_warnings!

  bitcoin_pods

end
