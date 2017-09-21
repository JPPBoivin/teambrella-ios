//
//  TeammateProfileVC.swift
//  Teambrella
//
//  Created by Yaroslav Pasternak on 30.05.17.

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
import PKHUD
import UIKit
import XLPagerTabStrip

class TeammateProfileVC: UIViewController, Routable {
    struct Constant {
        static let socialCellHeight: CGFloat = 68
    }
    
    static var storyboardName: String = "Team"
    
    var teammate: TeammateEntity?
    var teammateID: String?
    
    var dataSource: TeammateProfileDataSource!
    var linearFunction: PiecewiseFunction?
    var chosenRisk: Double?
    
    var isRiskScaleUpdateNeeded = true
    
    @IBOutlet var collectionView: UICollectionView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let teammate = teammate {
            dataSource = TeammateProfileDataSource(id: teammate.userID, isVoting: teammate.isVoting, isMe: false)
            addGradientNavBar()
        } else if let teammateID = teammateID {
            dataSource = TeammateProfileDataSource(id: teammateID, isVoting: false, isMe: false)
            addGradientNavBar()
        } else if let myID = service.session?.currentUserID {
            dataSource = TeammateProfileDataSource(id: myID, isVoting: false, isMe: true)
        } else {
            fatalError("No valid info about teammate")
        }
        
        registerCells()
        HUD.show(.progress, onView: view)
        dataSource.loadEntireTeammate { [weak self] extendedTeammate in
            HUD.hide()
            self?.teammate?.extended = extendedTeammate
            self?.prepareLinearFunction()
            self?.setTitle()
            self?.collectionView.reloadData()
        }
        if let flow = collectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            flow.sectionHeadersPinToVisibleBounds = true
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setTitle()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        title = "Main.back".localized
    }
    
    func setTitle() {
        title = dataSource.extendedTeammate?.basic.name
    }
    
    func prepareLinearFunction() {
        guard let risk = dataSource.extendedTeammate?.riskScale else { return }
        
        let function = PiecewiseFunction((0.2, risk.coversIfMin), (1, risk.coversIf1), (5, risk.coversIfMax))
        linearFunction = function
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @objc
    func showClaims(sender: UIButton) {
        if let claimCount = dataSource.extendedTeammate?.object.claimCount,
            claimCount == 1,
            let claimID = dataSource.extendedTeammate?.object.singleClaimID {
            service.router.presentClaim(claimID: claimID)
        } else {
            service.router.presentClaims(teammate: teammate)
        }
    }
    
    func registerCells() {
        collectionView.register(DiscussionCell.nib, forCellWithReuseIdentifier: TeammateProfileCellType.dialog.rawValue)
        collectionView.register(MeCell.nib, forCellWithReuseIdentifier: TeammateProfileCellType.me.rawValue)
        collectionView.register(VotingRiskCell.nib, forCellWithReuseIdentifier: TeammateProfileCellType.voting.rawValue)
        collectionView.register(CompactUserInfoHeader.nib,
                                forSupplementaryViewOfKind: UICollectionElementKindSectionHeader,
                                withReuseIdentifier: CompactUserInfoHeader.cellID)
    }
    
    func updateAmounts(with risk: Double) {
        chosenRisk = risk
        let kind = UICollectionElementKindSectionHeader
        guard let view = collectionView.visibleSupplementaryViews(ofKind: kind).first as? CompactUserInfoHeader else {
            return
        }
        guard let myRisk = dataSource.extendedTeammate?.riskScale?.myRisk,
            let theirRisk = dataSource.extendedTeammate?.basic.risk else { return }
        
        if let theirAmount = linearFunction?.value(at: risk / theirRisk * myRisk) {
            view.leftNumberView.amountLabel.text = String(format: "%.2f", theirAmount)
        }
        if let myAmount = linearFunction?.value(at: risk / myRisk * theirRisk) {
            view.rightNumberView.amountLabel.text = String(format: "%.2f", myAmount)
        }
    }
    
    @objc
    func tapFacebook() {
        DeveloperTools.notSupportedAlert(in: self)
    }
    
    @objc
    func tapTwitter() {
        DeveloperTools.notSupportedAlert(in: self)
    }
    
    @objc
    func tapEmail() {
        DeveloperTools.notSupportedAlert(in: self)
    }
    
    @objc
    func tapAddToProxy(sender: UIButton) {
        dataSource.addToProxy { [weak self] in
            guard let me = self else { return }
            
            let cells = me.collectionView.visibleCells
            let statCells = cells.flatMap { $0 as? TeammateStatsCell }
            if let cell = statCells.first {
                let title = me.dataSource.isMyProxy
                    ? "Team.TeammateCell.removeFromMyProxyVoters".localized
                    : "Team.TeammateCell.addToMyProxyVoters".localized
                cell.addButton.setTitle(title, for: .normal)
            }
        }
    }
    
    @objc
    func tapResetVote(sender: UIButton) {
        guard let cell = votingRiskCell else { return }
        guard let userID = teammate?.id else { return }
        
        cell.yourVoteValueLabel.alpha = 0.5
        //sender.isEnabled = false
        dataSource.sendRisk(userID: userID, risk: nil) { [weak self, weak cell] json in
            guard let `self` = self else { return }
            guard let cell = cell else { return }
            
            self.teammate?.updateWithVote(json: json)
            cell.yourVoteValueLabel.alpha = 1
            cell.isProxyHidden = false
            self.resetVote(cell: cell)
        }
    }
    
    @objc
    func tapShowOtherVoters(sender: UIButton) {
        
    }
    
    func riskFrom(offset: CGFloat, maxValue: CGFloat) -> Double {
        return min(Double(pow(25, offset / maxValue) / 5), 5)
    }
    
    func offsetFrom(risk: Double, maxValue: CGFloat) -> CGFloat {
        return CGFloat(log(base: 25.0, value: risk * 5.0)) * maxValue
    }
    
    private func resetVote(cell: VotingRiskCell) {
        let vote = teammate?.extended?.voting?.myVote
        let proxyAvatar = teammate?.extended?.voting?.proxyAvatar
        let proxyName = teammate?.extended?.voting?.proxyName
        if let vote = vote,
            let proxyAvatar = proxyAvatar,
            let proxyName = proxyName {
            cell.isProxyHidden = false
            cell.proxyAvatarView.showAvatar(string: proxyAvatar)
            cell.proxyNameLabel.text = proxyName.uppercased()
            let offset = offsetFrom(risk: vote, maxValue: cell.maxValue)
            cell.scrollTo(offset: offset, silently: true)
        } else {
            cell.isProxyHidden = true
            cell.yourVoteValueLabel.text = "..."
            cell.scrollToAverage(silently: true)
        }
    }
    
    var votingRiskCell: VotingRiskCell? {
        let visibleCells = collectionView.visibleCells
        return visibleCells.filter { $0 is VotingRiskCell }.first as? VotingRiskCell
    }
    
}

