//
//  TeammateCellBuilder.swift
//  Teambrella
//
//  Created by Yaroslav Pasternak on 02.06.17.
//  Copyright © 2017 Yaroslav Pasternak. All rights reserved.
//

import Kingfisher
import UIKit

struct TeammateCellBuilder {
    static func populate(cell: UICollectionViewCell, with teammate: ExtendedTeammate, delegate: Any? = nil) {
        if let cell = cell as? TeammateSummaryCell {
            populateSummary(cell: cell, with: teammate)
        } else if let cell = cell as? TeammateObjectCell {
          populateObject(cell: cell, with: teammate)
        } else if let cell = cell as? TeammateContactCell {
            populateContact(cell: cell, with: teammate, delegate: delegate)
        } else if let cell = cell as? DiscussionCell {
            populateDiscussion(cell: cell, with: teammate.topic, avatar: teammate.basic.avatar)
        } else if let cell = cell as? TeammateStatsCell {
            populateStats(cell: cell, with: teammate)
        } else if let cell = cell as? TeammateVoteCell, let delegate = delegate as? TeammateProfileVC {
           populateVote(cell: cell, with: teammate, delegate: delegate)
        } else if let cell = cell as? DiscussionCompactCell {
            populateCompactDiscussion(cell: cell, with: teammate.topic, avatar: teammate.basic.avatar)
        } else if let cell = cell as? MeCell {
            populateMeCell(cell: cell, with: teammate, delegate: delegate)
        }
    }
    
    private static func populateMeCell(cell: MeCell, with teammate: ExtendedTeammate, delegate: Any?) {
        cell.avatar.showAvatar(string: teammate.basic.avatar)
        cell.nameLabel.text = teammate.basic.name
        cell.infoLabel.text = teammate.basic.city
        if let vc = delegate as? TeammateProfileVC {
            cell.facebookButton.removeTarget(vc, action: nil, for: .allEvents)
            cell.facebookButton.addTarget(vc, action: #selector(TeammateProfileVC.tapFacebook), for: .touchUpInside)
            
            cell.twitterButton.removeTarget(vc, action: nil, for: .allEvents)
            cell.twitterButton.addTarget(vc, action: #selector(TeammateProfileVC.tapTwitter), for: .touchUpInside)
            
            cell.emailButton.removeTarget(vc, action: nil, for: .allEvents)
            cell.emailButton.addTarget(vc, action: #selector(TeammateProfileVC.tapEmail), for: .touchUpInside)
        }
    }
    
    private static func populateSummary(cell: TeammateSummaryCell, with teammate: ExtendedTeammate) {
        cell.title.text = teammate.basic.name
        let url = URL(string: service.server.avatarURLstring(for: teammate.basic.avatar))
        cell.avatarView.kf.setImage(with: url)
        if let left = cell.leftNumberView {
            left.titleLabel.text = "Team.TeammateCell.coversMe".localized
            let amount = teammate.basic.coversMeAmount
            left.amountLabel.text = ValueToTextConverter.textFor(amount: amount)
        }
        if let right = cell.rightNumberView {
            right.titleLabel.text = "Team.TeammateCell.coverThem".localized
            let amount = teammate.basic.iCoverThemAmount
            right.amountLabel.text = ValueToTextConverter.textFor(amount: amount)
        }
        
        cell.subtitle.text = teammate.basic.city
        if teammate.basic.isProxiedByMe {
            cell.infoLabel.isHidden = false
            cell.infoLabel.text = "Team.TeammateCell.youAreProxy_format_s".localized(teammate.basic.name)
        }
    }
    
    private static func populateVote(cell: TeammateVoteCell,
                                     with teammate: ExtendedTeammate,
                                     delegate: TeammateProfileVC) {
        if delegate.riskController == nil {
            let board = UIStoryboard(name: "Members", bundle: nil)
            if let vc = board.instantiateViewController(withIdentifier: "VotingRiskVC") as? VotingRiskVC {
            delegate.riskController = vc
            }
        }
        if let vc = delegate.riskController {
            vc.view.removeFromSuperview()
            vc.willMove(toParentViewController: delegate)
            cell.container.addSubview(vc.view)
            vc.view.frame = cell.container.bounds
            vc.view.autoresizingMask = [.flexibleHeight, .flexibleWidth]
            delegate.addChildViewController(vc)
            vc.didMove(toParentViewController: delegate)
        }
    }
    
    private static func populateObject(cell: TeammateObjectCell, with teammate: ExtendedTeammate) {
        cell.titleLabel.text = "Team.TeammateCell.object".localized
        cell.nameLabel.text = "\(teammate.object.model), \(teammate.object.year)"
        
        cell.statusLabel.text = "Team.TeammateCell.covered".localized
        cell.detailsLabel.text = "Team.TeammateCell.collisionDeductible".localized
        if let left = cell.numberBar.left {
            left.titleLabel.text = "Team.TeammateCell.limit".localized
            left.amountLabel.text = ValueToTextConverter.textFor(amount: teammate.object.claimLimit)
        }
        if let middle = cell.numberBar.middle {
            middle.titleLabel.text = "Team.Teammates.net".localized
            middle.amountLabel.text = ValueToTextConverter.textFor(amount: teammate.basic.totallyPaidAmount)
        }
        if let right = cell.numberBar.right {
            right.titleLabel.text = "Team.TeammateCell.riskFactor".localized
            right.amountLabel.text = ValueToTextConverter.textFor(amount: teammate.basic.risk)
            right.badgeLabel.text = "1x47xAVG"
            right.isBadgeVisible = true
            right.currencyLabel.text = nil
        }
        
        if let imageString = teammate.object.smallPhotos.first {
            cell.avatarView.showImage(string: imageString)
        }
        cell.button.setTitle("Team.TeammateCell.buttonTitle_format_i".localized(teammate.object.claimCount),
                             for: .normal)
    }
    
    private static func populateStats(cell: TeammateStatsCell, with teammate: ExtendedTeammate) {
        let stats = teammate.stats
        cell.headerLabel.text = "Team.TeammateCell.votingStats".localized
        if let left = cell.numberBar.left {
            left.titleLabel.text = "Team.TeammateCell.weight".localized
            left.amountLabel.text = ValueToTextConverter.textFor(amount: stats.weight)
        }
        if let right = cell.numberBar.right {
            right.titleLabel.text = "Team.TeammateCell.proxyRank".localized
            right.amountLabel.text = ValueToTextConverter.textFor(amount: stats.proxyRank)
            right.isBadgeVisible = false
        }
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
    }
    
    private static func populateDiscussion(cell: DiscussionCell, with stats: Topic, avatar: String) {
        cell.avatarView.kf.setImage(with: URL(string: service.server.avatarURLstring(for: avatar)))
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
        let urls = stats.topPosterAvatars.flatMap { URL(string: service.server.avatarURLstring(for: $0)) }
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
    
    private static func populateContact(cell: TeammateContactCell, with teammate: ExtendedTeammate, delegate: Any?) {
        guard let dataSource = delegate as? UITableViewDataSource else {
            fatalError("TeammateContactCell should have table view data source")
        }
        
        cell.headerLabel.text = "Team.TeammateCell.contact".localized
        let delegate = delegate as? UITableViewDelegate
        cell.tableView.delegate = delegate
        cell.tableView.dataSource = dataSource
        cell.tableView.reloadData()
    }
    
}
