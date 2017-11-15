//
//  ProxyCell.swift
//  Teambrella
//
//  Created by Yaroslav Pasternak on 22.06.17.

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

class ProxyCell: UICollectionViewCell, XIBInitableCell {
    @IBOutlet var avatarView: RoundBadgedView!
    @IBOutlet var numberLabel: Label!
    @IBOutlet var nameLabel: MessageTitleLabel!
    @IBOutlet var detailsLabel: InfoLabel!
    @IBOutlet var timeLabel: MessageTitleLabel!
    @IBOutlet var rankLabel: InfoLabel!
    @IBOutlet var leftBar: ScaleBar!
    @IBOutlet var middleBar: ScaleBar!
    @IBOutlet var rightBar: ScaleBar!
    @IBOutlet var dragHandleView: DragHandleView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        ViewDecorator.roundedEdges(for: self)
        ViewDecorator.shadow(for: self)
        numberLabel.layer.borderWidth = 1
        numberLabel.layer.borderColor = #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1).cgColor
        numberLabel.layer.cornerRadius = 7.5
        
    }

}

class DragHandleView: UIImageView {
    
}
