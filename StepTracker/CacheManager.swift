//
//  CacheManager.swift
//  StepTracker
//
//  Created by Filip Cernov on 05/05/2024.
//

import Foundation

class CacheManager {
    static let shared = CacheManager()
    private var cachedData: [StepDataResponce]?
    
    private init() {}
    
    // Function to fetch cached data
    func fetchCachedData() -> [StepDataResponce]? {
        cachedData
    }
    
    // Function to save data to cache
    func saveResponceToCahce(response: [StepDataResponce]) {
        self.cachedData = response
    }
}
