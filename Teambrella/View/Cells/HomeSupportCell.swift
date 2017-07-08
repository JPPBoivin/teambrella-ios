//
//  HomeSupportCell.swift
//  Teambrella
//
//  Created by Екатерина Рыжова on 07.07.17.
//  Copyright © 2017 Yaroslav Pasternak. All rights reserved.
//

import UIKit

class HomeSupportCell: UICollectionViewCell, XIBInitableCell {
    @IBOutlet var backView: UIView!
    @IBOutlet var imageView: UIImageView!
    @IBOutlet var headerLabel: UILabel!
    @IBOutlet var centerLabel: UILabel!
    @IBOutlet var bottomLabel: UILabel!
    @IBOutlet var button: BorderedButton!
    @IBOutlet var onlineIndicator: UIView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        CellDecorator.roundedEdges(for: self)
        CellDecorator.shadow(for: self)
    }
}
