//
//  HomeSupportCell.swift
//  Teambrella
//
//  Created by Екатерина Рыжова on 07.07.17.

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

class HomeSupportCell: UICollectionViewCell, XIBInitableCell {
    enum Constant {
        static let buttonHeight: CGFloat = 40
    }

    @IBOutlet var backView: UIView!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var headerLabel: UILabel!
    @IBOutlet var centerLabel: UILabel!
    @IBOutlet var bottomLabel: UILabel!
    @IBOutlet var button: BorderedButton!
    @IBOutlet var onlineIndicator: UIView!

    @IBOutlet var buttonHeightConstraint: NSLayoutConstraint!

    var isButtonHidden: Bool = false {
        didSet {
            buttonHeightConstraint.constant = isButtonHidden ? 0 : Constant.buttonHeight
            button.isHidden = isButtonHidden
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        ViewDecorator.roundedEdges(for: self)
        backView.layer.cornerRadius = 6
        ViewDecorator.homeCardShadow(for: self)
    }

}