// MARK: UICollectionViewDataSource
extension TeammateProfileVC: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return dataSource.sections
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.rows(in: section)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let identifier = dataSource.type(for: indexPath).rawValue
        return collectionView.dequeueReusableCell(withReuseIdentifier: identifier, for: indexPath)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        viewForSupplementaryElementOfKind kind: String,
                        at indexPath: IndexPath) -> UICollectionReusableView {
        if kind == UICollectionElementKindSectionHeader {
            return collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionHeader,
                                                                   withReuseIdentifier: CompactUserInfoHeader.cellID,
                                                                   for: indexPath)
        }
        if kind == UICollectionElementKindSectionFooter {
            return collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionElementKindSectionFooter,
                                                                   withReuseIdentifier: "footer",
                                                                   for: indexPath)
        }
        fatalError("Unknown supplementary view of kind: \(kind)")
    }
    
}

// MARK: UICollectionViewDelegate
extension TeammateProfileVC: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath) {
        guard let teammate = dataSource.extendedTeammate else { return }
        
        TeammateCellBuilder.populate(cell: cell, with: teammate, controller: self)
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        willDisplaySupplementaryView view: UICollectionReusableView,
                        forElementKind elementKind: String,
                        at indexPath: IndexPath) {
        guard let teammate = dataSource.extendedTeammate else { return }
        
        if let view = view as? CompactUserInfoHeader {
            view.avatarView.showAvatar(string: teammate.basic.avatar)
            
            if let left = view.leftNumberView {
                left.titleLabel.text = "Team.TeammateCell.coversMe".localized
                let amount = teammate.basic.coversMeAmount
                left.amountLabel.text = ValueToTextConverter.textFor(amount: amount)
                left.currencyLabel.text = service.currencyName
            }
            
            if let right = view.rightNumberView {
                right.titleLabel.text = "Team.TeammateCell.coverThem".localized
                let amount = teammate.basic.iCoverThemAmount
                right.amountLabel.text = ValueToTextConverter.textFor(amount: amount)
                right.currencyLabel.text = service.currencyName
            }
        }
        if elementKind == UICollectionElementKindSectionFooter, let footer = view as? TeammateFooter {
            if let date = teammate.basic.dateJoined {
                let dateString = Formatter.teambrellaShort.string(from: date)
                footer.label.text = "Team.Teammate.Footer.MemberSince".localized(dateString).uppercased()
            } else {
                footer.label.text = "..."
            }
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let identifier = dataSource.type(for: indexPath)
        if identifier == .dialog || identifier == .dialogCompact, let extendedTeammate = dataSource.extendedTeammate {
            let context = ChatContext.teammate(extendedTeammate)
            service.router.presentChat(context: context)
        }
    }
    
}

