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
    @Published var selectedPeriod: Periods = .weekly
    @Published var activityForTheWeek = [WeeklyActivity]()
    @Published var activityForTheMonth = [MonthlyActivity]()
    private let healthStore = HKHealthStore()
    let constants = Constants()
    let bearerToken: String
    init(bearerToken: String) {
        self.bearerToken = bearerToken
        fetchStepData()
    }
    
    
    func fetchStepData() {
        guard !bearerToken.isEmpty else {
               print("Bearer token is empty")
               return
           }
           let stepsURL = URL(string: "https://testapi.mindware.us/steps")!
           var request = URLRequest(url: stepsURL)
           request.httpMethod = "GET"
           request.setValue("application/json", forHTTPHeaderField: "Content-Type")
           request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
           
           URLSession.shared.dataTask(with: request) { data, response, error in
               guard let data = data else {
                   print("No data returned: \(error?.localizedDescription ?? "Unknown error")")
                   return
               }
               
               if let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) {
                   if let decodedResponse = try? JSONDecoder().decode([StepDataResponce].self, from: data) {
                       DispatchQueue.main.async {
                           // Handle decoded response as needed
                           print(decodedResponse)
                       }
                   } else {
                       let responseString = String(data: data, encoding: .utf8)
                       print("Error decoding response: \(responseString ?? "No data")")
                   }
               } else {
                   let responseString = String(data: data, encoding: .utf8)
                   print("Error response: \(responseString ?? "No data")")
               }
           }.resume()
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
