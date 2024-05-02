//
//  TodayViewModel.swift
//  StepTracker
//
//  Created by Filip Cernov on 30/04/2024.
//

//import Foundation
//import HealthKit
//
//class TodayViewModel: ObservableObject {
//    // HealthKit store
//    private let healthStore = HKHealthStore()
//    
//    // Published property to notify views about changes in step count data
//    @Published var stepCountsPerHour: [(date: String, stepCount: Int)] = []
//    @Published var numberOfStepsDuringTheDay = 0
//    
//    init() {
//        requestAuthorization()
//    }
//    
//    private func requestAuthorization() {
//        guard HKHealthStore.isHealthDataAvailable() else {
//            print("DEBUG:: HealthKit is not available on this device.")
//            return
//        }
//        
//        // Define the health data type we want to read (step count)
//        guard let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
//            print("DEBUG:: Step count type is not available.")
//            return
//        }
//        
//        // Request authorization to access step count data
//        healthStore.requestAuthorization(toShare: nil, read: [stepCountType]) { [weak self] (success, error) in
//            if let error = error {
//                print("DEBUG:: Authorization request error: \(error.localizedDescription)")
//                return
//            }
//            
//            if success {
//                // Authorization granted, proceed with querying step count data
//                self?.queryStepCount()
//            } else {
//                print("DEBUG:: Authorization denied.")
//            }
//        }
//    }
//    
//    func queryStepCount() {
//        // Define the date range for which you want to fetch step count data (e.g., past 24 hours)
//        let calendar = Calendar.current
//        let now = Date()
//        let startDate = calendar.startOfDay(for: now)
//        let endDate = now
//        
//        // Define the hourly interval
//        var dateComponents = DateComponents()
//        dateComponents.hour = 1
//        let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount)!
//        // Create the query
//        let query = HKStatisticsCollectionQuery(quantityType: stepCountType,
//                                                quantitySamplePredicate: nil,
//                                                options: .cumulativeSum,
//                                                anchorDate: startDate,
//                                                intervalComponents: dateComponents)
//        
//        // Define how the results should be grouped
//        query.initialResultsHandler = { [weak self] query, results, error in
//            guard let statsCollection = results else {
//                print("Failed to fetch step count data: \(error?.localizedDescription ?? "Unknown error")")
//                return
//            }
//            
//            var stepCounts: [(date: Date, stepCount: Int)] = []
//            statsCollection.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
//                if let sum = statistics.sumQuantity() {
//                    let date = statistics.startDate
//                    let stepCount = Int(sum.doubleValue(for: HKUnit.count()))
//                    
//                    // Process step count for each hour
//                    stepCounts.append((date: date, stepCount: stepCount))
//                }
//            }
//            
//            // Update the published property on the main thread
//            DispatchQueue.main.async {
//                self?.stepCountsPerHour = self?.convertDateIntoString(stepCounts: stepCounts) ?? []
//            }
//        }
//        
//        // Execute the query
//        healthStore.execute(query)
//    }
//    
//    private func convertDateIntoString(stepCounts: [(date: Date, stepCount: Int)] ) -> [(date: String, stepCount: Int)]{
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "h:mm a" // 'a' represents AM/PM format
//        var convertedSteps = [(date: String, stepCount: Int)]()
//        // Iterate through your array and format each date
//        for (date, stepCount) in stepCounts {
//            let formattedDate = dateFormatter.string(from: date)
//            // Now `formattedDate` contains the date in the desired format (AM/PM)
//            print("\(formattedDate), Steps: \(stepCount)")
//            convertedSteps.append((formattedDate, stepCount))
//        }
//        return convertedSteps
//    }
//}



import Foundation
import HealthKit

class TodayViewModel: ObservableObject {
    // HealthKit store
    private let healthStore = HKHealthStore()
    
    // Published property to notify views about changes in step count data
    @Published var stepCountsPerHour: [(date: String, stepCount: Int)] = []
    @Published var totalNumberOfStepsDuringTheDay = 0
    let targetNumberOfSteps = 10_000
    
    
    init() {
        requestHealthDataAuthorization()
    }
    
    private func requestHealthDataAuthorization() {
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
        healthStore.requestAuthorization(toShare: nil, read: [stepCountType]) { [weak self] (success, error) in
            if let error = error {
                print("DEBUG:: Authorization request error: \(error.localizedDescription)")
                return
            }
            
            if success {
                // Authorization granted, proceed with querying step count data
                self?.queryDailyStepCount()
            } else {
                print("DEBUG:: Authorization denied.")
            }
        }
    }
    
    func queryDailyStepCount() {
        // Define the date range for which you want to fetch step count data (e.g., past 24 hours)
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
            
            // Update the published property on the main thread
            DispatchQueue.main.async {
                self?.stepCountsPerHour = self?.convertDateIntoString(stepCounts: stepCounts) ?? []
                self?.totalNumberOfStepsDuringTheDay = self?.stepCountsPerHour.reduce(0) { $0 + $1.stepCount } ?? 0
            }
        }
        
        // Execute the query
        healthStore.execute(query)
    }
    
    private func convertDateIntoString(stepCounts: [(date: Date, stepCount: Int)] ) -> [(date: String, stepCount: Int)]{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "h:mm a" // 'a' represents AM/PM format
        var convertedSteps = [(date: String, stepCount: Int)]()
        // Iterate through your array and format each date
        for (date, stepCount) in stepCounts {
            let formattedDate = dateFormatter.string(from: date)
            // Now `formattedDate` contains the date in the desired format (AM/PM)
            print("\(formattedDate), Steps: \(stepCount)")
            convertedSteps.append((formattedDate, stepCount))
        }
        return convertedSteps
    }
    
    func getPercentOfCompletedSteps() -> Int {
        (totalNumberOfStepsDuringTheDay  * 100) / targetNumberOfSteps
    }
}
