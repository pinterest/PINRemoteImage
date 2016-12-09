source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '7.0'
project 'Examples/Example/PINRemoteImage.xcodeproj'

#TODO CocoaPods plugin instead?
abstract_target 'Buck' do
  target 'PINRemoteImage' do
    pod 'FLAnimatedImage', '~> 1.0'
    pod 'PINCache', '3.0.1-beta.2'
  end

  post_install do |installer|
    require 'fileutils'

    pod_names = installer.pod_targets.flat_map do |pod_target|
      pod_target.pod_name
    end

    pod_names.each do |pod_name|
      # Recursively copy all contents of buck-files/pod_name to Pods/pod_name,
      # override existing files if needed
      buck_files_dir = 'buck-files/' + pod_name
      pod_dir = 'Pods/' + pod_name
      if File.directory?(buck_files_dir)
        FileUtils.cp_r(buck_files_dir + '/.', pod_dir, :preserve => false)

        # In Pods/pod_name/, rename BUCK_template file to BUCK
        buck_template_file = pod_dir + '/BUCK_template'
        if File.file?(buck_template_file)
          FileUtils.mv(buck_template_file, pod_dir + '/BUCK')
        end
      end
    end
  end
end
