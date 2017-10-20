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

import SwiftyJSON
import UIKit

enum TeammateProfileCellType: String {
    case me, summary, object, stats, contact, dialog, dialogCompact, voting
}

enum SocialItemType: String {
    case facebook, twitter, email
}

struct SocialItem {
    var name: String {
        return type.rawValue
    }
    let type: SocialItemType
    let icon: UIImage?
    let address: String
}

class TeammateProfileDataSource {
    let teammateID: String
    let isMe: Bool
   // let isVoting: Bool
    var isMyProxy: Bool {
        get {
            return extendedTeammate?.basic.isMyProxy ?? false
        }
        set {
            extendedTeammate?.myProxy(set: newValue)
        }
    }
    
    var source: [TeammateProfileCellType] = []
    var extendedTeammate: ExtendedTeammateEntity?
    var riskScale: RiskScaleEntity? { return extendedTeammate?.riskScale }
    var isNewTeammate = false
    
    init(id: String, isMe: Bool) {
        self.teammateID = id
        self.isMe = isMe
    }
    
    var sections: Int = 1
    
    func rows(in section: Int) -> Int {
        return source.count
    }
    
    func type(for indexPath: IndexPath) -> TeammateProfileCellType {
        return source[indexPath.row]
    }
    
    func loadEntireTeammate(completion: @escaping (ExtendedTeammateEntity) -> Void) {
        let key = Key(base58String: ServerService.privateKey, timestamp: service.server.timestamp)
        
        let body = RequestBodyFactory.teammateBody(key: key, id: teammateID)
        let request = TeambrellaRequest(type: .teammate, body: body, success: { [weak self] response in
            guard let me = self else { return }
            
            if case .teammate(let extendedTeammate) = response {
                me.extendedTeammate = extendedTeammate
                me.modifySource()
                completion(extendedTeammate)
            }
        })
        request.start()
    }
    
    func addToProxy(completion: @escaping () -> Void) {
        service.dao.myProxy(userID: teammateID, add: !isMyProxy).observe { [weak self] result in
            switch result {
            case .value:
                guard let me = self else { return }
                
                me.isMyProxy = !me.isMyProxy
                completion()
            case .temporaryValue:
                break
            case let .error(error):
                log("\(#file) \(error)", type: .error)
                completion()
            }
        }
    }
    
    func sendRisk(userID: Int, risk: Double?, completion: @escaping (JSON) -> Void) {
        service.server.updateTimestamp { timestamp, error in
            let key = service.server.key
            let body = RequestBody(payload: ["TeammateId": userID,
                                             "MyVote": risk ?? NSNull(),
                                             "Since": key.timestamp,
                                             "ProxyAvatarSize": 32])
            let request = TeambrellaRequest(type: .teammateVote, body: body, success: { [weak self] response in
                if case .teammateVote(let json) = response {
                    self?.extendedTeammate?.updateWithVote(json: json)
                    completion(json)
                }
            })
            request.start()
        }
        
    }
    
    private func modifySource() {
        guard let teammate = extendedTeammate else { return }
        
        isMyProxy = teammate.basic.isMyProxy
        let isVoting = teammate.voting != nil
        
        if isVoting && !isMe {
            isNewTeammate = true
            source.append(.dialogCompact)
            source.append(.voting)
            source.append(.object)
            source.append(.stats)
            if !socialItems.isEmpty && !isMe {
                source.append(.contact)
            }
        } else {
            if isMe {
                source.append(.me)
            } else {
                source.append(.summary)
            }
                source.append(.object)
                source.append(.stats)
            if !socialItems.isEmpty && !isMe {
                source.append(.contact)
            }
            if !isNewTeammate {
                source.append(.dialog)
            }
        }
    }
    
    var socialItems: [SocialItem] {
        var items: [SocialItem] = []
        if let facebook = extendedTeammate?.basic.facebook {
            items.append(SocialItem(type: .facebook, icon: #imageLiteral(resourceName: "facebook"), address: facebook))
        }
        return items
    }
}
