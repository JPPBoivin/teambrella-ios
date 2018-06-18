//
//  VotingChartCell.swift
//  Teambrella
//
//  Created by Yaroslav Pasternak on 21.09.2017.
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

class VotingChartCell: UICollectionViewCell, XIBInitableCell {
    @IBOutlet var heightConstraint: NSLayoutConstraint!
    @IBOutlet var topLabel: UILabel!
    @IBOutlet var centerLabel: UILabel!
    @IBOutlet var column: RoundedCornersView!
    @IBOutlet var columnHeightConstraint: NSLayoutConstraint!
    
    var isCentered: Bool = false
    
    override func awakeFromNib() {
        super.awakeFromNib()
        centerLabel.font = isSmallIPhone ? UIFont.teambrellaBold(size: 8) : UIFont.teambrellaBold(size: 10)
    }

}
