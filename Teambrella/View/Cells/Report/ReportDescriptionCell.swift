//
//  ReportDescriptionCell.swift
//  Teambrella
//
//  Created by Yaroslav Pasternak on 24.06.17.
//  Copyright © 2017 Yaroslav Pasternak. All rights reserved.
//

import UIKit

class ReportDescriptionCell: UICollectionViewCell, XIBInitableCell {
    @IBOutlet var headerLabel: Label!
    @IBOutlet var textView: UITextView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

}
