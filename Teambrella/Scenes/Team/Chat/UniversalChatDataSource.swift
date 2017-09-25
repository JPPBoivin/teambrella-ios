//
//  UniversalChatDataSource.swift
//  Teambrella
//
//  Created by Yaroslav Pasternak on 19.06.17.

/* Copyright(C) 2017  Teambrella, Inc.
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU Affero General Public License(version 3) as published
 * by the Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Affero General Public License for more details.
 *
 * You should have received a copy of the GNU Affero General Public License
 * along with this program.  If not, see<http://www.gnu.org/licenses/>.
 */

import Foundation
import SwiftyJSON

final class UniversalChatDatasource {
    private var topic: Topic?
    private var claim: EnhancedClaimEntity?
    var name: String?
    
    var topicID: String? { return claim?.topicID }
    var claimID: String? {
        if let strategy = strategy as? ClaimChatStrategy {
            return strategy.claim.id
        }
        return nil
    }
    
    var chatHeader: String? {
        if let strategy = strategy as? ClaimChatStrategy {
            return strategy.claim.description
        } else if let strategy = strategy as? HomeChatStrategy {
            return strategy.card.chatTitle
        }
        return nil
    }
    
    var count: Int { return chunks.reduce(0) { $0 + $1.count } }
    var limit                         = 10
    
    var hasNext = true
    var hasPrevious = true
    var isFirstLoad = true
    var title: String { return strategy.title }
    var lastIndexPath: IndexPath? { return count >= 1 ? IndexPath(row: count - 1, section: 0) : nil }
    var currentTopCell: IndexPath? {
        guard let topCellDate = topCellDate else { return nil }
        
        let models = chunks.flatMap { $0.cellModels }
        for (idx, model) in models.enumerated() where model.date == topCellDate {
            return IndexPath(row: idx, section: 0)
        }
        return nil
    }
    
    private var topCellDate: Date?
    
    var previousCount: Int = 0
    
    var isLoadNextNeeded: Bool = false {
        didSet {
            guard isLoadNextNeeded else { return }
            
            if !isLoading && hasNext {
                loadNext()
            }
        }
    }
    
    var allImages: [String] {
        let models = chunks.flatMap { $0.cellModels }
        let textCellModels = models.flatMap { $0 as? ChatTextCellModel }
        let fragments = textCellModels.flatMap { $0.fragments }
        var images: [String] = []
        for fragment in fragments {
            switch fragment {
            case let .image(string, _):
                images.append(string)
            default:
                break
            }
        }
        return images
    }
    
    var isLoadPreviousNeeded: Bool = false {
        didSet {
            guard isLoadPreviousNeeded else { return }
            
            if !isLoading && hasPrevious {
                loadPrevious()
            }
        }
    }
    
    var isRateVisible: Bool { return strategy.isRateVisible }
    
    var onUpdate: ((_ backward: Bool, _ hasNewItems: Bool) -> Void)?
    var onMessageSend: (() -> Void)?
    var onLoadPrevious: ((Int) -> Void)?
    
    private var cellModels: [ChatCellModel] = []
    private var chunks: [ChatChunk] = []
    
    private var lastRead: Int64               = 0 {
        didSet {
            if oldValue == 0 {
                loadPrevious()
            }
        }
    }
    private var forwardOffset: Int            = 0
    private var backwardOffset: Int           = 0
    private var postsCount: Int               = 0
    private var avatarSize                    = 64
    private var commentAvatarSize             = 32
    var cloudWidth: CGFloat           = 0
    private var labelHorizontalInset: CGFloat = 8
    private var font: UIFont                  = UIFont.teambrella(size: 14)
    
    private(set) var isLoading = false
    private var isChunkAdded = false
    
    private var strategy: ChatDatasourceStrategy = EmptyChatStrategy()
    
    private var cellModelBuilder = ChatModelBuilder()
    
    func addContext(context: ChatContext) {
        strategy = ChatStrategyFactory.strategy(with: context)
        hasPrevious = strategy.canLoadBackward
        cellModelBuilder.showRate = isRateVisible
    }
    
    func loadNext() {
        load(previous: false)
    }
    
    func loadPrevious() {
        backwardOffset -= limit
        load(previous: true)
    }
    
    private func load(previous: Bool) {
        let canLoadMore = previous ? hasPrevious : hasNext
        guard isLoading == false, canLoadMore else { return }
        
        isLoading = true
        if previous {
            isLoadPreviousNeeded = false
            topCellDate = chunks.first?.firstTextMessage?.date
        } else {
            isLoadNextNeeded = false
        }
        
        service.storage.freshKey { [weak self] key in
            guard let me = self else { return }
            
            let limit = me.limit// previous ? -me.limit: me.limit
            let offset = previous ? me.backwardOffset : me.forwardOffset
            var payload: [String: Any] = ["limit": limit,
                                          "offset": offset,
                                          "avatarSize": me.avatarSize,
                                          "commentAvatarSize": me.commentAvatarSize]
            if me.lastRead > 0 {
                payload["since"] = me.lastRead
            }
            let body = me.strategy.updatedChatBody(body: RequestBody(key: key, payload: payload))
            let request = TeambrellaRequest(type: me.strategy.requestType,
                                            body: body,
                                            success: { [weak me] response in
                                                guard let me = me else { return }
                                                
                                                me.isLoading = false
                                                me.process(response: response,
                                                           isPrevious: previous,
                                                           isMyNewMessage: false)
            })
            request.start()
        }
    }
    
