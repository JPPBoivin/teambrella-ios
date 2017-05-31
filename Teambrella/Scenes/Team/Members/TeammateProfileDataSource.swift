//
//  TeammateProfileDataSource.swift
//  Teambrella
//
//  Created by Yaroslav Pasternak on 30.05.17.
//  Copyright © 2017 Yaroslav Pasternak. All rights reserved.
//

import UIKit

enum TeammateProfileCellType: String {
    case summary, object, stats, contact, dialog
}

class TeammateProfileDataSource {
    var source: [TeammateProfileCellType] = [
        .summary,
        .object,
        .stats,
        .contact,
        .dialog
    ]
    var teammate: TeammateLike
    
    init(teammate: TeammateLike) {
        self.teammate = teammate
    }
    
    var sections: Int = 1
    
    func rows(in section: Int) -> Int {
        return source.count
    }
    
    func type(for indexPath: IndexPath) -> TeammateProfileCellType {
        return source[indexPath.row]
    }
    
}
