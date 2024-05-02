//
//  HistoryViewModel.swift
//  StepTracker
//
//  Created by Filip Cernov on 01/05/2024.
//

import Foundation
import HealthKit
import Charts

enum Periods: String {
    case weekly = "7 Days"
    case monthly = "1 Month"
}

class HistoryViewModel: ObservableObject {
    private let healthStore = HKHealthStore()
    @Published var selectedPeriod: Periods = .weekly
    @Published var activityForTheWeek = [WeeklyActivity]()
    @Published var activityForTheMonth = [MonthlyActivity]()
    let constants = Constants()
    
    func queryWeeklyStepCount() {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Set Monday as the first day of the week
        
        let now = Date()
        
        // Get the start and end dates of the current week
        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now) else {
            print("Failed to calculate the current week.")
            return
        }
        
        let startOfWeek = weekInterval.start
        let endOfWeek = weekInterval.end
        
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
                guard let sum = statistics.sumQuantity()else { return }
                let date = statistics.startDate
                // Skip statistics for future dates
                guard date <= now else { return }
                
                let dayName = calendar.shortWeekdaySymbols[calendar.component(.weekday, from: date) - 1]
                let stepCount = Int(sum.doubleValue(for: HKUnit.count()))
                
                let weeklyActivity = WeeklyActivity(dayName: dayName, numberOfSteps: stepCount)
                activityForTheWeek.append(weeklyActivity)
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
                guard let sum = statistics.sumQuantity() else { return }
                let date = statistics.startDate
                // Skip statistics for future dates
                guard date <= now else { return }
                
                let day = calendar.component(.day, from: date)
                let stepCount = Int(sum.doubleValue(for: HKUnit.count()))
                
                let monthlyActivity = MonthlyActivity(date: day, numberOfSteps: stepCount)
                activityForTheMonth.append(monthlyActivity)
            }
            
            // Update the published property on the main thread
            DispatchQueue.main.async {
                self?.activityForTheMonth = activityForTheMonth
            }
        }
        
        // Execute the query
        healthStore.execute(query)
    }
    //MARK: For testing purposes on simulator
    func generateMockWeeklyStepCount() {
        let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]
        var activityForTheWeekTemp = [WeeklyActivity]()
        for day in dayNames {
            let activity = WeeklyActivity(dayName: day, numberOfSteps: Int.random(in: 0...10000))
            activityForTheWeekTemp.append(activity)
        }
        activityForTheWeek = activityForTheWeekTemp
    }
    
    //MARK: For testing purposes on simulator
    func generateMockMonthlyStepCount() {
        var activityForTheMonthTemp = [MonthlyActivity]()
        
        for date in 1...31 {
            let activity = MonthlyActivity(date: date, numberOfSteps: Int.random(in: 0...15000))
            activityForTheMonthTemp.append(activity)
        }
        activityForTheMonth = activityForTheMonthTemp
    }
}

extension HistoryViewModel {
    struct Constants {
        let dayTitle = "Day"
        let stepsTitle = "Steps"
        let dateTitle = "Date"
        let barMarkWidth: MarkDimension = 50
        let chartVisibleDomainLength = 4
    }
}
