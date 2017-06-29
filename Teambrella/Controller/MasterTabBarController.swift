//
//  MasterTabBarController.swift
//  Teambrella
//
//  Created by Yaroslav Pasternak on 31.05.17.
//  Copyright © 2017 Yaroslav Pasternak. All rights reserved.
//

import UIKit

class MasterTabBarController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let items = tabBar.items else { return }
        
        for item in items {
            item.image = item.image?.withRenderingMode(.alwaysOriginal)
        }
    }
    
    func switchTo(tabType: TabType) -> UIViewController? {
        guard let viewControllers = viewControllers else { return nil }
        
        for (idx, vc) in viewControllers.enumerated() {
            if let nc = vc as? UINavigationController,
                let firstVC = nc.viewControllers.first,
                let tabRoutable = firstVC as? TabRoutable,
                tabRoutable.tabType == tabType {
                selectedIndex = idx
                return firstVC
            }
        }
        return nil
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
