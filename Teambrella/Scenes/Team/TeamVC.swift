//
//  TeamVC.swift
//  Teambrella
//
//  Created by Yaroslav Pasternak on 25.05.17.

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

import UIKit
import XLPagerTabStrip

class TeamVC: ButtonBarPagerTabStripViewController, TabRoutable {
    let tabType: TabType = .team
    
    override func awakeFromNib() {
        super.awakeFromNib()
        title = "Main.team".localized
        tabBarItem.title = "Main.team".localized
    }
    
    override func viewDidLoad() {
        setupTeambrellaTabLayout()
        super.viewDidLoad()
        setupTransparentNavigationBar()
        //        addTeamButton()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //    private func addTeamButton() {
    //        let button = UIButton(type: .custom)
    //        let image = #imageLiteral(resourceName: "iconCoverage")
    //        button.tintColor = .teambrellaBlue
    //        button.setImage(image, for: .normal)
    //        button.frame = CGRect(x: 0, y: 0, width: 30, height: 30)
    //        button.addTarget(self, action: #selector(tapTeam(button:)), for: .touchUpInside)
    //        let barItem = UIBarButtonItem(customView: button)
    //        navigationItem.setLeftBarButton(barItem, animated: false)
    //    }
    
    func tapTeam(button: UIButton) {
        // TeamRouter().presentChooseTeam(in: self)
        service.router.showJoinTeam(in: self)
        //service.router.presentJoinTeam()
        /*
         let alert = UIAlertController(title: "Select your team",
         message: "Please select your team",
         preferredStyle: .actionSheet)
         
         let teams = ["Happy dogs team",
         "Muscle cars owners",
         "Private beta",
         "To live is to drive",
         "Honda Supra race team",
         "Toyota civic knights",
         "Pussycats",
         "Drive as you mean it",
         "My dog my rules",
         "Kittens are awesome",
         "Pet shop girls",
         "Straw dogs",
         "Wheel burners",
         "From Husk till Dawn"]
         for team in teams {
         let teamButton = UIAlertAction(title: team, style: .default) { action in
         self.teamSelected(name: action.title)
         }
         alert.addAction(teamButton)
         }
         let cancel = UIAlertAction(title: "Cancel", style: .cancel) { action in
         print("Cancel pressed")
         }
         alert.addAction(cancel)
         present(alert, animated: true) {
         print("Alert presented")
         }
         */
        
    }
    
    func teamSelected(name: String?) {
        let name = name ?? ""
        let alert = UIAlertController(title: "Team change",
                                      message: "Are you sure you want to change your current team to \(name)?",
                                      preferredStyle: .alert)
        let confirm = UIAlertAction(title: "Yes I do", style: .destructive) { action in
            print("Confirm pressed")
        }
        alert.addAction(confirm)
        let cancel = UIAlertAction(title: "No chance", style: .cancel) { action in
            print("Cancel pressed")
        }
        alert.addAction(cancel)
        present(alert, animated: true) {
            print("Alert presented")
        }
    }
    
    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        let feed = UIStoryboard(name: "Team", bundle: nil).instantiateViewController(withIdentifier: "FeedVC")
        let members = UIStoryboard(name: "Team", bundle: nil).instantiateViewController(withIdentifier: "MembersVC")
        let claims = UIStoryboard(name: "Team", bundle: nil).instantiateViewController(withIdentifier: "ClaimsVC")
        //let rules = UIStoryboard(name: "Team", bundle: nil).instantiateViewController(withIdentifier: "RulesVC")
        return [feed, members, claims /* , rules */]
    }
    
}
