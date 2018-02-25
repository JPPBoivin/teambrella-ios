//
//  RoundImagesStack.swift
//  Teambrella
//
//  Created by Yaroslav Pasternak on 03.05.17.

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

import Kingfisher
import UIKit

/**
 Shows a horizontal stack of round images
 */
class RoundImagesStack: UIView {
    private var views: [UIView] = []
    /// width of the limb around image view (image view changes it's size to fit into the limb)
    var limbWidth: CGFloat = 1
    var limbColor: UIColor = .white
    /// max images that could be contained in the view
    var maxImages: Int = 1
    var isEmpty: Bool {
        return views.isEmpty
    }

    func  setAvatars(_ avatars: [Avatar], label: String? = nil, max: Int? = nil) {
        let images = avatars.map { URLBuilder().avatarURLstring(for: $0.string) }
        let urls = images.flatMap { URL(string: $0) }
        set(images: urls, label: label, max: max)
    }

    func  setAvatars(images: [String], label: String? = nil, max: Int? = nil) {
        let images = images.map { URLBuilder().avatarURLstring(for: $0) }
        let urls = images.flatMap { URL(string: $0) }
        set(images: urls, label: label, max: max)
    }
    
    /// Populate stack with images
    ///
    /// - Parameters:
    ///   - images: URLs of the images
    ///   - label: optional label to be shown as last view
    ///   - max: maximum quantity of images that can be added to this stack. If actual count of images is less than the
    ///          maximum count, images will be set to the left
    func  set(images: [URL], label: String? = nil, max: Int? = nil) {
        if let max = max {
            self.maxImages = max
        } else {
            self.maxImages = label == nil ? images.count : images.count + 1
        }
        views.forEach {
            $0.removeFromSuperview()
        }
        views.removeAll()
        images.forEach { url in
            let view = RoundImageView()
            view.showAvatar(url: url)
            self.add(view: view)
        }
        if let label = label {
            let lastView = Label()
            lastView.text = "+1000"//label
            add(view: lastView)
        }
    }
    
    func add(view: UIView) {
        if views.count < maxImages {
            views.append(view)
        } else {
            views.popLast().map { $0.removeFromSuperview() }
            views.append(view)
        }
        if let view = view as? RoundImageView {
            view.limbColor = limbColor
            view.inset = limbWidth
        } else if let view = view as? Label {
            view.cornerRadius = 10
            view.backgroundColor = .paleGray
            view.textColor = #colorLiteral(red: 0.4, green: 0.4549019608, blue: 0.4901960784, alpha: 1)
            view.tintColor = limbColor
//            view.layer.borderWidth = limbWidth
            view.font = UIFont.teambrellaBold(size: 10)
            view.textAlignment = .center
        }
        addSubview(view)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        translatesAutoresizingMaskIntoConstraints = true
        guard !views.isEmpty else { return }
        
        let side = bounds.height
        //let quantity = CGFloat(maxImages)
        //let interval: CGFloat = quantity > 1 ? (bounds.width - side) / (quantity - 1) : 0
        let interval = side * 0.8
        let size = CGSize(width: side, height: side)
        for (idx, view) in views.enumerated() {
            view.frame.origin = CGPoint(x: CGFloat(idx) * interval, y: 0)
            view.frame.size = size
        }
        frame.size.width = views.last?.frame.maxX ?? 0
    }
    
}