    func clear() {
        cellModels.removeAll()
        chunks.removeAll()
        forwardOffset = 0
        backwardOffset = 0
        postsCount = 0
        hasNext = true
    }
    
    func send(text: String, images: [String]) {
        isLoading = true
        let body = strategy.updatedMessageBody(body: RequestBody(key: service.server.key, payload: ["text": text,
                                                                                                    "images": images]))
        
        let request = TeambrellaRequest(type: strategy.postType, body: body, success: { [weak self] response in
            guard let me = self else { return }
            
            me.hasNext = true
            me.isLoading = false
            me.onMessageSend?()
            me.process(response: response, isPrevious: false, isMyNewMessage: true)
        })
        request.start()
    }
    
    private func addModels(models: [ChatEntity], isPrevious: Bool) {
        previousCount = postsCount
        let currentPostsCount = models.count
        postsCount += currentPostsCount
        if isPrevious {
            isLoadPreviousNeeded = false
        } else {
            isLoadNextNeeded = false
            forwardOffset += currentPostsCount
        }
        
        let models = createCellModels(from: models)
        let chunk = ChatChunk(cellModels: models)
        addChunk(chunk: chunk)
    }
    
    private func process(response: TeambrellaResponseType, isPrevious: Bool, isMyNewMessage: Bool) {
        let count = self.count
        switch response {
        case let .chat(model):
            addModels(models: model.chat, isPrevious: isPrevious)
            claim?.update(with: model.basicPart)
            if limit > model.chat.count {
                if isPrevious {
                    hasPrevious = false
                } else {
                    hasNext = false
                    lastRead = model.lastRead
                }
            }
        case let .privateChat(messages):
            if isMyNewMessage {
                clear()
            }
            addModels(models: messages, isPrevious: isPrevious)
            if limit > messages.count {
                if isPrevious {
                    hasPrevious = false
                } else {
                    hasNext = false
                    // lastRead = model.lastRead
                }
            }
        case let .newPost(post):
            let models = createCellModels(from: [post])
            let chunk = ChatChunk(cellModels: models, isTemporary: true)
            addChunk(chunk: chunk)
            postsCount += 1
            forwardOffset += 1
        default:
            return
        }
        let hasNewModels = self.count > count
        handleNewSeparator(hasNewModels: hasNewModels, isPrevious: isPrevious, isMyNewMessage: isMyNewMessage)
        onUpdate?(isPrevious, hasNewModels)
    }
    
    private func addChunk(chunk: ChatChunk?) {
        guard let chunk = chunk else {
            isChunkAdded = false
            return
        }
        
        isChunkAdded = true
        for (idx, storedChunk) in chunks.enumerated() where chunk < storedChunk {
            chunks.insert(chunk, at: idx)
            return
        }
        chunks.append(chunk)
    }
    
    private func createCellModels(from entities: [ChatEntity]) -> [ChatCellModel] {
        cellModelBuilder.font = font
        cellModelBuilder.width = cloudWidth - labelHorizontalInset * 2
        let models = cellModelBuilder.cellModels(from: entities,
                                                 lastChunk: chunks.last,
                                                 isClaim: strategy.requestType == .claimChat)
        return models
    }
    
    private func handleNewSeparator(hasNewModels: Bool, isPrevious: Bool, isMyNewMessage: Bool) {
        if hasNewModels && isFirstLoad {
            addNewSeparatorIfNeeded(isPrevious: isPrevious, isMyNewMessage: isMyNewMessage)
            isFirstLoad = false
        } else if !hasNewModels {
            removeNewSeparatorIfNeeded()
        }
    }
    private func removeNewSeparatorIfNeeded() {
        if let firstChunk = chunks.first, firstChunk.cellModels.first is ChatNewMessagesSeparatorModel {
            chunks.removeFirst()
        }
    }
    
    private func addNewSeparatorIfNeeded(isPrevious: Bool, isMyNewMessage: Bool) {
        guard !isPrevious && !isMyNewMessage else { return }
        guard let firstChunk = chunks.first else { return }
        
        let minTime = firstChunk.minTime
        let model = ChatNewMessagesSeparatorModel(date: minTime.addingTimeInterval(-0.01))
        let chunk = ChatChunk(cellModels: [model])
        addChunk(chunk: chunk)
    }
    
    subscript(indexPath: IndexPath) -> ChatCellModel {
        var idx = 0
        var rightChunk: ChatChunk?
        for chunk in chunks {
            if idx + chunk.count > indexPath.row {
                rightChunk = chunk
                break
            }
            idx += chunk.count
        }
        guard let chunk = rightChunk else { fatalError("Wrong indexing") }
        
        let offset = indexPath.row - idx
        return chunk.cellModels[offset]
    }
    
}
