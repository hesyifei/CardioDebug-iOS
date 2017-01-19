source 'https://github.com/CocoaPods/Specs.git'
# Uncomment the next line to define a global platform for your project
platform :ios, '8.0'

target 'ImproveHRV' do
  # Comment the next line if you're not using Swift and don't want to use dynamic frameworks
  use_frameworks!

  # Pods for ImproveHRV
  pod 'AsyncSwift'
  pod 'Alamofire', '~> 4.0'
  pod 'Charts'
  pod "TouchVisualizer", :configurations => ['Debug']
  pod 'Eureka', '~> 2.0.0-beta.1'
  pod 'RealmSwift'
  pod 'MBProgressHUD', '~> 1.0.0'
  pod 'VTAcknowledgementsViewController'

  target 'ImproveHRVTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'ImproveHRVUITests' do
    inherit! :search_paths
    # Pods for testing
  end

end

post_install do | installer |
    require 'fileutils'
    copy_acknowledgements('ImproveHRV')
end

def copy_acknowledgements(target_name)
    # pod acknowledgements section
    require 'fileutils'
    file = %Q'Pods-#{target_name}-acknowledgements.plist'
    from = %Q'Pods/Target Support Files/Pods-#{target_name}/'
    to = %Q'ImproveHRV/'
    FileUtils.cp_r(from + file, to + %Q'Pods-acknowledgements.plist', :remove_destination => true)
end
