//
//  NetworkingManager.swift
//  StepTracker
//
//  Created by Filip Cernov on 05/05/2024.
//

import Foundation

class NetworkManager {
    
    static let shared = NetworkManager()
    
    private init() {}
    
    func fetchBearerToken() async throws -> String {
        let authURL = URL(string: "https://testapi.mindware.us/auth/local")!
        let authData = ["identifier": "user1@test.com", "password": "Test123!"]
        
        var request = URLRequest(url: authURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: authData)
        } catch {
            print("Error encoding auth data: \(error.localizedDescription)")
            throw error
        }
        
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                throw NSError(domain: "NetworkError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Error response: \(response.debugDescription)"])
            }
            
            if let token = try? JSONDecoder().decode(TokenResponse.self, from: data) {
                return token.jwt
            } else {
                throw NSError(domain: "DecodingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to decode token"])
            }
        } catch {
            print("Error fetching bearer token: \(error.localizedDescription)")
            throw error
        }
    }
    
    func postNumberOfStepsForToday(bearerToken: String, hourlyActivityData: [HourlyActivity], userName: String, totalNumberOfCompletedStepsDuringTheDay: Int) async throws {
        guard !hourlyActivityData.isEmpty else {
            throw NSError(domain: "DataError", code: 0, userInfo: [NSLocalizedDescriptionKey: "There is no data for posting activity"])
        }
        guard let stepsURL = URL(string: "https://testapi.mindware.us/steps") else {
            throw NSError(domain: "URLError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL for posting daily activity"])
        }
        
        let stepsData = [
            "username": userName,
            "steps_date": getTodaysShortVersionDate(),
            "steps_datetime": getTodaysLongVersionDate(),
            "steps_count": 0,
            "steps_total_by_day": totalNumberOfCompletedStepsDuringTheDay
        ] as [String : Any]
        
        var request = URLRequest(url: stepsURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: stepsData)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let responseString = String(data: data, encoding: .utf8)
                throw NSError(domain: "NetworkError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Error response: \(responseString ?? "No data")"])
            }
            print("Hourly activity data posted successfully.")
        } catch {
            print("Error posting hourly activity data: \(error.localizedDescription)")
            throw error
        }
    }
    
    // Function which returns tutple for checking whether backend has to be updated with the new data from health kit.
    // It takes into account scenario where we fail to determine if backend has to be updated or not. That's why values are optional
    // TODO: Needs rethinking
    func getInformationIfStepsDataForTodayIsInBackendAndItHasToBeUpdated(bearerToken: String, userName: String, totalNumberOfCompletedStepsDuringTheDay: Int) async throws -> (updateIsRequired: Bool?, idOfStepsDataForTodayInBackend: Int?) {
        guard let stepsURL = URL(string: "https://testapi.mindware.us/steps?username=\(userName)&steps_date=\(getTodaysShortVersionDate())") else {
            throw NSError(domain: "URLError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to get URL for checking steps data for today"])
        }
        var request = URLRequest(url: stepsURL)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let responseString = String(data: data, encoding: .utf8)
                throw NSError(domain: "NetworkError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Error response for getting id for today's steps data in back end: \(responseString ?? "No data")"])
            }
            
            if let decodedResponse = try? JSONDecoder().decode([StepDataResponce].self, from: data) {
                if decodedResponse.isEmpty {
                    print("Decoded response is empty. Data for today's should be posted")
                    return (false, nil)
                } else if decodedResponse.count > 1 {
                    print("Back end has more data on back for today than required")
                    return (nil, nil)
                } else {
                    if decodedResponse.first?.stepsTotalByDay  == totalNumberOfCompletedStepsDuringTheDay {
                        print("Total number of steps is the same in backend as on device. Therefore, no need in posting new data. In backend it's \(decodedResponse.first?.stepsTotalByDay) and locally we have \(totalNumberOfCompletedStepsDuringTheDay). Returning nil.")
                        return (nil, nil)
                    } else {
                        print("Health data on device is different from back end. Backend has to be updated, locally we have total numberOfSteps \(totalNumberOfCompletedStepsDuringTheDay), whereas back end has \(decodedResponse.first?.stepsTotalByDay)")
                        return (true, decodedResponse.first?.id)
                    }
                }
            } else {
                let responseString = String(data: data, encoding: .utf8)
                throw NSError(domain: "DecodingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Error decoding response: \(responseString ?? "No data")"])
            }
        } catch {
            print("Error fetching step data: \(error.localizedDescription)")
            throw error
        }
    }
    
    func updateTotalStepsCountForTodayInBackend(bearerToken: String, userName: String,  idOfStepsDataForTodayInBackend: Int, hourlyActivityData: [HourlyActivity], totalNumberOfCompletedStepsDuringTheDay: Int) async throws {
        guard !hourlyActivityData.isEmpty else {
            throw NSError(domain: "DataError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Steps data are empty"])
        }
        guard let stepsURL = URL(string: "https://testapi.mindware.us/steps/\(idOfStepsDataForTodayInBackend)") else {
            throw NSError(domain: "URLError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid URL for posting daily activity"])
        }
        
        let stepsData = [
            "username": userName,
            "steps_date": getTodaysShortVersionDate(),
            "steps_datetime": getTodaysLongVersionDate(),
            "steps_count": 0,
            "steps_total_by_day": totalNumberOfCompletedStepsDuringTheDay
        ] as [String : Any]
        
        var request = URLRequest(url: stepsURL)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: stepsData)
            
            let (data, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let responseString = String(data: data, encoding: .utf8)
                throw NSError(domain: "NetworkError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Error response for updating value in back end: \(responseString ?? "No data")"])
            }
            print("Total number of steps in backend have been updated")
        } catch {
            print("Error posting hourly activity data: \(error.localizedDescription)")
            throw error
        }
    }
    
    func fetchUserStepData(bearerToken: String, userName: String) async throws -> [StepDataResponce] {
        guard let stepsURL = URL(string: "https://testapi.mindware.us/steps?username=\(userName)") else {
            throw NSError(domain: "URLError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid url for fetching users activity"])
        }
        var request = URLRequest(url: stepsURL)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        print("Bearer token is \(bearerToken)")
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                let responseString = String(data: data, encoding: .utf8)
                throw NSError(domain: "NetworkError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Error response: \(responseString ?? "No data")"])
            }
            if let decodedResponse = try? JSONDecoder().decode([StepDataResponce].self, from: data) {
                print("decoded response is \(decodedResponse)")
                return decodedResponse
            } else {
                let responseString = String(data: data, encoding: .utf8)
                throw NSError(domain: "DecodingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Error decoding response: \(responseString ?? "No data")"])
            }
        } catch {
            print("Error fetching step data: \(error.localizedDescription)")
            throw error
        }
    }
    
    private func getTodaysShortVersionDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        return dateString
    }
    
    private func getTodaysLongVersionDate() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        let dateString = dateFormatter.string(from: Date())
        return dateString
    }
}