// MARK: UICollectionViewDelegateFlowLayout
extension TeammateProfileVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let wdt = collectionView.bounds.width - 16 * 2
        switch dataSource.type(for: indexPath) {
        case .summary:
            return CGSize(width: collectionView.bounds.width, height: 210)
        case .object:
            guard let teammate = dataSource.extendedTeammate,
                teammate.object.claimCount > 0 else { return CGSize(width: wdt, height: 216) }
            
            return CGSize(width: wdt, height: 296)
        case .stats:
            return CGSize(width: wdt, height: 368)
        case .contact:
            let base: CGFloat = 38
            let cellHeight: CGFloat = Constant.socialCellHeight
            return CGSize(width: wdt, height: base + CGFloat(dataSource.socialItems.count) * cellHeight)
        case .dialog:
            return CGSize(width: collectionView.bounds.width, height: 120)
        case .me:
            return CGSize(width: collectionView.bounds.width, height: 256)
        case .voting:
            return CGSize(width: wdt, height: 350)
        case .dialogCompact:
            return  CGSize(width: collectionView.bounds.width, height: 98)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForHeaderInSection section: Int) -> CGSize {
        return dataSource.isNewTeammate ? CGSize(width: collectionView.bounds.width, height: 60) : CGSize.zero
    }
    
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        referenceSizeForFooterInSection section: Int) -> CGSize {
        return dataSource.isNewTeammate ?  CGSize.zero : CGSize(width: collectionView.bounds.width, height: 81)
    }
}

// MARK: UITableViewDataSource
extension TeammateProfileVC: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataSource.socialItems.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: "ContactCellTableCell", for: indexPath)
    }
}

// MARK: UITableViewDelegate
extension TeammateProfileVC: UITableViewDelegate {
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let cell = cell as? ContactCellTableCell {
            let item = dataSource.socialItems[indexPath.row]
            cell.avatarView.image = item.icon
            cell.topLabel.text = item.name.uppercased()
            cell.bottomLabel.text = item.address
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constant.socialCellHeight
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.001
    }
}

// MARK: IndicatorInfoProvider
extension TeammateProfileVC: IndicatorInfoProvider {
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: "Me.ProfileVC.indicatorTitle".localized)
    }
}

// MARK: VotingRiskCellDelegate
extension TeammateProfileVC: VotingRiskCellDelegate {
    func votingRisk(cell: VotingRiskCell, changedOffset: CGFloat) {
        func text(for label: UILabel, risk: Double) {
            guard let riskScale = teammate?.extended?.riskScale else { return }
            
            let delta = risk - riskScale.averageRisk
            var text = "AVG\n"
            text += delta > 0 ? "+" : ""
            let percent = 100 * delta / riskScale.averageRisk
            let amount = String(format: "%.0f", percent)
            label.text =  text + amount + "%"
        }
        
        let risk = riskFrom(offset: changedOffset, maxValue: cell.maxValue)
        cell.yourVoteValueLabel.text = String(format: "%.2f", risk)
        
        text(for: cell.yourVoteBadgeLabel, risk: risk)
        if let teamRisk = teammate?.extended?.voting?.riskVoted {
            text(for: cell.teamVoteBadgeLabel, risk: teamRisk)
        }
        
        //cell.pearMiddleAvatar.riskLabelText =  String.formattedNumber(risk)
        
        updateAmounts(with: risk)
    }
    
    func votingRisk(cell: VotingRiskCell, stoppedOnOffset: CGFloat) {
        let risk = riskFrom(offset: stoppedOnOffset, maxValue: cell.maxValue)
        
        cell.yourVoteValueLabel.alpha = 0.5
        guard let userID = teammate?.id else { return }
        
        dataSource.sendRisk(userID: userID, risk: risk) { [weak self, weak cell] json in
            guard let `self` = self else { return }
            
            self.teammate?.updateWithVote(json: json)
            cell?.yourVoteValueLabel.alpha = 1
            cell?.isProxyHidden = true
        }
    }
    
    func votingRisk(cell: VotingRiskCell, changedMiddleRowIndex: Int) {
        func setview(labeledView: LabeledRoundImageView, with teammate: RiskScaleEntity.Teammate?) {
            guard let teammate = teammate else {
                labeledView.isHidden = true
                labeledView.avatar.image = nil
                return
            }
            
            labeledView.isHidden = false
            labeledView.avatar.showAvatar(string: teammate.avatar,
                                          options: [.transition(.fade(0.5)), .forceTransition])
            labeledView.riskLabelText = String(format: "%.2f", teammate.risk)
            labeledView.labelBackgroundColor = .blueWithAHintOfPurple
        }
        
        guard let range = teammate?.extended?.riskScale?.ranges[changedMiddleRowIndex] else { return }
        
        if range.teammates.count > 1 {
            setview(labeledView: cell.pearRightAvatar, with: range.teammates.last)
        } else {
            cell.pearRightAvatar.isHidden = true
        }
        setview(labeledView: cell.pearLeftAvatar, with: range.teammates.first)
    }
}
