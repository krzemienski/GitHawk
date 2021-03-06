//
//  GithubClient+Merge.swift
//  Freetime
//
//  Created by Ryan Nystrom on 2/15/18.
//  Copyright © 2018 Ryan Nystrom. All rights reserved.
//

import Foundation

import GitHubAPI

extension GithubClient {

    func merge(
        previous: IssueResult,
        owner: String,
        repo: String,
        number: Int,
        type: IssueMergeType,
        error: @escaping () -> Void
        ) {
        let newStatus = IssueStatusModel(
            status: .merged,
            pullRequest: previous.status.pullRequest,
            locked: previous.status.locked
        )
        let newEvent = IssueStatusEventModel(
            id: UUID().uuidString,
            actor: userSession?.username ?? Constants.Strings.unknown,
            commitHash: nil,
            date: Date(),
            status: .merged,
            pullRequest: previous.pullRequest
        )
        let optimisticResult = previous.updated(
            status: newStatus,
            timelinePages: previous.timelinePages(appending: [newEvent])
        )

        let mergeType: MergeType
        switch type {
        case .merge: mergeType = .merge
        case .rebase: mergeType = .rebase
        case .squash: mergeType = .squash
        }

        let cache = self.cache

        client.send(V3MergePullRequestReqeust(owner: owner, repo: repo, number: number, type: mergeType)) { result in
            switch result {
            case .success:
                cache.set(value: optimisticResult)
            case .failure:
                ToastManager.showGenericError()
                error()
            }
        }
    }

}
