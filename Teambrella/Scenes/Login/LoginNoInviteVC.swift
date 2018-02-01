//
//  LoginNoInviteVC.swift
//  Teambrella
//
//  Created by Екатерина Рыжова on 10.07.17.

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

import MessageUI
import UIKit

final class LoginNoInviteVC: UIViewController {
    @IBOutlet private var centerLabel: UILabel!
    @IBOutlet private var subcontainer: UIView!
    @IBOutlet private var upperLabel: UILabel!
    @IBOutlet private var lowerLabel: UILabel!
    @IBOutlet private var tryDemoButton: UIButton!
    @IBOutlet private var supportButton: UIButton!
    @IBOutlet private var requestInviteButton: UIButton!
    
    var error: TeambrellaError?
    
    private var mailAddress: String = "support@teambrella.com"
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        subcontainer.layer.cornerRadius = 4
        centerLabel.text = "Login.LoginNoInviteVC.centerLabel".localized
        tryDemoButton.setTitle("Login.LoginNoInviteVC.tryDemoButton".localized, for: .normal)
        supportButton.setTitle("Login.LoginNoInviteVC.mailToSupport".localized, for: .normal)
        requestInviteButton.setTitle("Login.LoginNoInviteVC.requestInvitationButton".localized, for: .normal)
        
        guard let error = error else {
            inviteOnlySetup()
            return
        }
        
        switch error.kind {
        case .permissionDenied:
            permissionDeniedSetup()
        case .keyAlreadyRegistered:
            permissionDeniedSetup()
        case .noTeamsApplicationPending:
            pendingApplicationSetup()
        case .noTeamsApplicationApproved:
            almostReadySetup()
        case .noTeamsYet:
            inviteOnlySetup()
        default:
            inviteOnlySetup()
        }
    }
    
    // MARK: Callbacks
    
    @IBAction func tapTryDemoButton(_ sender: Any) {
        // unwind segue
    }
    
    @IBAction func tapSupport(_ sender: UIButton) {
        let emailTitle = " "
        let messageBody: String = ""
        let toRecipents = [mailAddress]
        let mc: MFMailComposeViewController = MFMailComposeViewController()
        mc.navigationBar.tintColor = .white
        mc.mailComposeDelegate = self
        mc.setSubject(emailTitle)
        mc.setMessageBody(messageBody, isHTML: false)
        mc.setToRecipients(toRecipents)
        
        present(mc, animated: true, completion: nil)
    }
    
    @IBAction func tapClose(_ sender: UIButton) {
        navigationController?.popViewController(animated: true)
    }
    
    @IBAction func tapRequestInvite(_ sender: UIButton) {
        guard let url = URL(string: "http://teambrella.com/join/team") else { return }
        
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    // MARK: Private
    
    private func inviteOnlySetup() {
        upperLabel.text = "Login.LoginNoInviteVC.upperLabel".localized
        lowerLabel.text = "Login.LoginNoInviteVC.lowerLabel".localized
        requestInviteButton.isHidden = false
    }
    
    private func permissionDeniedSetup() {
        upperLabel.text = "Login.LoginNoInviteVC.accessDenied.title".localized
        lowerLabel.text = "Login.LoginNoInviteVC.accessDenied.details".localized
        mailAddress = "help@teambrella.com"
        supportButton.isHidden = false
    }
    
    private func almostReadySetup() {
        upperLabel.text = "Login.LoginNoInviteVC.almostReady.title".localized
        lowerLabel.text = "Login.LoginNoInviteVC.almostReady.details".localized
        supportButton.isHidden = false
    }
    
    private func pendingApplicationSetup() {
        upperLabel.text = "Login.LoginNoInviteVC.pendingApplication.title".localized
        lowerLabel.text = "Login.LoginNoInviteVC.pendingApplication.details".localized
        supportButton.isHidden = false
    }
    
}

// MARK: MFMailComposeViewControllerDelegate
extension LoginNoInviteVC: MFMailComposeViewControllerDelegate {
    func mailComposeController(_ controller: MFMailComposeViewController,
                               didFinishWith result: MFMailComposeResult,
                               error: Error?) {
        switch result {
        case .cancelled:
            log("Mail cancelled", type: .info)
        case .saved:
            log("Mail saved", type: .info)
        case .sent:
            log("Mail sent", type: .info)
        case .failed:
            log("Mail sent failure", type: .info)
            error.map { log("error: \($0)", type: .error) }
        }
        
        controller.dismiss(animated: true, completion: nil)
        navigationController?.popViewController(animated: false)
    }
}
