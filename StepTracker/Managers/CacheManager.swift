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
    
    func updateStepsInCache(newNumberOfStepsToday: Int) {
        guard let cachedData, !cachedData.isEmpty else {
            print("Cache is empty")
            return
        }
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let todayDateString = dateFormatter.string(from: Date())

        
        let stepsDates = cachedData.map { $0.stepsDate }

        
        if let index = stepsDates.firstIndex(of: todayDateString) {
            print("Steps for today are being updated in cache. In cache total number of steps is \(cachedData[index].stepsTotalByDay), whereas  update value is \(newNumberOfStepsToday)")
            self.cachedData?[index].stepsTotalByDay = newNumberOfStepsToday
            print("Total number of steps has been updated in array new value for today's date i.e. \(String(describing: self.cachedData?[index].stepsDate)) is \(String(describing: self.cachedData?[index].stepsTotalByDay))")
        } else {
            print("Today's date not found in cache.")
        }
    }
}
