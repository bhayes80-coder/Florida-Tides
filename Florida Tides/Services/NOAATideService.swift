//
//  NOAATideService.swift
//  Florida Tides
//
//  Created by Barry Hayes on 10/8/25.
//

import Foundation
import CoreLocation
import Combine

class NOAATideService: ObservableObject {
    private let baseURL = "https://api.tidesandcurrents.noaa.gov/api/prod/datagetter"
    
    func fetchTideData(for stationId: String,
                       startDate: Date = Date(),
                       endDate: Date = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()) async throws -> [TideData] {
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd HH:mm"
        
        let startString = formatter.string(from: startDate)
        let endString = formatter.string(from: endDate)
        
        let urlString = "\(baseURL)?product=predictions&application=NOS.COOPS.TAC.WL&begin_date=\(startString)&end_date=\(endString)&datum=MLLW&station=\(stationId)&time_zone=gmt&units=english&interval=h&format=json"
        
        guard let url = URL(string: urlString) else {
            throw TideServiceError.invalidURL
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200 else {
            throw TideServiceError.invalidResponse
        }
        
        let tideResponse = try JSONDecoder().decode(TideResponse.self, from: data)
        
        // Convert data points to TideData and determine high/low types
        var tideData = tideResponse.data.compactMap { $0.tideData }
        tideData = determineTideTypes(tideData: tideData)
        
        return tideData
    }
    
    func searchStations(near location: CLLocation) async throws -> [Location] {
        let floridaStations = [
            Location(name: "Key West, FL", latitude: 24.5551, longitude: -81.8066, stationId: "8724580"),
            Location(name: "Miami, FL", latitude: 25.7617, longitude: -80.1918, stationId: "8729108"),
            Location(name: "Tampa, FL", latitude: 27.9506, longitude: -82.4572, stationId: "8729108"),
            Location(name: "Jacksonville, FL", latitude: 30.3322, longitude: -81.6557, stationId: "8720218"),
            Location(name: "Pensacola, FL", latitude: 30.4213, longitude: -87.2169, stationId: "8729840"),
            Location(name: "St. Petersburg, FL", latitude: 27.7676, longitude: -82.6403, stationId: "8726520")
        ]
        
        return floridaStations.sorted { station1, station2 in
            let location1 = CLLocation(latitude: station1.latitude, longitude: station1.longitude)
            let location2 = CLLocation(latitude: station2.latitude, longitude: station2.longitude)
            return location.distance(from: location1) < location.distance(from: location2)
        }
    }
    
    private func determineTideTypes(tideData: [TideData]) -> [TideData] {
        guard tideData.count >= 3 else { return tideData }
        
        var result = tideData
        
        for i in 1..<tideData.count - 1 {
            let prev = tideData[i - 1]
            let current = tideData[i]
            let next = tideData[i + 1]
            
            if current.height > prev.height && current.height > next.height {
                result[i] = TideData(time: current.time, height: current.height, type: .high)
            } else if current.height < prev.height && current.height < next.height {
                result[i] = TideData(time: current.time, height: current.height, type: .low)
            }
        }
        
        return result
    }
}

enum TideServiceError: Error, LocalizedError {
    case invalidURL
    case invalidResponse
    case noData
    
    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid response from server"
        case .noData: return "No tide data available"
        }
    }
}
