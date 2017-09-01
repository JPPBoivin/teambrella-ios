//
//  ChatFooter.swift
//  Teambrella
//
//  Created by Yaroslav Pasternak on 30.08.17.
//  Copyright © 2017 Yaroslav Pasternak. All rights reserved.
//

import UIKit

class ChatFooter: UICollectionReusableView, XIBInitableCell {
    @IBOutlet var label: Label!
    @IBOutlet var isTypingView: IsTypingView!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    func hide(_ hide: Bool) {
        label.isHidden = hide
        isTypingView.isHidden = hide
    }
    
}
