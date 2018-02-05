//
//  ClaimCellBuilder.swift
//  Teambrella
//
//  Created by Yaroslav Pasternak on 07.06.17.

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

struct ClaimCellBuilder {
    static func populate(cell: UICollectionViewCell, with claim: ClaimEntityLarge, delegate: ClaimVC) {
        if let cell = cell as? ImageGalleryCell {
            populateImageGallery(cell: cell, with: claim)
            addObserversToImageGallery(cell: cell, delegate: delegate)
        } else if let cell = cell as? ClaimVoteCell {
            populateClaimVote(cell: cell, with: claim, delegate: delegate)
            addObserversToClaimVote(cell: cell, delegate: delegate)
        } else if let cell = cell as? ClaimDetailsCell {
            populateClaimDetails(cell: cell, with: claim)
        } else if let cell = cell as? ClaimOptionsCell {
            populateClaimOptions(cell: cell, with: claim, delegate: delegate)
        }
    }
    
    static func addObserversToImageGallery(cell: ImageGalleryCell, delegate: ClaimVC) {
        if cell.tapGalleryGesture == nil {
            let gestureRecognizer = UITapGestureRecognizer(target: delegate, action: #selector(ClaimVC.tapGallery))
            cell.tapGalleryGesture = gestureRecognizer
            cell.slideshow.addGestureRecognizer(gestureRecognizer)
        }
    }
    
    static func addObserversToClaimVote(cell: ClaimVoteCell, delegate: ClaimVC) {
        cell.slider.removeTarget(delegate, action: nil, for: .valueChanged)
        cell.slider.addTarget(delegate, action: #selector(ClaimVC.sliderMoved), for: .valueChanged)
    }
    
    static func populateImageGallery(cell: ImageGalleryCell, with claim: ClaimEntityLarge) {
        let imageURLStrings = claim.largePhotos.map { URLBuilder().urlString(string: $0) }
        log("\(imageURLStrings)", type: .info)
        service.server.updateTimestamp { timestamp, error in
            let key =  Key(base58String: KeyStorage.shared.privateKey, timestamp: timestamp)
            let modifier = AnyModifier { request in
                var request = request
                request.addValue("\(key.timestamp)", forHTTPHeaderField: "t")
                request.addValue(key.publicKey, forHTTPHeaderField: "key")
                request.addValue(key.signature, forHTTPHeaderField: "sig")
                return request
            }
            cell.setupGallery(with: imageURLStrings, options: [.requestModifier(modifier)])
        }
        cell.avatarView.kf.setImage(with: URL(string: URLBuilder().avatarURLstring(for: claim.avatar)))
        cell.titleLabel.text = "Team.ClaimCell.claimID_format".localized(claim.id)//"Claim \(claim.id)"
        cell.textLabel.text = claim.originalPostText
        cell.unreadCountLabel.text = "\(claim.unreadCount)"
        cell.unreadCountLabel.isHidden = claim.unreadCount <= 0
        let dateProcessor = DateProcessor()
        cell.timeLabel.text = dateProcessor.stringFromNow(minutes: claim.minutesinceLastPost)
        ViewDecorator.shadow(for: cell, opacity: 0.1, radius: 8)
    }
    
    static func populateClaimVote(cell: ClaimVoteCell, with claim: ClaimEntityLarge, delegate: ClaimVC) {
        cell.titleLabel.text = "Team.ClaimCell.voting".localized.uppercased()
        let dateProcessor = DateProcessor()
        cell.remainingDaysLabel.text = "Team.Claims.ClaimVC.VotingCell.endsTitle".localized.uppercased()
            + dateProcessor.stringFromNow(minutes: -claim.minutesRemaining).uppercased()

        cell.pieChart.setupWith(remainingMinutes: claim.minutesRemaining)
        
        if let myVote = claim.myVote {
            cell.yourVotePercentValue.text = String.truncatedNumber(myVote.percentage)
            cell.yourVoteAmount.text = String.truncatedNumber(myVote.fiat(from: claim.claimAmount).value)
            cell.slider.setValue(Float(myVote.value), animated: true)
        } else if let proxyVote = claim.proxyVote {
            cell.yourVotePercentValue.text = String.truncatedNumber(proxyVote.percentage)
            cell.yourVoteAmount.text = String.truncatedNumber(proxyVote.fiat(from: claim.claimAmount).value)
            cell.slider.setValue(Float(proxyVote.value), animated: true)
            if let proxyAvatar = claim.proxyAvatar {
                cell.proxyAvatar.kf.setImage(with: URL(string: URLBuilder().avatarURLstring(for: proxyAvatar)))
                cell.byProxyLabel.text = "Team.ClaimCell.byProxy".localized.uppercased()
            }
        } else {
            cell.yourVotePercentValue.text = ". . ."
            cell.isYourVoteHidden = true
            cell.slider.setValue(cell.slider.minimumValue, animated: true)
        }
        cell.resetButton.isHidden = claim.myVote == nil
        cell.proxyAvatar.isHidden = claim.proxyAvatar == nil || claim.myVote != nil
        cell.byProxyLabel.isHidden = claim.proxyVote == nil || claim.myVote != nil
        
        cell.yourVoteLabel.text = "Team.ClaimCell.yourVote".localized.uppercased()
        cell.yourVotePercentValue.alpha = 1
        cell.yourVoteAmount.alpha = 1
        cell.yourVoteCurrency.text = service.session?.currentTeam?.currency
        
        cell.teamVoteLabel.text = "Team.ClaimCell.teamVote".localized.uppercased()
        cell.teamVotePercentValue.text = String.truncatedNumber(claim.ratioVoted.percentage)
        cell.teamVoteAmount.text = String.truncatedNumber(claim.ratioVoted.fiat(from: claim.claimAmount).value)
        cell.teamVoteCurrency.text = service.session?.currentTeam?.currency
        
        cell.resetButton.setTitle("Team.ClaimCell.resetVote".localized, for: .normal)
        cell.resetButton.removeTarget(delegate, action: nil, for: .allEvents)
        cell.resetButton.addTarget(delegate, action: #selector(ClaimVC.tapResetVote), for: .touchUpInside)
        
        let avatars = claim.otherAvatars.flatMap { URL(string: URLBuilder().avatarURLstring(for: $0)) }
        let maxAvatarsStackCount = 4
        let otherVotersCount = claim.otherCount - maxAvatarsStackCount + 1
        let label: String?  =  otherVotersCount > 0 ? "+\(otherVotersCount)" : nil
        cell.avatarsStack.set(images: avatars, label: label, max: maxAvatarsStackCount)
        
        cell.othersVotedButton.removeTarget(delegate, action: nil, for: .allEvents)
        cell.othersVotedButton.addTarget(delegate, action: #selector(ClaimVC.tapOthersVoted), for: .touchUpInside)
        ViewDecorator.shadow(for: cell, opacity: 0.1, radius: 8)
    }
    
    static func populateClaimDetails(cell: ClaimDetailsCell, with claim: ClaimEntityLarge) {
        cell.titleLabel.text = "Team.ClaimCell.claimDetails".localized

        cell.coverageLabel.text = "Team.ClaimCell.coverage".localized
        let coverage = "\(Int((claim.coverage * 100).rounded()))"
        cell.coverageValueLabel.text = coverage + "%"
        
        cell.incidentDateLabel.text = "Team.ClaimCell.incidentDate".localized
        claim.incidentDate.map { cell.incidentDateValueLabel.text = DateFormatter.teambrellaShort.string(from: $0) }
        ViewDecorator.shadow(for: cell, opacity: 0.1, radius: 8)

        cell.claimAmountLabel.text = "Team.ClaimCell.claimAmount".localized
        let claimAmount = String(format: "%.2f", claim.claimAmount.value)
        cell.deductibleLabel.text = "Team.ClaimCell.deductible".localized
        let deductible = String(format: "%.2f", claim.deductible)
        cell.estimatedExpencesLabel.text = "Team.ClaimCell.estimatedExpences".localized
        let estimatedExpenses = String(format: "%.2f", claim.estimatedExpences)
        guard let currency = service.session?.currentTeam?.currencySymbol else { return }

        cell.claimAmountValueLabel.text = currency + claimAmount
        cell.deductibleValueLabel.text = currency + deductible
        cell.estimatedExpensesValueLabel.text = currency + estimatedExpenses
        
    }
    
    static func populateClaimOptions(cell: ClaimOptionsCell, with claim: ClaimEntityLarge, delegate: ClaimVC) {
        cell.allVotesLabel.text = "Team.TeammateCell.allVotes".localized
        cell.tapAllVotesRecognizer.removeTarget(delegate, action: nil)
        cell.tapAllVotesRecognizer.addTarget(delegate, action: #selector(ClaimVC.tapOthersVoted))
        cell.cashFlowLabel.text = "Team.TeammateCell.cashFlow".localized
        cell.transactionsLabel.text = "Team.TeammateCell.transactions".localized
        cell.tapTransactionsRecognizer.removeTarget(delegate, action: nil)
        cell.tapTransactionsRecognizer.addTarget(delegate, action: #selector(ClaimVC.tapTransactions))
        ViewDecorator.shadow(for: cell, opacity: 0.1, radius: 8)
    }
    
}
