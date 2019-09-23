
Pod::Spec.new do |spec|


  spec.name         = "MoyaManager"
  spec.version      = "1.2.1"
  spec.summary      = "net swift"
  spec.description  = <<-DESC
                      this project is net manager for moya   
                   DESC

  spec.homepage     = "https://github.com/kai120897660/NetUtil"

  spec.license      = "MIT"
  spec.license      = { :type => "MIT", :file => "LICENSE" }

  spec.author             = { "陈凯文" => "kai120897660@sina.com" }

  spec.swift_version= "5.0"
  spec.platform     = :ios, "10.0"

  spec.source       = { :git => "https://github.com/kai120897660/NetUtil.git", :tag => "#{spec.version}" }


#  spec.source_files  = "NetManage"
  spec.subspec "NetManage" do |ss|
    ss.source_files = "NetManager"
    ss.dependency "Moya/RxSwift",     "~> 13.0"
    ss.dependency "HandyJSON",        "~> 5.0"
  end
  

  spec.requires_arc = true


end
