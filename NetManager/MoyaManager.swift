//
//  MoyaManager.swift
//  net
//
//  Created by 陈凯文 on 2019/9/12.
//  Copyright © 2019 陈凯文. All rights reserved.
//

import UIKit
import Moya
import RxSwift

class MoyaManager {
    
    public typealias Prepare = () -> Void
    ///网络请求host
    public var HTTPHost = "http://test-family-api.xiaomawang.com"
    
    ///请求头参数
    public var headerParams: [String: String] = [:]
    
    static let shareinstaned = MoyaManager()
    
    private let provider = MoyaProvider<BaseApi>()
    
    private init() {
        
    }
    
    ///开始网络请求
    public func requestDatas(api: BaseApi, prepare: Prepare?) -> Observable<ResultModel?> {
        
        ///请求操作之前
        prepare?()
        
        return self.provider.rx.request(api)
            .mapJSON()
            .map{ (data) -> ResultModel? in
                ck_print(data)
                switch api {
                case .base(_, _, _):
                    var rst = ResultModel()
                    rst.data = data
                    return rst
                default:
                    let rst = ResultModel.deserialize(from: data as? [String: Any])
                    return rst
                }
                
            }.catchError({ (error) -> PrimitiveSequence<SingleTrait, ResultModel?> in
                ck_print(error)
                
                return PrimitiveSequence<SingleTrait, ResultModel?>.just(nil)
            }).asObservable()
    }
    
    ///网络请求
    ///prepare   nil则没有加载toast
    public class func requestDatas(api: BaseApi, prepare: Prepare?) -> Observable<ResultModel?> {
        return MoyaManager.shareinstaned.requestDatas(api: api, prepare: prepare)
    }

}
