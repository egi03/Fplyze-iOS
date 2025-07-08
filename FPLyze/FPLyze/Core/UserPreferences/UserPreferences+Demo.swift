//
//  UserPreferences+Demo.swift
//  FPL.stats
//
//  Created by Eugen Sedlar on 08.07.2025..
//

import Foundation

extension UserPreferences {
    func addDemoToRecentSearches() {
        addRecentSearch(leagueId: 999999, name: "FPL Demo League")
    }
    
    func isDemoLeague(_ leagueId: Int) -> Bool {
        return leagueId == 999999
    }
}
