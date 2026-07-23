Pod::Spec.new do |spec|
  spec.name         = "AgoraWidgets"
  spec.version      = "2.8.128-hello"
  spec.summary      = "SDKs/AgoraWidgets."
  spec.description  = "Agora native widgets"
  spec.homepage     = "https://docs.agora.io/en/agora-class/landing-page?platform=iOS"
  spec.license      = { "type" => "Copyright", "text" => "Copyright 2020 agora.io. All rights reserved." }
  spec.author       = { "Agora Lab" => "developer@agora.io" }
  
  spec.platform              = :ios
  spec.ios.deployment_target = "10.0"

  spec.source       = { :git => "git@github.com:AgoraIO-Community/apaas-extapp-ios.git", :tag => "AgoraWidgets_v" + "#{spec.version.to_s}" }
    
  spec.pod_target_xcconfig  = { "EXCLUDED_ARCHS[sdk=iphonesimulator*]" => "arm64", "DEFINES_MODULE" => "YES" }
  spec.user_target_xcconfig = { "EXCLUDED_ARCHS[sdk=iphonesimulator*]" => "arm64", "DEFINES_MODULE" => "YES" }
  spec.xcconfig             = { "BUILD_LIBRARY_FOR_DISTRIBUTION" => "YES" }
  spec.pod_target_xcconfig  = { "VALID_ARCHS" => "arm64 armv7 x86_64" }
  spec.user_target_xcconfig = { "VALID_ARCHS" => "arm64 armv7 x86_64" }

  # Agora libs
  spec.dependency "AgoraVideo_Special_iOS", "4.5.2.189.CLVAEC"
  spec.dependency "AgoraFoundation",            "~> 3.5.0"

  # Netless
  spec.dependency "Whiteboard"
  
  # Hyphenate
  spec.dependency "Agora_Chat_iOS",              "1.0.6"

  # Third libs
  spec.dependency "SwifterSwift"
  spec.dependency "SDWebImage",                 "<=5.12.0"
  
  spec.subspec "Source" do |ss|
    ss.source_files = "SDKs/AgoraWidgets/**/**/*.{h,m,swift}"
    ss.resource_bundles = {
      "AgoraWidgets" => ["SDKs/AgoraWidgets/Assets/**/*.{xcassets,strings,gif,mp3,js}"]
    }

    ss.dependency "AgoraUIBaseViews/Source"
    ss.dependency "AgoraWidget/Source"
  end

  spec.subspec "Build" do |ss|
    ss.source_files = "SDKs/AgoraWidgets/**/**/*.{h,m,swift}"
    ss.resource_bundles = {
      "AgoraWidgets" => ["SDKs/AgoraWidgets/Assets/**/*.{xcassets,strings,gif,mp3,js}"]
    }

    ss.dependency "AgoraUIBaseViews/Binary"
    ss.dependency "AgoraWidget/Binary"
  end
  
  spec.subspec "Binary" do |ss|
    ss.vendored_frameworks = [
      "Products/Libs/AgoraWidgets/*.framework"
    ]

    ss.dependency "AgoraUIBaseViews/Binary"
    ss.dependency "AgoraWidget/Binary"
  end

  spec.default_subspec = "Source"
end
