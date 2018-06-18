//
//  JoinTeamCellModels.swift
//  Teambrella
//
//  Created by Yaroslav Pasternak on 01.07.17.

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

protocol JoinTeamCellModel {
    static var cellID: String { get }
}

struct JoinTeamGreetingCellModel: JoinTeamCellModel {
    static var cellID = JoinTeamGreetingCell.cellID
}

struct JoinTeamInfoCellModel: JoinTeamCellModel {
    static var cellID = JoinTeamInfoCell.cellID
}

struct JoinTeamPersonalCellModel: JoinTeamCellModel {
    static var cellID = JoinTeamPersonalCell.cellID
}

struct JoinTeamItemCellModel: JoinTeamCellModel {
    static var cellID = JoinTeamItemCell.cellID
}

struct JoinTeamMessageCellModel: JoinTeamCellModel {
    static var cellID = JoinTeamMessageCell.cellID
}

struct JoinTeamTermsCellModel: JoinTeamCellModel {
    static var cellID = JoinTeamTermsCell.cellID
}