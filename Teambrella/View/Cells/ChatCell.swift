//
//  ChatCell.swift
//  Teambrella
//
//  Created by Yaroslav Pasternak on 19.06.17.

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

@IBDesignable
class ChatCell: UICollectionViewCell, XIBInitableCell {
    @IBOutlet var cloudView: UIView!
    @IBOutlet var stackView: UIStackView!
    @IBOutlet var dateLabel: Label!
    
    @IBOutlet var cloudLeadingConstraint: NSLayoutConstraint!
    @IBOutlet var cloudTrailingConstraint: NSLayoutConstraint!
    
    @IBOutlet var widthConstraint: NSLayoutConstraint!
    
    var isLeadingAlighed: Bool { return cloudLeadingConstraint.constant < 0.001 }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        contentView.translatesAutoresizingMaskIntoConstraints = false
        let screen = UIScreen.main.bounds.width
        widthConstraint.constant = screen - 16 * 2
    }
    
    func align(offset: CGFloat, toLeading: Bool) {
        cloudLeadingConstraint.constant = toLeading ? 0 : offset
        cloudTrailingConstraint.constant = toLeading ? offset : 0
        setNeedsLayout()
        setNeedsDisplay()
        layoutIfNeeded()
    }
    
    func clearAll() {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
//        setNeedsLayout()
//        setNeedsDisplay()
//        layoutIfNeeded()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        clearAll()
    }
    
    func add(text: String) {
        let label = ChatTextLabel(frame: CGRect(x: 0,
                                                y: 0,
                                                width: widthConstraint.constant,
                                                height: CGFloat.greatestFiniteMagnitude))
        label.font = UIFont.teambrella(size: 14)
        label.textColor = .charcoalGray
        label.numberOfLines = 0
        label.text = text
        label.sizeToFit()
        stackView.addArrangedSubview(label)
    }
    
    func add(image: String) {
        let imageView = UIImageView()
        imageView.addConstraint(NSLayoutConstraint(item: imageView,
                                                   attribute: .height,
                                                   relatedBy: .equal,
                                                   toItem: nil,
                                                   attribute: .notAnAttribute,
                                                   multiplier: 1,
                                                   constant: 150))
        let key = service.server.key
        let modifier = AnyModifier { request in
            var request = request
            request.addValue("\(key.timestamp)", forHTTPHeaderField: "t")
            request.addValue(key.publicKey, forHTTPHeaderField: "key")
            request.addValue(key.signature, forHTTPHeaderField: "sig")
            return request
        }
        imageView.kf.setImage(with: URL(string: image), options: [.requestModifier(modifier)])
        //imageView.kf.setImage(with: URL(string: image))
        imageView.contentMode = .scaleAspectFill
        imageView.layer.masksToBounds = true
        stackView.addArrangedSubview(imageView)
    }
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        let tailW: CGFloat = 10
        let tailH: CGFloat = 7
        let radius: CGFloat = 5
        if isLeadingAlighed {
            context.move(to: CGPoint(x: 0, y: cloudView.frame.height))
            context.addLine(to: CGPoint(x: tailW, y: cloudView.frame.height - tailH))
            context.addLine(to: CGPoint(x: tailW, y: radius))
            context.addQuadCurve(to: CGPoint(x: tailW + radius, y: 0),
                                 control: CGPoint(x: tailW, y: 0))
            context.addLine(to: CGPoint(x: cloudView.frame.maxX - radius, y: 0))
            context.addQuadCurve(to: CGPoint(x: cloudView.frame.maxX, y: radius),
                                 control: CGPoint(x: cloudView.frame.maxX, y: 0))
            context.addLine(to: CGPoint(x: cloudView.frame.maxX, y: cloudView.frame.maxY - radius))
            context.addQuadCurve(to: CGPoint(x: cloudView.frame.maxX - radius, y: cloudView.frame.maxY),
                                 control: CGPoint(x: cloudView.frame.maxX, y: cloudView.frame.maxY))
            context.closePath()
        } else {
            context.move(to: CGPoint(x: cloudView.frame.maxX, y: cloudView.frame.height))
            context.addLine(to: CGPoint(x: cloudView.frame.maxX - tailW, y: cloudView.frame.height - tailH))
            context.addLine(to: CGPoint(x: cloudView.frame.maxX - tailW, y: radius))
            context.addQuadCurve(to: CGPoint(x: cloudView.frame.maxX - tailW - radius, y: 0),
                                 control: CGPoint(x: cloudView.frame.maxX - tailW, y: 0))
            context.addLine(to: CGPoint(x: cloudView.frame.minX + radius, y: 0))
            context.addQuadCurve(to: CGPoint(x: cloudView.frame.minX, y: radius),
                                 control: CGPoint(x: cloudView.frame.minX, y: 0))
            context.addLine(to: CGPoint(x: cloudView.frame.minX, y: cloudView.frame.maxY - radius))
            context.addQuadCurve(to: CGPoint(x: cloudView.frame.minX + radius, y: cloudView.frame.maxY),
                                 control: CGPoint(x: cloudView.frame.minX, y: cloudView.frame.maxY))
            context.closePath()
        }
        context.setStrokeColor(UIColor.lightBlueGray.cgColor)
        context.setLineWidth(1)
        context.setFillColor(UIColor.veryLightBlue.cgColor)
        context.drawPath(using: .fillStroke)
    }
    
    //    override var intrinsicContentSize: CGSize {
    //        var height: CGFloat = 0
    //
    //    }
    
}
