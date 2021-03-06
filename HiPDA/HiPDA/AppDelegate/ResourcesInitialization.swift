//
//  ResourceInitialization.swift
//  HiPDA
//
//  Created by leizh007 on 2017/5/19.
//  Copyright © 2017年 HiPDA. All rights reserved.
//

import Foundation
import RxSwift
import SDWebImage
import AlamofireNetworkActivityIndicator

class ResourcesInitialization: Bootstrapping {
    private var disposeBag = DisposeBag()
    func bootstrap(bootstrapped: Bootstrapped) throws {
        _ = EmoticonHelper.groups
        _ = URLDispatchManager.shared
        _ = UnReadMessagesCountManager.shared
        NetworkActivityIndicatorManager.shared.isEnabled = true
        NetworkActivityIndicatorManager.shared.startDelay = 0.5
        NetworkActivityIndicatorManager.shared.completionDelay = 0.2
        // 最大图片缓存100MB
        SDImageCache.shared().config.maxCacheSize = UInt(pow(10.0, 8.0))
        
        // 初始化一下tabbar的vc
        guard let tabbarController = UIApplication.shared.windows.first?.rootViewController as? UITabBarController else { return }
        tabbarController.viewControllers?.forEach { _ = ($0 as? UINavigationController)?.topViewController?.view }
    }
}
