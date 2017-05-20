//
//  PostManager.swift
//  HiPDA
//
//  Created by leizh007 on 2017/5/17.
//  Copyright © 2017年 HiPDA. All rights reserved.
//

import Foundation
import RxSwift

typealias PostListFetchCompletion = (PostListResult) -> Void

/// 数据的网络请求管理
class PostManager {
    var pidSet = Set<Int>()
    fileprivate var disposeBag = DisposeBag()
    var postInfo: PostInfo {
        didSet {
            title = nil
            totalPage = .max
        }
    }
    init(postInfo: PostInfo) {
        self.postInfo = postInfo
    }
    
    fileprivate var title: String?
    
    /// 总页数
    fileprivate(set) var totalPage = Int.max
    
    /// 当前页数
    var page: Int {
        return postInfo.page
    }
    
    /// 加载第一页数据
    func loadFirstPage(completion: @escaping PostListFetchCompletion = { _ in }) {
        postInfo = PostInfo.lens.page.set(1, postInfo)
        load(postInfo: postInfo, completion: completion)
    }
    
    /// 加载前一页数据
    func loadPreviousPage(completion: @escaping PostListFetchCompletion = { _ in }) {
        postInfo = PostInfo.lens.page.set(postInfo.page - 1, postInfo)
        load(postInfo: postInfo, completion: completion)
    }
    
    /// 加载后一页数据
    func loadNextPage(completion: @escaping PostListFetchCompletion = { _ in }) {
        postInfo = PostInfo.lens.page.set(postInfo.page + 1, postInfo)
        load(postInfo: postInfo, completion: completion)
    }
    
    /// 加载指定postInfo的数据
    func load(postInfo: PostInfo, completion: @escaping PostListFetchCompletion = { _ in }) {
        disposeBag = DisposeBag()
        var totalPage = self.totalPage
        var title = self.title
        HiPDAProvider.request(.posts(postInfo))
            .observeOn(ConcurrentDispatchQueueScheduler(qos: .userInteractive))
            .mapGBKString()
            .do(onNext: { html in
                if totalPage == .max {
                    totalPage = try HtmlParser.totalPage(from: html)
                }
                if postInfo.page == 1 {
                    if title == nil {
                        title = try HtmlParser.postTitle(from: html)
                    }
                } else {
                    title = nil
                }
            })
            .map(HtmlParser.posts(from:))
            .observeOn(MainScheduler.instance)
            .subscribe { [weak self] event in
                guard let `self` = self, postInfo == `self`.postInfo else { return }
                self.totalPage = totalPage
                self.title = title
                switch event {
                case let .next(posts):
                    self.pidSet = Set(posts.map { $0.id })
                    completion(.success((title: title, posts: posts)))
                case let .error(error):
                    let postsResultError: PostError = error is HtmlParserError ? .parseError(String(describing: error as! HtmlParserError)) : .unKnown(error.localizedDescription)
                    completion(.failure(postsResultError))
                case .completed:
                    break
                }
            }.disposed(by: disposeBag)
    }
}