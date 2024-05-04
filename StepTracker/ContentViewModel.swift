//
//  ContentViewModel.swift
//  StepTracker
//
//  Created by Filip Cernov on 02/05/2024.
//

import Foundation
import HealthKit

enum Tabs: String {
    case today = "Today"
    case history = "History"
}

@MainActor
class ContentViewModel: ObservableObject {
    @Published var stepCountsPerHour: [HourlyActivity] = []
    @Published var totalNumberOfCompletedStepsDuringTheDay = 0
    @Published var selectedTab: Tabs = .today
    @Published var dataForTodayAreBeingRefreshed = false
    @Published var newStepsDataForTodayHasBeenFetchedFromHealthKit = false
    
    var bearerToken: String = ""
    
    private let healthStore = HKHealthStore()
    let targetedNumberOfSteps = 10_000
    let constants = Constants()
    
    init() {
        retrieveStepCountsForTodayFromLocalStorage()
    }
    
    func requestHealthDataAuthorizationAndQueryDailyStepCount() async {
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
            queryAndDisplayFreshDailyStepCountFromHealthKit()
        } catch let error {
            print("DEBUG:: Authorization request error: \(error.localizedDescription)")
        }
    }
    
    private func retrieveStepCountsForTodayFromLocalStorage() {
        let defaults = UserDefaults.standard
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let dateString = dateFormatter.string(from: Date())
        guard let existingStepCounts = defaults.dictionary(forKey: dateString) as? [String: Int] else {
            // No data found for the current date
            return
        }
        
        // Update stepCountsPerHour array with data from UserDefaults
        stepCountsPerHour = existingStepCounts.map { HourlyActivity(time: $0.key, numberOfSteps: $0.value) } .sorted {
            let formatter = DateFormatter()
            formatter.dateFormat = "h:mm a"
            if let time1 = formatter.date(from: $0.time), let time2 = formatter.date(from: $1.time) {
                return time1 < time2
            }
            return false // If conversion fails, maintain original order
        }
        totalNumberOfCompletedStepsDuringTheDay = stepCountsPerHour.reduce(0) { $0 + $1.numberOfSteps }
    }

    func queryAndDisplayFreshDailyStepCountFromHealthKit() {
        // Define the date range for which you want to fetch step count data (e.g., past 24 hours)
        DispatchQueue.main.async {
            if !self.stepCountsPerHour.isEmpty {
                self.dataForTodayAreBeingRefreshed = true
            }
        }
        let calendar = Calendar.current
        let now = Date()
        let startDate = calendar.startOfDay(for: now)
        let endDate = now
        
        // Define the hourly interval
        var dateComponents = DateComponents()
        dateComponents.hour = 1
        let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount)!
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
                self?.stepCountsPerHour = self?.getConvertedHourlyActivityModel(stepCounts: stepCounts) ?? []
                self?.totalNumberOfCompletedStepsDuringTheDay = self?.stepCountsPerHour.reduce(0) { $0 + $1.numberOfSteps } ?? 0
                self?.saveOrUpdateStepCountsForTodayInLocalStorage(stepCounts)
                self?.dataForTodayAreBeingRefreshed = false
                self?.newStepsDataForTodayHasBeenFetchedFromHealthKit = true
            }
        }
        
        // Execute the query
        healthStore.execute(query)
    }
    
    private func getConvertedHourlyActivityModel(stepCounts: [(date: Date, stepCount: Int)] ) -> [HourlyActivity] {
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
    
    //MARK: For testing purposes on simulator
    private func generateMockDailyStepCount() {
        let hours = ["12:00 am", "01:00 am", "02:00 am", "03:00 am", "04:00 am", "05:00 am", "06:00 am", "07:00 am", "08:00 am", "09:00 am", "10:00 am", "11:00 am",
                     "12:00 pm", "01:00 pm", "02:00 pm", "03:00 pm", "04:00 pm", "05:00 pm", "06:00 pm", "07:00 pm", "08:00 pm", "09:00 pm", "10:00 pm", "11:00 pm"]
        
        var stepCountsPerHourTemp = [HourlyActivity]()
        for hour in hours {
            let activity = HourlyActivity(time: hour, numberOfSteps: Int.random(in: 0...5000))
            stepCountsPerHourTemp.append(activity)
        }
        stepCountsPerHour = stepCountsPerHourTemp
    }
}


extension ContentViewModel {
    struct Constants {
        let pickerWidth: CGFloat = 200
        let pickerContainerLeadingPadding: CGFloat = 16
        let containerTopPadding: CGFloat = 50
    }
}
