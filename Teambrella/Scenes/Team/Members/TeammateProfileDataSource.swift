//
//  TeammateProfileDataSource.swift
//  Teambrella
//
//  Created by Yaroslav Pasternak on 30.05.17.
//  Copyright © 2017 Yaroslav Pasternak. All rights reserved.
//

import UIKit

enum TeammateProfileCellType: String {
    case me, summary, object, stats, contact, dialog
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
    var source: [TeammateProfileCellType] = []
    var teammate: TeammateLike
    
    init(teammate: TeammateLike, isMe: Bool) {
        self.teammate = teammate
        source.append(isMe ? .me : .summary)
    }
    
    var sections: Int = 1
    
    func rows(in section: Int) -> Int {
        return source.count
    }
    
    func type(for indexPath: IndexPath) -> TeammateProfileCellType {
        return source[indexPath.row]
    }
    
    func loadEntireTeammate(completion: @escaping () -> Void) {
        let key = Key(base58String: ServerService.privateKey, timestamp: service.server.timestamp)
        
        let body = RequestBodyFactory.teammateBody(key: key, id: teammate.userID)
        let request = TeambrellaRequest(type: .teammate, body: body, success: { [weak self] response in
            guard let me = self else { return }
            
            if case .teammate(let extendedTeammate) = response {
                me.teammate.extended = extendedTeammate
                me.modifySource()
                completion()
            }
        })
        request.start()
    }
    
    private func modifySource() {
        if teammate.extended?.object != nil {
            source.append(.object)
        }
        if teammate.extended?.stats != nil {
            source.append(.stats)
        }
        if !socialItems.isEmpty {
            source.append(.contact)
        }
        if teammate.extended?.topic != nil {
            source.append(.dialog)
        }
    }
    
    var socialItems: [SocialItem] {
        var items: [SocialItem] = []
        if let facebook = teammate.extended?.basic.facebook {
            items.append(SocialItem(type: .facebook, icon: #imageLiteral(resourceName: "facebook"), address: facebook))
        }
        return items
    }
}
