//
//  HistoryViewModel.swift
//  StepTracker
//
//  Created by Filip Cernov on 01/05/2024.
//

import Foundation
import HealthKit

class HistoryViewModel: ObservableObject {
    private let healthStore = HKHealthStore()
    @Published var activityForTheWeek = [WeeklyActivity]()
    @Published var activityForTheMonth = [MonthlyActivity]()
    
    func queryWeeklyStepCount() {
        // Define the date range for which you want to fetch step count data (e.g., current week from Monday to Sunday)
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Set Monday as the first day of the week
        
        let now = Date()
        
        // Find the beginning of the current week (Monday)
        guard let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
            print("Failed to calculate the beginning of the week.")
            return
        }
        
        // Find the end of the current week (Sunday)
        guard let endOfWeek = calendar.date(byAdding: .day, value: 6, to: startOfWeek) else {
            print("Failed to calculate the end of the week.")
            return
        }
        
        // Define the daily interval
        var dateComponents = DateComponents()
        dateComponents.day = 1
        let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount)!
        
        // Create the query
        let query = HKStatisticsCollectionQuery(quantityType: stepCountType,
                                                quantitySamplePredicate: nil,
                                                options: .cumulativeSum,
                                                anchorDate: startOfWeek,
                                                intervalComponents: dateComponents)
        
        // Define array to hold weekly activities
        var activityForTheWeek = [WeeklyActivity]()
        
        // Define how the results should be grouped
        query.initialResultsHandler = { [weak self] query, results, error in
            guard let statsCollection = results else {
                print("Failed to fetch step count data: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            statsCollection.enumerateStatistics(from: startOfWeek, to: endOfWeek) { statistics, _ in
                if let sum = statistics.sumQuantity() {
                    let date = statistics.startDate
                    let dayName = calendar.shortWeekdaySymbols[calendar.component(.weekday, from: date) - 1]
                    let stepCount = Int(sum.doubleValue(for: HKUnit.count()))
                    
                    let weeklyActivity = WeeklyActivity(dayName: dayName, numberOfSteps: stepCount)
                    activityForTheWeek.append(weeklyActivity)
                }
            }
            
            // Update the published property on the main thread
            DispatchQueue.main.async {
                self?.activityForTheWeek = activityForTheWeek
            }
        }
        
        // Execute the query
        healthStore.execute(query)
    }
    
    func queryMonthlyStepCount() {
        // Define the date range for which you want to fetch step count data (e.g., current month from 1st day to last day)
        let calendar = Calendar.current
        let now = Date()
        
        // Find the beginning of the current month
        guard let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now)) else {
            print("Failed to calculate the beginning of the month.")
            return
        }
        
        // Find the end of the current month
        guard let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            print("Failed to calculate the end of the month.")
            return
        }
        
        // Define the daily interval
        var dateComponents = DateComponents()
        dateComponents.day = 1
        let stepCountType = HKObjectType.quantityType(forIdentifier: .stepCount)!
        
        // Create the query
        let query = HKStatisticsCollectionQuery(quantityType: stepCountType,
                                                quantitySamplePredicate: nil,
                                                options: .cumulativeSum,
                                                anchorDate: startOfMonth,
                                                intervalComponents: dateComponents)
        
        // Define array to hold monthly activities
        var activityForTheMonth = [MonthlyActivity]()
        
        // Define how the results should be grouped
        query.initialResultsHandler = { [weak self] query, results, error in
            guard let statsCollection = results else {
                print("Failed to fetch step count data: \(error?.localizedDescription ?? "Unknown error")")
                return
            }
            
            statsCollection.enumerateStatistics(from: startOfMonth, to: endOfMonth) { statistics, _ in
                if let sum = statistics.sumQuantity() {
                    let date = calendar.component(.day, from: statistics.startDate)
                    let stepCount = Int(sum.doubleValue(for: HKUnit.count()))
                    
                    let monthlyActivity = MonthlyActivity(date: date, numberOfSteps: stepCount)
                    activityForTheMonth.append(monthlyActivity)
                }
            }
            
            // Update the published property on the main thread
            DispatchQueue.main.async {
                self?.activityForTheMonth = activityForTheMonth
            }
        }
        
        // Execute the query
        healthStore.execute(query)
    }
}
