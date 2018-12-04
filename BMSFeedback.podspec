Pod::Spec.new do |s|

  s.name              = 'BMSFeedback'
  s.version           = '1.0.0'
  s.summary           = 'The In App Feedback feature of analytics component of the Swift client SDK for IBM Bluemix Mobile Services'
  s.homepage          = 'https://github.com/mohlogan/bms-clientsdk-swift-analytics-feedback.git'
  s.documentation_url = 'https://ibm-bluemix-mobile-services.github.io/API-docs/client-SDK/BMSAnalytics/Swift/index.html'
  s.license           = 'Apache License, Version 2.0'
  s.authors           = { 'IBM Bluemix Services Mobile SDK' => 'mobilsdk@us.ibm.com' }

  s.source       = { :git => 'https://github.com/mohlogan/bms-clientsdk-swift-analytics-feedback.git', :tag => s.version }

  s.source_files = 'Source/**/*.swift','Source/Feedback/Resource/*.h'
  s.dependency 'IBMMobileFirstPlatformFoundation'
  s.dependency 'SSZipArchive'

  s.requires_arc = true
  s.ios.resources = ['Source/Feedback/Resources/*.{storyboard,xcassets,json,imageset,png}']
  s.ios.deployment_target = '8.0'
end
