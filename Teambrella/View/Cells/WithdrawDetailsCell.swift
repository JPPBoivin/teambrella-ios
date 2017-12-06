//
/* Copyright(C) 2017 Teambrella, Inc.
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

class WithdrawDetailsCell: UICollectionViewCell, XIBInitableCell {
    @IBOutlet var backView: UIView!
    @IBOutlet var titleLabel: BlockHeaderLabel!
    @IBOutlet var infoButton: UIButton!
    @IBOutlet var toLabel: InfoLabel!
    @IBOutlet var cryptoAddressTextView: UITextView!
    @IBOutlet var qrButton: BorderedButton!
    @IBOutlet var amountLabel: InfoLabel!
    @IBOutlet var cryptoAmountTextField: UITextField!
    @IBOutlet var separator: UIView!
    @IBOutlet var submitButton: BorderedButton!
    @IBOutlet var placeholder: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        cryptoAddressTextView.layer.borderWidth = 0.5
        cryptoAddressTextView.layer.borderColor = #colorLiteral(red: 0.862745098, green: 0.862745098, blue: 0.862745098, alpha: 1)
        cryptoAddressTextView.layer.cornerRadius = 4
        placeholder.text = "Me.Wallet.Withdraw.Details.to.placeholder".localized
        cryptoAmountTextField.placeholder = "Me.Wallet.Withdraw.Details.amount.placeholder".localized
        ViewDecorator.shadow(for: self)
        cryptoAddressTextView.delegate = self
    }
}

// MARK: UITextViewDelegate
extension WithdrawDetailsCell: UITextViewDelegate {
    func textViewDidBeginEditing(_ textView: UITextView) {

    }
    
    func textViewDidChange(_ textView: UITextView) {
        if textView.text == nil || textView.text == "" {
            placeholder.isHidden = false
        } else {
            placeholder.isHidden = true
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text == nil || textView.text == "" {
            placeholder.isHidden = false
        }
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        return true
    }
}
