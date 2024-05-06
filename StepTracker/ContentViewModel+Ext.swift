//
//  ContentViewModel+Ext.swift
//  StepTracker
//
//  Created by Filip Cernov on 03/05/2024.
//

import Foundation
import HealthKit

extension ContentViewModel {
    func requestHealthDataAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("DEBUG:: HealthKit is not available on this device.")
            return
        }
        
        // Define the health data type we want to read (step count)
        guard let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            print("DEBUG:: Step count type is not available.")
            return
        }
        // Request authorization to access step count data
        do {
            try await healthStore.__requestAuthorization(toShare: nil, read: [stepCountType])
            // Authorization granted, proceed with querying step count data
            healthDataAuthorizationHasBeenGranted = true
            print("Health data authorization has been granted")
        } catch let error {
            print("DEBUG:: Authorization request error: \(error.localizedDescription)")
        }
    }
    
    func retrieveStepCountsForTodayFromLocalStorage() {
        let defaults = UserDefaults.standard
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let dateString = dateFormatter.string(from: Date())
        guard let existingStepCounts = defaults.dictionary(forKey: dateString) as? [String: Int] else {
            // No data found for the current date
            return
        }
        print("Locally saved steps data for today are \(existingStepCounts)")
        hourlyActivityData = existingStepCounts.map { HourlyActivity(time: $0.key, numberOfSteps: $0.value) } .sorted {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            if let time1 = formatter.date(from: $0.time), let time2 = formatter.date(from: $1.time) {
                return time1 < time2
            }
            return false // If conversion fails, maintain original order
        }
        totalNumberOfCompletedStepsDuringTheDay = hourlyActivityData.reduce(0) { $0 + $1.numberOfSteps }
        print("Local data has been displayed")
    }
    
    func queryAndDisplayFreshDailyStepCountFromHealthKit() {
        DispatchQueue.main.async {
            if !self.hourlyActivityData.isEmpty {
                self.dataForTodayAreBeingFetchedFromHealthKit = true
                print("Fresh data from health kit are being loaded")
            }
        }
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.startOfDay(for: now)
        let endDate = now
        
        // Define the hourly interval
        var dateComponents = DateComponents()
        dateComponents.hour = 1
        
        guard let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            print("Failed to define hourly interval")
            return
        }
        // Create the query
        let query = HKStatisticsCollectionQuery(quantityType: stepCountType,
                                                quantitySamplePredicate: nil,
                                                options: .cumulativeSum,
                                                anchorDate: startDate,
                                                intervalComponents: dateComponents)
        
        // Define how the results should be grouped
        query.initialResultsHandler = { [weak self] query, results, error in
            guard let statsCollection = results else {
                print("Failed to fetch step count data: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            var stepCounts: [(date: Date, stepCount: Int)] = []
            statsCollection.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                if let sum = statistics.sumQuantity() {
                    let date = statistics.startDate
                    let stepCount = Int(sum.doubleValue(for: HKUnit.count()))
                    
                    // Process step count for each hour
                    stepCounts.append((date: date, stepCount: stepCount))
                }
            }
            
            DispatchQueue.main.async {
                self?.hourlyActivityData = self?.mapHourlyActivityData(stepCounts: stepCounts) ?? []
                self?.totalNumberOfCompletedStepsDuringTheDay = self?.hourlyActivityData.reduce(0) { $0 + $1.numberOfSteps } ?? 0
                self?.saveOrUpdateStepCountsForTodayInLocalStorage(stepCounts)
                self?.dataForTodayAreBeingFetchedFromHealthKit = false
                self?.newStepsDataForTodayHasBeenFetchedFromHealthKit = true
                print("New data from health kit have been displayed")
            }
        }
        
        // Execute the query
        healthStore.execute(query)
    }
    
    private func mapHourlyActivityData(stepCounts: [(date: Date, stepCount: Int)] ) -> [HourlyActivity] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a" // 'a' represents AM/PM format
        var convertedSteps = [HourlyActivity]()
        // Iterate through your array and format each date
        for (date, stepCount) in stepCounts {
            let formattedDate = dateFormatter.string(from: date)
            // Now `formattedDate` contains the date in the desired format (AM/PM)
            convertedSteps.append(HourlyActivity(time: formattedDate, numberOfSteps: stepCount))
        }
        return convertedSteps
    }
    
    func getPercentOfCompletedSteps() -> Int {
        (totalNumberOfCompletedStepsDuringTheDay  * 100) / targetedNumberOfSteps
    }
    
    private func saveOrUpdateStepCountsForTodayInLocalStorage(_ stepCounts: [(date: Date, stepCount: Int)]) {
        let defaults = UserDefaults.standard
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        // Remove UserDefaults data for previous days until encountering a day without data
        var dateToRemove = Calendar.current.date(byAdding: .day, value: -1, to: Date())
        while let removeDate = dateToRemove {
            let removeDateKey = dateFormatter.string(from: removeDate)
            if defaults.object(forKey: removeDateKey) == nil {
                break // Stop loop if there's no data for this date
            }
            defaults.removeObject(forKey: removeDateKey)
            print("Removed UserDefaults data for previous day: \(removeDateKey)")
            dateToRemove = Calendar.current.date(byAdding: .day, value: -1, to: removeDate)
        }
        
        // Save or update step counts for the current day
        let dateString = dateFormatter.string(from: Date())
        var existingStepCounts = defaults.dictionary(forKey: dateString) as? [String: Int] ?? [:]
        // Update or append new step counts
        for (date, stepCount) in stepCounts {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "h:mm a" // 'a' represents AM/PM format
            let formattedHour = dateFormatter.string(from: date)
            existingStepCounts[formattedHour] = stepCount
        }
        defaults.set(existingStepCounts, forKey: dateString)
    }
}
