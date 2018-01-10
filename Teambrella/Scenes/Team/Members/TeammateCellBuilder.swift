//
//  TeammateCellBuilder.swift
//  Teambrella
//
//  Created by Yaroslav Pasternak on 02.06.17.

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

struct TeammateCellBuilder {
    static func populate(cell: UICollectionViewCell,
                         with teammate: TeammateLarge,
                         controller: TeammateProfileVC) {
        switch cell {
        case let cell as TeammateObjectCell:
            populateObject(cell: cell, with: teammate, controller: controller)
        case let cell as TeammateContactCell:
            populateContact(cell: cell, with: teammate, controller: controller)
        case let cell as DiscussionCell:
            populateDiscussion(cell: cell, with: teammate.topic, avatar: teammate.basic.avatar)
        case let cell as TeammateStatsCell:
            populateStats(cell: cell, with: teammate, controller: controller)
        case let cell as VotingRiskCell:
            populateVote(cell: cell, with: teammate, controller: controller)
        case let cell as DiscussionCompactCell:
            populateCompactDiscussion(cell: cell, with: teammate.topic, avatar: teammate.basic.avatar)
        case let cell as MeCell:
            populateMeCell(cell: cell, with: teammate, controller: controller)
        default:
            break
        }
    }
    
    private static func populateMeCell(cell: MeCell,
                                       with teammate: TeammateLarge,
                                       controller: TeammateProfileVC?) {
        cell.avatar.showAvatar(string: teammate.basic.avatar)
        cell.nameLabel.text = teammate.basic.name.entire
        cell.infoLabel.text = teammate.basic.city.uppercased()
    }
    
    private static func populateSummary(cell: TeammateSummaryCell,
                                        with teammate: TeammateLarge,
                                        controller: UIViewController) {
        /*
         cell.title.text = teammate.basic.name.entire
         //let url = URL(string: service.server.avatarURLstring(for: teammate.basic.avatar))
         cell.avatarView.present(avatarString: teammate.basic.avatar)
         cell.avatarView.onTap = { [weak controller] view in
         view.fullscreen(in: controller, imageStrings: nil)
         }
         //cell.avatarView.kf.setImage(with: url)
         if let left = cell.leftNumberView {
         left.titleLabel.text = "Team.TeammateCell.coversMe".localized
         let amount = teammate.basic.coversMeAmount
         left.amountLabel.text = ValueToTextConverter.textFor(amount: amount)
         left.currencyLabel.text = service.currencyName
         }
         if let right = cell.rightNumberView {
         right.titleLabel.text = "Team.TeammateCell.coverThem".localized
         let amount = teammate.basic.iCoverThemAmount
         right.amountLabel.text = ValueToTextConverter.textFor(amount: amount)
         right.currencyLabel.text = service.currencyName
         }
         
         cell.subtitle.text = teammate.basic.city.uppercased()
         if teammate.basic.isProxiedByMe, let myID = service.session?.currentUserID, teammate.basic.id != myID {
         cell.infoLabel.isHidden = false
         cell.infoLabel.text = "Team.TeammateCell.youAreProxy_format_s".localized(teammate.basic.name.entire)
         }
         */
    }
    
    private static func setVote(votingCell: VotingRiskCell, voting: TeammateVotingInfo, controller: TeammateProfileVC) {
        let label: String? = voting.votersCount > 0 ? String(voting.votersCount) : nil
        votingCell.teammatesAvatarStack.setAvatars(images: voting.votersAvatars, label: label, max: nil)
        if let risk = voting.riskVoted {
            votingCell.teamVoteValueLabel.text =  String.formattedNumber(risk)
            votingCell.showTeamNoVote(risk: risk)
        } else {
            votingCell.teamVoteValueLabel.text = "..."
            votingCell.showTeamNoVote(risk: nil)
        }
        
        if let myVote = voting.myVote {
            votingCell.layoutIfNeeded()
            votingCell.yourVoteValueLabel.text = String(format: "%.2f", myVote)
            let offset = controller.offsetFrom(risk: myVote, maxValue: votingCell.maxValue)
            votingCell.scrollTo(offset: offset, silently: true)
            votingCell.showYourNoVote(risk: myVote)
        } else {
            controller.resetVote(cell: votingCell)
            votingCell.showYourNoVote(risk: nil)
        }
        let currentChosenRisk = controller.riskFrom(offset: votingCell.collectionView.contentOffset.x,
                                                    maxValue: votingCell.maxValue)
        controller.updateAverages(cell: votingCell,
                                  risk: currentChosenRisk)
        
        let timeString = DateProcessor().stringFromNow(minutes: -voting.remainingMinutes).uppercased()
        votingCell.timeLabel.text = "Team.VotingRiskVC.ends".localized(timeString)
    }
    
