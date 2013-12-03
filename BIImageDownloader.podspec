Pod::Spec.new do |s|
  s.name          = "BIImageDownloader"
  s.version       = "0.0.1"
  s.summary       = "軽量な永続化機能とキャッシュ機能付きの画像ダウンローダー"
  s.authors       = {
                      "Yusuke SUGAMIYA" => "yusuke.dnpp@gmail.com",
                      "Yusuke Ito"      => "novi.mad@gmail.com"
  }
  s.homepage      = "https://github.com/Beatrobo/BIImageDownloader"
  s.source        = { :git => "git@github.com:Beatrobo/BIImageDownloader.git", :tag => "0.0.1" }
  s.source_files  = 'BIImageDownloader/**/*.{h,m}'
  s.requires_arc  = true
  s.dependency 'BIReachability'
  s.dependency 'DPSmallUtils'
    s.license      = {
   :type => "Beatrobo Inc Library",
   :text => ""
  }
end
