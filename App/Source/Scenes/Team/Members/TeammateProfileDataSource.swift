//
//  TeammateProfileDataSource.swift
//  Teambrella
//
//  Created by Yaroslav Pasternak on 30.05.17.

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

import UIKit

enum TeammateProfileCellType: String {
    case me, summary, object, stats, contact, dialog, dialogCompact, voting, voted
}

enum SocialItemType: String {
    case facebook, vk, twitter, email, call
}

struct SocialItem {
    var name: String {
        return type.rawValue
    }
    let type: SocialItemType
    let icon: UIImage?
    let address: String
}

class TeammateProfileDataSource: SingleItemDataSource {
    let teammateID: String
    let teamID: Int
    let isMe: Bool
    // let isVoting: Bool
    var isMyProxy: Bool {
        get {
            return item?.basic.isMyProxy ?? false
        }
        set {
            item?.myProxy(set: newValue)
        }
    }
    
    var source: [TeammateProfileCellType] = []
    var item: TeammateLarge?
    var riskScale: RiskScaleEntity? { return item?.riskScale }
    var isNewTeammate = false
    
    var isLoading: Bool = false
    var onUpdate: (() -> Void)?
    var onError: ((Error) -> Void)?
    
    var votingCellIndexPath: IndexPath? {
        for (idx, cellType) in source.enumerated() where cellType == .voting {
            return IndexPath(row: idx, section: 0)
        }
        return nil
    }

    /// we need this check as votedPart is sent from server for the Android needs
    private var canAddVoted: Bool {
        guard let teammate = item else { return false }

        switch teammate.basic.state {
        case .prejoining:
            return false
        default:
            return true
        }
    }
    
    init(id: String, teamID: Int, isMe: Bool) {
        self.teammateID = id
        self.isMe = isMe
        self.teamID = teamID
    }
    
    var sections: Int = 1
    
    func rows(in section: Int) -> Int {
        return source.count
    }
    
    func type(for indexPath: IndexPath) -> TeammateProfileCellType {
        return source[indexPath.row]
    }
    
    func loadData() {
        guard !isLoading else { return }
        
        isLoading = true
        service.dao.requestTeammate(userID: teammateID, teamID: teamID).observe { [weak self] result in
            guard let self = self else { return }

            self.isLoading = false
            switch result {
            case let .value(teammate):
                self.item = teammate
                self.modifySource()
                self.onUpdate?()
            case let .error(error):
                self.onError?(error)
            }
        }
    }
    
    func addToProxy(completion: @escaping () -> Void) {
        service.dao.myProxy(userID: teammateID, add: !isMyProxy).observe { [weak self] result in
            switch result {
            case .value:
                guard let me = self else { return }
                
                me.isMyProxy = !me.isMyProxy
                completion()
            case let .error(error):
                log("\(#file) \(error)", type: .error)
                completion()
            }
        }
    }
    
    func sendRisk(userID: Int, risk: Double?, completion: @escaping (TeammateVotingResult) -> Void) {
        service.dao.sendRiskVote(teammateID: userID, risk: risk).observe { [weak self] result in
            guard let `self` = self else { return }

            switch result {
            case let .value(votingResult):
                self.item?.update(votingResult: votingResult)
                completion(votingResult)
            case let .error(error):
                log("\(#file) \(error)", type: .error)
            }
        }
    }
    
    private func modifySource() {
        guard let teammate = item else { return }
        
        source.removeAll()
        isMyProxy = teammate.basic.isMyProxy
        let isVoted = teammate.voted != nil
        
        //if isMe { source.append(.me) } else { source.append(.summary) }
        source.append(.dialog)
        if let voting = teammate.voting {
            isNewTeammate = true
            if voting.canVote || isMe {
                source.append(.voting)
            } else if canAddVoted {
                source.append(.voted)
            }
            //source.append(.dialogCompact)
        } else if isVoted && canAddVoted {
            source.append(.voted)
        }
        source.append(.object)
        source.append(.stats)
        if !socialItems.isEmpty && !isMe {
            source.append(.contact)
        }
    }
    
    var socialItems: [SocialItem] {
        var items: [SocialItem] = []
        if let facebook = item?.basic.facebook {
            items.append(SocialItem(type: .facebook, icon: #imageLiteral(resourceName: "facebook"), address: facebook))
        }
        if let vk = item?.basic.vk {
            items.append(SocialItem(type: .facebook, icon: #imageLiteral(resourceName: "vk"), address: vk))
        }
        if isMyProxy {
            items.append(SocialItem(type: .call, icon: #imageLiteral(resourceName: "call"), address: ""))
        }
        return items
    }
}