    private static func populateVote(cell: VotingRiskCell,
                                     with teammate: TeammateLarge,
                                     controller: TeammateProfileVC) {
        if let riskScale = teammate.riskScale, controller.isRiskScaleUpdateNeeded == true {
            cell.updateWithRiskScale(riskScale: riskScale)
            controller.isRiskScaleUpdateNeeded = false
        }
        cell.setNeedsLayout()
        cell.layoutIfNeeded()
        cell.middleAvatar.showAvatar(string: teammate.basic.avatar)
        
        if SimpleStorage().string(forKey: .swipeHelperWasShown) != nil {
            cell.swipeToVoteView.isHidden = true
        } else {
            cell.swipeToVoteView.isHidden = false
            cell.swipeToVoteView.onInteraction = {
                cell.swipeToVoteView.removeFromSuperview()
                SimpleStorage().store(bool: true, forKey: .swipeHelperWasShown)
            }
        }
        
        if let voting = teammate.voting {
            setVote(votingCell: cell, voting: voting, controller: controller)
        }
        cell.delegate = controller
    }
    
    private static func populateObject(cell: TeammateObjectCell,
                                       with teammate: TeammateLarge,
                                       controller: TeammateProfileVC) {
        let type: CoverageType = service.session?.currentTeam?.coverageType ?? .other
        let owner: String
        if let me = service.session?.currentUserID, me == teammate.basic.id {
            owner = "Main.my".localized
        } else {
            owner = teammate.basic.gender == .male ? "Main.his".localized : "Main.her".localized
        }
        cell.titleLabel.text = owner.uppercased() + " " + type.localizedCoverageObject
        cell.nameLabel.text = "\(teammate.object.model), \(teammate.object.year)"
        
        cell.statusLabel.text = "Team.TeammateCell.covered".localized
        cell.detailsLabel.text = teammate.coverageType.localizedCoverageType
        if let left = cell.numberBar.left {
            left.titleLabel.text = "Team.TeammateCell.limit".localized
            left.amountLabel.text = ValueToTextConverter.textFor(amount: teammate.object.claimLimit)
            left.currencyLabel.text = service.currencyName
        }
        if let middle = cell.numberBar.middle {
            middle.titleLabel.text = "Team.Teammates.net".localized
            middle.amountLabel.text = ValueToTextConverter.textFor(amount: teammate.basic.totallyPaidAmount)
            middle.currencyLabel.text = service.currencyName
        }
        if let right = cell.numberBar.right {
            right.titleLabel.text = "Team.TeammateCell.riskFactor".localized
            right.amountLabel.text = ValueToTextConverter.textFor(amount: teammate.basic.risk)
            let avg = String.truncatedNumber(teammate.basic.averageRisk)
            right.badgeLabel.text = avg + " AVG"
            right.isBadgeVisible = true
            right.currencyLabel.text = nil
        }
        
        if let imageString = teammate.object.smallPhotos.first {
            cell.avatarView.present(imageString: imageString)
            cell.avatarView.onTap = { [weak controller] view in
                guard let vc = controller else { return }
                
                view.fullscreen(in: vc, imageStrings: nil)
            }
            //cell.avatarView.showImage(string: imageString)
        }
        cell.button.setTitle("Team.TeammateCell.buttonTitle_format_i".localized(teammate.object.claimCount),
                             for: .normal)
        
        let hasClaims = teammate.object.claimCount > 0
        cell.button.isEnabled = hasClaims ? true : false
        
        cell.button.removeTarget(nil, action: nil, for: .allEvents)
        cell.button.addTarget(controller, action: #selector(TeammateProfileVC.showClaims), for: .touchUpInside)
    }
    
    private static func populateStats(cell: TeammateStatsCell,
                                      with teammate: TeammateLarge,
                                      controller: TeammateProfileVC) {
        let stats = teammate.stats
        cell.headerLabel.text = "Team.TeammateCell.votingStats".localized
        
        cell.weightTitleLabel.text = "Team.TeammateCell.weight".localized
        cell.weightValueLabel.text = ValueToTextConverter.textFor(amount: stats.weight)
        
        cell.proxyRankTitleLabel.text = "Team.TeammateCell.proxyRank".localized
        cell.proxyRankValueLabel.text = ValueToTextConverter.textFor(amount: stats.proxyRank)
        /*
         if let left = cell.numberBar.left {
         left.amountLabel.textAlignment = .center
         left.titleLabel.text = "Team.TeammateCell.weight".localized
         left.amountLabel.text = ValueToTextConverter.textFor(amount: stats.weight)
         left.currencyLabel.text = nil
         }
         if let right = cell.numberBar.right {
         right.amountLabel.textAlignment = .center
         right.titleLabel.text = "Team.TeammateCell.proxyRank".localized
         right.amountLabel.text = ValueToTextConverter.textFor(amount: stats.proxyRank)
         right.isBadgeVisible = false
         right.currencyLabel.text = nil
         }
         */
        cell.decisionsLabel.text = "Team.TeammateCell.decisions".localized
        cell.decisionsBar.autoSet(value: stats.decisionFrequency)
        cell.decisionsBar.rightText = ValueToTextConverter.decisionsText(from: stats.decisionFrequency).uppercased()
        cell.discussionsLabel.text = "Team.TeammateCell.discussions".localized
        cell.discussionsBar.autoSet(value: stats.discussionFrequency)
        cell.discussionsBar.rightText = ValueToTextConverter
            .discussionsText(from: stats.discussionFrequency).uppercased()
        cell.frequencyLabel.text = "Team.TeammateCell.votingFrequency".localized
        cell.frequencyBar.autoSet(value: stats.votingFrequency)
        cell.frequencyBar.rightText = ValueToTextConverter.frequencyText(from: stats.votingFrequency).uppercased()
        
        let buttonTitle = teammate.basic.isMyProxy
            ? "Team.TeammateCell.removeFromMyProxyVoters".localized
            : "Team.TeammateCell.addToMyProxyVoters".localized
        cell.addButton.setTitle(buttonTitle, for: .normal)
        if let me = service.session?.currentUserID, me == teammate.basic.id {
            cell.addButton.isHidden = true
        } else {
            cell.addButton.isHidden = false
        }
        
        cell.addButton.removeTarget(controller, action: nil, for: .allEvents)
        cell.addButton.addTarget(self, action: #selector(TeammateProfileVC.tapAddToProxy), for: .touchUpInside)
    }
    
    private static func populateDiscussion(cell: DiscussionCell, with stats: Topic, avatar: String) {
        cell.avatarView.kf.setImage(with: URL(string: URLBuilder().avatarURLstring(for: avatar)))
        cell.titleLabel.text = "Team.TeammateCell.applicationDiscussion".localized
        switch stats.minutesSinceLastPost {
        case 0:
            cell.timeLabel.text = "Team.TeammateCell.timeLabel.justNow".localized
        case 1..<60:
            cell.timeLabel.text = "Team.TeammateCell.timeLabel.minutes_format_i".localized(stats.minutesSinceLastPost)
        case 60...(60 * 24):
            let hours = stats.minutesSinceLastPost / 60
            cell.timeLabel.text = "Team.TeammateCell.timeLabel.hours_format_i".localized(hours)
        default:
            cell.timeLabel.text = "Team.TeammateCell.timeLabel.longAgo".localized
        }
        let message = TextAdapter().parsedHTML(string: stats.originalPostText)
        cell.textLabel.text = message
        cell.unreadCountView.text = String(stats.unreadCount)
        cell.unreadCountView.isHidden = stats.unreadCount == 0
        let urls = stats.topPosterAvatars.flatMap { URL(string: URLBuilder().avatarURLstring(for: $0)) }
        let morePersons = stats.posterCount - urls.count
        let text: String? = morePersons > 0 ? "+\(morePersons)" : nil
        cell.teammatesAvatarStack.set(images: urls, label: text, max: 4)
        cell.discussionLabel.text = "Team.TeammateCell.discussion".localized
    }
    
    private static func populateCompactDiscussion(cell: DiscussionCompactCell, with stats: Topic, avatar: String) {
        cell.avatarView.showAvatar(string: avatar)
        cell.titleLabel.text = "Team.TeammateCell.applicationDiscussion".localized
        cell.timeLabel.text = DateProcessor().stringFromNow(seconds: stats.minutesSinceLastPost).uppercased()
        let message = TextAdapter().parsedHTML(string: stats.originalPostText)
        cell.textLabel.text = message
        cell.unreadCountView.text = String(stats.unreadCount)
        cell.unreadCountView.isHidden = stats.unreadCount == 0
    }
    
    private static func populateContact(cell: TeammateContactCell,
                                        with teammate: TeammateLarge,
                                        controller: TeammateProfileVC) {
        cell.headerLabel.text = "Team.TeammateCell.contact".localized
        cell.tableView.delegate = controller
        cell.tableView.dataSource = controller
        cell.tableView.reloadData()
    }
    
}
