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
    pod 'RealmSwift', '~>10'
#target 'HashCameraTests' do
#   inherit! :search_paths
#   # Pods for testing
# end

# target 'HashCameraUITests' do
#   # Pods for testing
# end

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
