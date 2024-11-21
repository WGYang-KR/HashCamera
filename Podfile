# Uncomment the next line to define a global platform for your project
platform :ios, '15.0'

target 'HashCamera' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
  
  # Pods for HashCamera
  pod 'RxSwift', '~> 6.5.0'
  pod 'RxCocoa', '~> 6.5.0'
  pod 'RxGesture'
  pod 'SnapKit', '5.6.0'
  pod 'SideMenu'
  pod 'SDWebImage', '~> 5.0'
  pod 'SwiftEntryKit', '2.0.0'
  pod 'FirebaseAnalytics'
  pod 'FirebaseCrashlytics'
  pod 'FirebaseRemoteConfig'
  
  post_install do |installer|
    installer.generated_projects.each do |project|
      project.targets.each do |target|
        target.build_configurations.each do |config|
          config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '15.0'
        end
      end
    end
  end
  
  
end
