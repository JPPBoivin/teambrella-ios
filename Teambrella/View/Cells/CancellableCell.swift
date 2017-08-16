//
//  CancellableCell.swift
//  Teambrella
//
//  Created by Екатерина Рыжова on 16.08.17.
//  Copyright © 2017 Yaroslav Pasternak. All rights reserved.
//

import UIKit

class CancellableCell: UICollectionViewCell, XIBInitableCell {
    @IBOutlet var closeButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        bringSubview(toFront: closeButton)
    }

}
