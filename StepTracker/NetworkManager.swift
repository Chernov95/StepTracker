//
//  NetworkingManager.swift
//  StepTracker
//
//  Created by Filip Cernov on 05/05/2024.
//
import Foundation

class NetworkManager {
    
    static let shared = NetworkManager()
    private let authData = ["identifier": "user1@test.com", "password": "Test123!"]
    private init() {}
    
    private enum Endpoint {
        static let baseURL = "https://testapi.mindware.us"
        static let auth = "/auth/local"
        static let steps = "/steps"
    }
    
    private enum Method {
        static let POST = "POST"
        static let GET = "GET"
        static let PUT = "PUT"
    }
    
    private func makeRequest(url: URL, method: String, bearerToken: String?, body: [String: Any]?) async throws -> (Data, HTTPURLResponse) {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let bearerToken {
            request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        }
        
        if let body = body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }
        
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "NetworkError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        return (data, httpResponse)
    }
    
    func fetchUserStepData(bearerToken: String, userName: String) async throws -> [StepDataResponce] {
        guard let stepsURL = URL(string: "\(Endpoint.baseURL)\(Endpoint.steps)?username=\(userName)") else {
            print("Invalid url for fetching user step data")
            return []
        }
        
        do {
            let (data, response) = try await makeRequest(url: stepsURL, method: Method.GET, bearerToken: bearerToken, body: nil)
            
            guard (200...299).contains(response.statusCode) else {
                let responseString = String(data: data, encoding: .utf8) ?? "No data"
                throw NSError(domain: "NetworkError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Error response: \(responseString)"])
            }
            
            if let decodedResponse = try? JSONDecoder().decode([StepDataResponce].self, from: data) {
                print("decoded response is \(decodedResponse)")
                return decodedResponse
            } else {
                let responseString = String(data: data, encoding: .utf8) ?? "No data"
                throw NSError(domain: "DecodingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Error decoding response: \(responseString)"])
            }
        } catch {
            print("Error fetching step data: \(error.localizedDescription)")
            throw error
        }
    }

    func fetchBearerToken() async throws -> String {
        guard let authURL = URL(string: Endpoint.baseURL + Endpoint.auth) else {
            print("Invalid url for fetching bearer token")
            return ""
        }
        do {
            let (data, response) = try await makeRequest(url: authURL, method: Method.POST, bearerToken: nil, body: authData) // Pass nil for bearer token
            
            guard (200...299).contains(response.statusCode) else {
                let responseString = String(data: data, encoding: .utf8) ?? "No data"
                throw NSError(domain: "NetworkError", code: response.statusCode, userInfo: [NSLocalizedDescriptionKey: "Error response: \(responseString)"])
            }
            
            guard let token = try? JSONDecoder().decode(TokenResponse.self, from: data) else {
                throw NSError(domain: "DecodingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to decode token"])
            }
            
            return token.jwt
        } catch {
            print("Error fetching bearer token: \(error.localizedDescription)")
            throw error
        }
    }

    func postNumberOfStepsForToday(bearerToken: String, hourlyActivityData: [HourlyActivity], userName: String, totalNumberOfCompletedStepsDuringTheDay: Int) async throws {
        guard !hourlyActivityData.isEmpty else {
            throw NSError(domain: "DataError", code: 0, userInfo: [NSLocalizedDescriptionKey: "There is no data for posting activity"])
        }
        
        guard let stepsURL = URL(string: Endpoint.baseURL + Endpoint.steps) else {
            print("Invalid url for posting number of steps for today")
            return
        }
        
        let stepsData = getStepsData(userName: userName, totalNumberOfCompletedStepsDuringTheDay: totalNumberOfCompletedStepsDuringTheDay)
        
        do {
            let (data, response) = try await makeRequest(url: stepsURL, method: Method.POST, bearerToken: bearerToken, body: stepsData)
            
            guard (200...299).contains(response.statusCode) else {
                let responseString = String(data: data, encoding: .utf8) ?? "No data"
                throw NSError(domain: "NetworkError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Error response: \(responseString)"])
            }
            
            print("Hourly activity data posted successfully.")
        } catch {
            print("Error posting hourly activity data: \(error.localizedDescription)")
            throw error
        }
    }

    func updateTotalStepsCountForTodayInBackend(bearerToken: String, userName: String, idOfStepsDataForTodayInBackend: Int, hourlyActivityData: [HourlyActivity], totalNumberOfCompletedStepsDuringTheDay: Int) async throws {
        guard !hourlyActivityData.isEmpty else {
            throw NSError(domain: "DataError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Steps data are empty"])
        }
        
        guard let stepsURL = URL(string: "\(Endpoint.baseURL)\(Endpoint.steps)/\(idOfStepsDataForTodayInBackend)") else {
            print("Invalid url for updating total step count for today in back end")
            return
        }
        
        let stepsData = getStepsData(userName: userName, totalNumberOfCompletedStepsDuringTheDay: totalNumberOfCompletedStepsDuringTheDay)
        
        do {
            let (data, response) = try await makeRequest(url: stepsURL, method: Method.PUT, bearerToken: bearerToken, body: stepsData)
            
            guard (200...299).contains(response.statusCode) else {
                let responseString = String(data: data, encoding: .utf8) ?? "No data"
                throw NSError(domain: "NetworkError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Error response for updating value in back end: \(responseString)"])
            }
            
            print("Total number of steps in backend have been updated")
        } catch {
            print("Error posting hourly activity data: \(error.localizedDescription)")
            throw error
        }
    }
    // Function which returns tutple for checking whether backend has to be updated with the new data from health kit.
    // It takes into account scenario where we fail to determine if backend has to be updated or not. That's why values are optional
    func getInformationIfStepsDataForTodayIsInBackendAndItHasToBeUpdated(bearerToken: String, userName: String, totalNumberOfCompletedStepsDuringTheDay: Int) async throws -> (updateIsRequired: Bool?, idOfStepsDataForTodayInBackend: Int?) {
        guard let stepsURL = URL(string: "\(Endpoint.baseURL)\(Endpoint.steps)?username=\(userName)&steps_date=\(getTodaysShortVersionDate())") else {
            print("Invalid url for gettng information if Steps Data For Today Is In Backend And It Has ToBeUpdated")
            return (nil, nil)
        }
        var request = URLRequest(url: stepsURL)
        request.httpMethod = Method.GET
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
            let responseString = String(data: data, encoding: .utf8) ?? "No data"
            throw NSError(domain: "NetworkError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Error response for getting id for today's steps data in back end: \(responseString)"])
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
            let responseString = String(data: data, encoding: .utf8) ?? "No data"
            throw NSError(domain: "DecodingError", code: 0, userInfo: [NSLocalizedDescriptionKey: "Error decoding response: \(responseString)"])
        }
    }

    private func getStepsData(userName: String, totalNumberOfCompletedStepsDuringTheDay: Int) -> [String : Any]{
        [
            "username": userName,
            "steps_date": getTodaysShortVersionDate(),
            "steps_datetime": getTodaysLongVersionDate(),
            "steps_count": 0,
            "steps_total_by_day": totalNumberOfCompletedStepsDuringTheDay
        ] as [String : Any]
    }

    private func getTodaysShortVersionDate() -> String {
        return DateFormatter.formattedString(from: Date(), format: "yyyy-MM-dd")
    }

    private func getTodaysLongVersionDate() -> String {
        return DateFormatter.formattedString(from: Date(), format: "yyyy-MM-dd'T'HH:mm:ss.SSSZ")
    }
}

extension DateFormatter {
    static func formattedString(from date: Date, format: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        return formatter.string(from: date)
    }
}
