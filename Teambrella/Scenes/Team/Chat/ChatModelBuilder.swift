//
//  ChatModelBuilder.swift
//  Teambrella
//
//  Created by Yaroslav Pasternak on 24.08.17.
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
//

import UIKit

class ChatModelBuilder {
    let fragmentParser = ChatFragmentParser()
    
    var showRate = false
    var font: UIFont = UIFont.teambrella(size: 14)
    var width: CGFloat = 0
    lazy var heightCalculator = ChatFragmentHeightCalculator(width: width, font: font)
    
    func unsentModel(fragments: [ChatFragment], id: String) -> ChatTextUnsentCellModel {
        let heights = heightCalculator.heights(for: fragments)
        let myName = service.session?.currentUserName ?? Name.empty
        return  ChatTextUnsentCellModel(fragments: fragments,
                                                     fragmentHeights: heights,
                                                     userName: myName,
                                                     date: Date(),
                                                     id: id,
                                                     isFailed: false)
    }
    
    func separatorModelIfNeeded(firstModel: ChatCellModel, secondModel: ChatCellModel) -> ChatCellModel? {
        if firstModel.date.interval(of: .day, since: secondModel.date) != 0 {
            return ChatSeparatorCellModel(date: secondModel.date.addingTimeInterval(-0.01))
        }
        return nil
    }
    
    func cellModels(from chatItems: [ChatEntity],
                    isClaim: Bool,
                    isTemporary: Bool) -> [ChatCellModel] {
        var result: [ChatCellModel] = []
   
        for item in chatItems {
            let fragments = fragmentParser.parse(item: item)
            var isMy = false
            service.session?.currentUserID.map { isMy = item.userID == $0 }
            
            let name: Name
            let avatar: Avatar
            if isMy == true {
                name = Name(fullName: "General.you".localized)
                avatar = service.session?.currentUserAvatar ?? Avatar.none
            } else {
                name = item.name
                avatar = item.avatar
            }
            
            let date = item.created
           
            var rateString: String?
            if showRate {
                if let rate = item.vote {
                rateString = isClaim
                    ? "Team.Chat.TextCell.voted_format".localized(String.truncatedNumber(rate * 100))
                    : "Team.Chat.TextCell.Application.voted_format".localized(String.formattedNumber(rate))
                } else {
                    rateString = "Team.Chat.TextCell.notVoted".localized
                }
            } else {
                rateString = nil
            }
            
            let model = ChatTextCellModel(entity: item,
                                          fragments: fragments,
                                          fragmentHeights: heightCalculator.heights(for: fragments),
                                          isMy: isMy,
                                          userName: name,
                                          userAvatar: avatar,
                                          rateText: rateString,
                                          date: date,
                                          isTemporary: isTemporary)
            result.append(model)
        }
        return result
    }
    
}
