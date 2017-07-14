//
//  ChooseYourTeamDataSource.swift
//  Teambrella
//
//  Created by Екатерина Рыжова on 13.07.17.
//  Copyright © 2017 Yaroslav Pasternak. All rights reserved.
//

import Foundation

struct ChooseYourTeamDataSource {
    var count: Int { return models.count }
    var models: [ChooseYourTeamCellModel] = []
    
    mutating func createModels() {
        let model = service.session.teams
        for card in model {
            if let inc = card.unreadCount, let item = card.objectName, let cvg = card.teamCoverage {
                models.append(ChooseYourTeamCellModel(teamIcon: #imageLiteral(resourceName: "yummy"),
                                                      incomingCount: inc,
                                                      teamName: card.teamName,
                                                      itemName: item,
                                                      coverage: Int(cvg)))
            }
        }
    }
    mutating func createFakeModels() {
        models = [ChooseYourTeamCellModel(teamIcon: #imageLiteral(resourceName: "yummy"),
                                          incomingCount: 12,
                                          teamName: "Deductable Savers",
                                          itemName: "Mazda CX5",
                                          coverage: 95),
                  ChooseYourTeamCellModel(teamIcon: #imageLiteral(resourceName: "yummy"),
                                          incomingCount: 3,
                                          teamName: "Animal Protection",
                                          itemName: "BENGAaaaaaaaa CATS",
                                          coverage: 100),
                  ChooseYourTeamCellModel(teamIcon: #imageLiteral(resourceName: "yummy"),
                                          incomingCount: 0,
                                          teamName: "Dogs",
                                          itemName: "Mazda CX5",
                                          coverage: 30),
                  ChooseYourTeamCellModel(teamIcon: #imageLiteral(resourceName: "yummy"),
                                          incomingCount: 12,
                                          teamName: "Cats",
                                          itemName: "Mazda CX5",
                                          coverage: 40),
                  ChooseYourTeamCellModel(teamIcon: #imageLiteral(resourceName: "yummy"),
                                          incomingCount: 15,
                                          teamName: "Cars",
                                          itemName: "Mazda CX5",
                                          coverage: 70),
                  ChooseYourTeamCellModel(teamIcon: #imageLiteral(resourceName: "yummy"),
                                          incomingCount: 1,
                                          teamName: "Trolleybuses detected",
                                          itemName: "Mazda CX5",
                                          coverage: 80),
                  ChooseYourTeamCellModel(teamIcon: #imageLiteral(resourceName: "yummy"),
                                          incomingCount: 7,
                                          teamName: "Deductable Savers",
                                          itemName: "Mazda CX5",
                                          coverage: 20),
                  ChooseYourTeamCellModel(teamIcon: #imageLiteral(resourceName: "yummy"),
                                          incomingCount: 123,
                                          teamName: "Washmachines",
                                          itemName: "Mazda CX5",
                                          coverage: 50),
                  ChooseYourTeamCellModel(teamIcon: #imageLiteral(resourceName: "yummy"),
                                          incomingCount: 0,
                                          teamName: "Refregerators",
                                          itemName: "Mazda CX5",
                                          coverage: 60),
                  ChooseYourTeamCellModel(teamIcon: #imageLiteral(resourceName: "yummy"),
                                          incomingCount: 5,
                                          teamName: "Insurance",
                                          itemName: "Mazda CX5",
                                          coverage: 10)]
    }
    
    subscript(indexPath: IndexPath) -> ChooseYourTeamCellModel {
        return models[indexPath.row]
    }
    
}
