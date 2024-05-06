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
    @Published var hourlyActivityData: [HourlyActivity] = []
    @Published var totalNumberOfCompletedStepsDuringTheDay = 0
    @Published var selectedTab: Tabs = .today
    @Published var dataForTodayAreBeingFetchedFromHealthKit = false
    @Published var newStepsDataForTodayHasBeenFetchedFromHealthKit = false
    @Published var healthDataAuthorizationHasBeenGranted = false
    @Published var bearerToken: String? = nil

    
    let healthStore = HKHealthStore()
    let networkManager = NetworkManager.shared
    let targetedNumberOfSteps = 10_000
    let constants = Constants()
    var idOfStepsDataForTodayInBackend: Int? = nil
    var backEndHasToBeUpdatedWithTodaysActivity: Bool? = nil
    let userName = "pylypcheg12345"
    
    init() {
        retrieveStepCountsForTodayFromLocalStorage()
    }
    
    @MainActor
    func fetchBearerToken() async {
        do {
            bearerToken = try await networkManager.fetchBearerToken()
        } catch {
            print("DEBUG: Faield to fetch bearer token")
        }
    }
    
    func postNumberOfStepsForToday() async {
        guard let bearerToken else {
            print("DEBUG: Cannot post activtiy for today because bearer token is nil")
            return
        }
        
        do {
            try await networkManager.postNumberOfStepsForToday(bearerToken: bearerToken, hourlyActivityData: hourlyActivityData, userName: userName, totalNumberOfCompletedStepsDuringTheDay: totalNumberOfCompletedStepsDuringTheDay)
        } catch {
            // Handle errors...
        }
        
    }
    
    func  getInformationIfStepsDataForTodayIsInBackendAndItHasToBeUpdated() async {
        guard let bearerToken else {
            print("DEBUG: Cannot determine if today's activtiy in back end has to be updated as there brearer token is nil")
            return
        }
        
        do {
            let result = try await networkManager.getInformationIfStepsDataForTodayIsInBackendAndItHasToBeUpdated(bearerToken: bearerToken,
                                                                                                       userName: userName,
                                                                                                       totalNumberOfCompletedStepsDuringTheDay: totalNumberOfCompletedStepsDuringTheDay)
            idOfStepsDataForTodayInBackend = result.idOfStepsDataForTodayInBackend
            backEndHasToBeUpdatedWithTodaysActivity = result.updateIsRequired
        } catch {
            
        }
    }
    
    func updateTotalStepsCountForTodayInBackend() async {
        guard let bearerToken else {
            print("DEBUG: Cannot post  today's activtiy in backend  as there brearer token is nil")
            return
        }
        guard let idOfStepsDataForTodayInBackend else {
            print("DEBUG: Cannot post  today's activtiy in backend  as idOfStepsDataForTodayInBackend is nil")
            return
        }
        
        do {
            try await networkManager.updateTotalStepsCountForTodayInBackend(bearerToken: bearerToken,
                                                                            userName: userName, idOfStepsDataForTodayInBackend: idOfStepsDataForTodayInBackend,
                                                                            hourlyActivityData: hourlyActivityData, totalNumberOfCompletedStepsDuringTheDay: totalNumberOfCompletedStepsDuringTheDay)
        } catch {
            
        }
        
    }
}


extension ContentViewModel {
    struct Constants {
        let pickerWidth: CGFloat = 200
        let pickerContainerLeadingPadding: CGFloat = 16
        let containerTopPadding: CGFloat = 50
    }
}
