Pod::Spec.new do |s|
    s.name             = "SwiftCJClient"
    s.version          = "0.1.0"
    s.summary          = "AFNetworking-based Collection+JSON HTTP client."
    s.description      = <<-DESC
                        An AFNetworking-based HTTP API client for Collection+JSON using SwiftCJ and BrightFutures
                        DESC
    s.homepage         = "https://github.com/adamcin/SwiftCJClient"
    s.license          = 'MIT'
    s.author           = { "Mark Adamcin" => "adamcin@gmail.com" }
    s.source           = { :git => "https://github.com/adamcin/SwiftCJClient.git", :tag => s.version.to_s }
    s.social_media_url = 'https://twitter.com/MarkAdamcin'


    s.ios.deployment_target     = '8.0'
    s.osx.deployment_target     = '10.10'

    s.requires_arc = true

    s.source_files = 'Pod/Classes/**/*'

    s.frameworks = 'Foundation', 'Security'

    s.dependency 'SwiftCJ', '~> 0.1.0'

    s.dependency 'BrightFutures', '~> 2.0.0-beta.1'

    s.dependency 'AFNetworking', '~> 2.0'

end
