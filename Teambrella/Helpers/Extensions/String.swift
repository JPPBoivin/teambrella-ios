//
// Created by Yaroslav Pasternak on 31.03.17.
// Copyright (c) 2017 Yaroslav Pasternak. All rights reserved.
//

import Foundation

extension String {
    var base58Data: Data {
        return BTCDataFromBase58(self) as Data
    }
    
    var base64data: Data? {
        return Data(base64Encoded: self)
    }
    
    var fromBase64: String? {
        guard let data = Data(base64Encoded: self) else {
            return nil
        }
        
        return String(data: data, encoding: .utf8)
    }
    
    var toBase64: String {
        return Data(self.utf8).base64EncodedString()
    }
    
    func split(by count: Int) -> [String] {
        return stride(from: 0, to: self.count, by: count).map { i -> String in
            let startIndex = self.index(self.startIndex, offsetBy: i)
            let endIndex = self.index(startIndex, offsetBy: count, limitedBy: self.endIndex) ?? self.endIndex
            return String(self[startIndex..<endIndex])
        }
    }
    
    var cSharpDate: Date? { return dateFromISO8601 }
    
    var dateFromISO8601: Date? {
        return Formatter.iso8601.date(from: self)   // "Mar 22, 2017, 10:22 AM"
    }
    
    var dateFromTeambrella: Date? {
        return Formatter.teambrella.date(from: self)
    }
    
    func attributedBoldString(nonBoldRange: NSRange?) -> NSAttributedString {
        let fontSize = UIFont.systemFontSize
        let attrs = [
            NSAttributedStringKey.font: UIFont.boldSystemFont(ofSize: fontSize),
            NSAttributedStringKey.foregroundColor: UIColor.black
        ]
        let nonBoldAttribute = [NSAttributedStringKey.font: UIFont.systemFont(ofSize: fontSize)]
        let attrStr = NSMutableAttributedString(string: self, attributes: attrs)
        if let range = nonBoldRange {
            attrStr.setAttributes(nonBoldAttribute, range: range)
        }
        return attrStr
    }
    
    static func formattedNumber(_ double: Double) -> String {
        guard double < 1000 else { return String(format: "%.0f", double) }
        
        let truncatedNumber = round(double * 100) / 100
        if fabs(truncatedNumber.truncatingRemainder(dividingBy: 1)) < 0.01 {
            if truncatedNumber == -0 {
                return "0"
            }
               return String(format: "%.0f", truncatedNumber)
        } else {
            return String(truncatedNumber)
        }
    }
    
    static func formattedNumber(_ float: Float) -> String {
        return formattedNumber(Double(float))
    }
    
    static func formattedNumber(_ cgFloat: CGFloat) -> String {
        return formattedNumber(Double(cgFloat))
    }
    
    static func truncatedNumber(_ double: Double) -> String {
        return String(Int(double + 0.5))
    }
    
    static func truncatedNumber(_ float: Float) -> String {
        return truncatedNumber(Double(float))
    }
    
    static func truncatedNumber(_ cgFloat: CGFloat) -> String {
        return truncatedNumber(Double(cgFloat))
    }
    
}
