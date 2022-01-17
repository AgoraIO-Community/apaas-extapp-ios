Pod::Spec.new do |spec|
  spec.name         = "AgoraWidgets"
  spec.version      = "2.0.0"
  spec.summary      = "Agora widgets"
  spec.description  = "Agora native widgets"
  spec.homepage     = "https://docs.agora.io/en/agora-class/landing-page?platform=iOS"
  spec.license      = { "type" => "Copyright", "text" => "Copyright 2020 agora.io. All rights reserved." }
  spec.author       = { "Agora Lab" => "developer@agora.io" }
  spec.module_name  = "AgoraWidgets"

  spec.ios.deployment_target = "10.0"
  spec.swift_versions        = ["5.0", "5.1", "5.2", "5.3", "5.4"]

  spec.source       = { :git => "git@github.com:AgoraIO-Community/apaas-extapp-ios.git", :tag => "AgoraWidgets_v" + "#{spec.version.to_s}" }
  spec.source_files = "Widgets/AgoraWidgets/Common/*.{h,m,swift}", "Widgets/AgoraWidgets/RenderSpread/*.{h,m,swift}", "Widgets/AgoraWidgets/Cloud/**/*.{h,m,swift}", "Widgets/AgoraWidgets/Whiteboard/**/*.{h,m,swift}", "Widgets/AgoraWidgets/RtmIM/**/*.{h,m,swift}"
  
  spec.dependency "AgoraUIBaseViews", ">=2.0.0"
  spec.dependency "AgoraWidget", ">=2.0.1"
  spec.dependency "AgoraLog"
  spec.dependency "Whiteboard"
  spec.dependency "Armin", ">=1.0.9"

  spec.dependency "SwifterSwift"
  spec.dependency "Masonry"
  spec.dependency "FLAnimatedImage"

  spec.pod_target_xcconfig  = { "EXCLUDED_ARCHS[sdk=iphonesimulator*]" => "arm64", "DEFINES_MODULE" => "YES" }
  spec.user_target_xcconfig = { "EXCLUDED_ARCHS[sdk=iphonesimulator*]" => "arm64", "DEFINES_MODULE" => "YES" }
  spec.pod_target_xcconfig  = { "VALID_ARCHS" => "arm64 armv7 x86_64" }
  spec.user_target_xcconfig = { "VALID_ARCHS" => "arm64 armv7 x86_64" } 
  spec.xcconfig             = { "BUILD_LIBRARY_FOR_DISTRIBUTION" => "YES" }
  
  spec.subspec "Resources" do |ss|
      ss.resource_bundles = {
        "AgoraWidgets" => ["AgoraResources/**/*.{xcassets,strings,gif,mp3}"]
      }
  end
end
