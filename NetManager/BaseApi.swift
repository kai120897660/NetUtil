//
//  BaseApi.swift
//  net
//
//  Created by 陈凯文 on 2019/9/12.
//  Copyright © 2019 陈凯文. All rights reserved.
//

import UIKit
import Moya

enum BaseApi {
    case get(_ param: Any?, _ url: String)
    case post(_ param: Any?, _ url: String)
    case delete(_ param: Any?, _ url: String)
    case put(_ param: Any?, _ url: String)
    case upload(_ param: Any?, _ uplaod: UplaodDataModel, _ url: String)
    case base(_ param: Any?, _ base: String, _ url: String)
}

extension BaseApi: TargetType {
    public var baseURL: URL {
        
        switch self {
        case .base(_, let base, _):
            return URL.init(string: base)!
        default:
            return URL.init(string: MoyaManager.shareinstaned.HTTPHost)!
        }
    }
    
    public var path: String  {
        
        switch self {
        case .get(_, let url),
             .post(_, let url),
             .delete(_, let url),
             .put(_, let url),
             .upload(_, _, let url),
             .base(_, _, let url):
            return url
        }
    }
    
    public var method: Moya.Method {
        switch self {
        case .get(_, _):
            return .get
        case .post(_, _), .upload(_, _, _):
            return .post
        case .delete(_, _):
            return .delete
        case .put(_, _):
            return .put
        case .base(_, _, _):
            return .post
        }
    }
    
    public var sampleData: Data {
        return "{}".data(using: String.Encoding.utf8)!
    }
    
    public var task: Task {
        
        switch self {
            //        case .get(let params, let url):
            //            ck_print("\(url) \(params ?? [])")
            //            return .requestPlain
            //            return .requestParameters(parameters: (params as? [String : Any]) ?? [:] ,
        //                                      encoding: URLEncoding.default)
        case .get(let params, let url),
             .post(let params, let url),
             .delete(let params, let url),
             .put(let params, let url),
             .base(let params, _, let url):
            ck_print("\(url) \(params ?? [])")
            return .requestParameters(parameters: (params as? [String : Any]) ?? [:] ,
                                      encoding: URLEncoding.default)
            //            let data = try! JSONSerialization.data(withJSONObject: params ?? [:], options: [])
        //            return .requestData(data)
        case .upload(let params, let upload, let url):
            ck_print("\(url) \(params ?? [])")
            return .uploadCompositeMultipart([MultipartFormData.init(provider: .data(upload.data!), name: upload.name, fileName: upload.fileName, mimeType: upload.mineType)], urlParameters: params as? [String : Any] ?? [:] )
        }
    }
    
    public var headers: [String : String]? {
        
        switch self {
        case .get(_, _),
             .post(_, _),
             .delete(_, _),
             .put(_, _),
             .upload(_, _, _):
            return MoyaManager.shareinstaned.headerParams
        case .base(_, _, _):
            return nil
        }
    }
    
    
}

func ck_print(_ items: Any?) {
    #if DEBUG
    if items != nil {
        print(items!)
    }
    #endif
}

///当前环境是否是生产环境
func isDistribution() ->  Bool {
    var isDis = true
    #if DEBUG
    isDis = false
    #endif
    return isDis
}
