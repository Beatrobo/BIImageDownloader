Pod::Spec.new do |s|
  s.name                  = "BIImageDownloader"
  s.version               = "1.2.4"
  s.summary               = "軽量な永続化機能とキャッシュ機能付きの画像ダウンローダー"
  s.authors               = {
    "Yusuke SUGAMIYA" => "yusuke.dnpp@gmail.com",
    "Yusuke Ito"      => "novi.mad@gmail.com"
  }
  s.homepage              = "https://github.com/Beatrobo/BIImageDownloader"
  s.source                = { :git => "git@github.com:Beatrobo/BIImageDownloader.git", :tag => "#{s.version}" }
  s.source_files          = 'BIImageDownloader/**/*.{h,m}'
  s.ios.source_files      = 'BIImageDownloader/**/*.{h,m}'
  s.osx.source_files      = 'BIImageDownloader/**/*.{h,m}'
  s.ios.deployment_target = '6.0'
  s.osx.deployment_target = '10.8'
  s.requires_arc          = true

  s.dependency 'BILogManager'
  s.dependency 'BIReachability'

  s.license = {
   :type => "Beatrobo Inc Library",
   :text => ""
  }
end
